import SwiftUI

/// The main scrollable personalised feed.
struct FeedView: View {
    @StateObject private var vm: FeedViewModel
    @EnvironmentObject private var store: InterestStore
    @Binding var pendingURL: URL?

    @State private var reader: ReaderLink?
    @State private var searchText = ""
    @State private var isRefreshing = false
    @State private var scrollProxy: ScrollViewProxy?

    init(client: NewsAPIClient, pendingURL: Binding<URL?>) {
        _vm = StateObject(wrappedValue: FeedViewModel(client: client, store: InterestStore.shared))
        _pendingURL = pendingURL
    }

    /// Articles filtered by the in-feed search box (title / source / topic).
    private var visibleArticles: [Article] {
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return vm.articles }
        return vm.articles.filter {
            $0.title.lowercased().contains(q)
            || $0.section.lowercased().contains(q)
            || ($0.pillar?.lowercased().contains(q) ?? false)
            || $0.tags.contains { $0.contains(q) }
        }
    }

    var body: some View {
        NavigationStack {
            content
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        HStack(spacing: 8) {
                            Button(action: refreshFromTop) {
                                LemonSliceIcon()
                                    .frame(width: 26, height: 26)
                                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                                    .animation(isRefreshing
                                               ? .linear(duration: 0.9).repeatForever(autoreverses: false)
                                               : .default, value: isRefreshing)
                            }
                            .accessibilityLabel("Refresh")
                            Text("Zesty News").font(.headline.weight(.bold))
                        }
                    }
                }
        }
        .task { await vm.loadIfNeeded() }
        // Open a story the widget asked for.
        .onChange(of: pendingURL) { _, url in
            if let url { reader = ReaderLink(url: url); pendingURL = nil }
        }
        .fullScreenCover(item: $reader) { link in
            ArticleReaderView(url: link.url)
        }
    }

    @ViewBuilder private var content: some View {
        switch vm.state {
        case .idle, .loading:
            ProgressView("Loading your feed…")
        case .failed(let message):
            ScrollView {
                ErrorState(message: message) { Task { await vm.refresh() } }
                    .frame(maxWidth: .infinity, minHeight: 500)
            }
            .refreshable { await vm.refresh() }
        case .empty:
            ScrollView {
                ContentUnavailableView("Nothing yet", systemImage: "newspaper",
                                       description: Text("Pull down to refresh or tune your interests."))
                    .frame(maxWidth: .infinity, minHeight: 500)
            }
            .refreshable { await vm.refresh() }
        case .loaded:
            if visibleArticles.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                list
            }
        }
    }

    /// Feed rows with native ads mixed in every few stories (not while searching).
    private var feedItems: [FeedItem] {
        let articles = visibleArticles
        guard searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return articles.map(FeedItem.article)
        }
        var items: [FeedItem] = []
        var adCount = 0
        for (i, article) in articles.enumerated() {
            items.append(.article(article))
            if (i + 1) % AdConfig.adEveryN == 0 && adCount < AdConfig.maxAdsPerFeed {
                items.append(.ad(adCount))
                adCount += 1
            }
        }
        return items
    }

    private var list: some View {
        ScrollViewReader { proxy in
            List(feedItems) { item in
                switch item {
                case .article(let article):
                    Button {
                        open(article)
                    } label: {
                        ArticleRow(article: article,
                                   isPinned: article.tags.contains(where: store.pinnedTags.contains))
                    }
                    .buttonStyle(.plain)
                    .onAppear { store.markShown(article) }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            store.record(.hideArticle, for: article)
                            vm.reorder()
                        } label: { Label("Less", systemImage: "hand.thumbsdown") }
                    }
                case .ad:
                    NativeAdSlot()
                }
            }
            .listStyle(.plain)
            .refreshable { await vm.refresh() }
            .onAppear { scrollProxy = proxy }
        }
    }

    /// Tapping the lemon: jump to the top, then refresh (with the icon spinning).
    private func refreshFromTop() {
        Task {
            isRefreshing = true
            if let first = vm.articles.first?.id {
                withAnimation { scrollProxy?.scrollTo(first, anchor: .top) }
            }
            await vm.refresh()
            isRefreshing = false
        }
    }

    private func open(_ article: Article) {
        // Clicking is the strongest interest signal — your "+10" example.
        store.record(.openArticle, for: article)
        if let url = URL(string: article.url) { reader = ReaderLink(url: url) }
    }
}

/// A feed entry: either a story or a native-ad slot.
private enum FeedItem: Identifiable {
    case article(Article)
    case ad(Int)
    var id: String {
        switch self {
        case .article(let a): return a.id
        case .ad(let i): return "ad-\(i)"
        }
    }
}

/// One row in the feed.
struct ArticleRow: View {
    let article: Article
    var isPinned = false

    /// Topic tags worth showing — drops the publisher slug and generic words.
    private var displayTags: [String] {
        let src = (article.pillar ?? "").lowercased().split(separator: " ").first.map(String.init) ?? ""
        var seen = Set<String>()
        return article.tags.filter {
            $0 != src && $0 != "news" && $0 != article.section && seen.insert($0).inserted
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                SourceBadge(source: article.pillar ?? article.section.capitalized,
                            category: article.section,
                            domain: URL(string: article.url)?.host)
                if isPinned {
                    Image(systemName: "pin.fill").font(.caption2).foregroundStyle(.tint)
                }
                Spacer()
                Text(article.publishedAt, format: .relative(presentation: .named))
                    .font(.caption2).foregroundStyle(.tertiary)
            }

            if let urlString = article.thumbnailURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { $0.resizable().scaledToFill() } placeholder: {
                    Rectangle().fill(.quaternary)
                }
                .frame(maxWidth: .infinity).frame(height: 190)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Text(article.title).font(.title3.weight(.semibold)).lineLimit(3)
            if let trail = article.trailText {
                Text(trail).font(.subheadline).foregroundStyle(.secondary).lineLimit(4)
            }
            if !displayTags.isEmpty {
                TagChips(tags: displayTags)
            }
        }
        .padding(.vertical, 8)
    }
}

/// A small lemon-slice mark (matches the app icon) used as the feed's refresh button.
struct LemonSliceIcon: View {
    var body: some View {
        Canvas { ctx, size in
            let d = min(size.width, size.height)
            let r = d / 2
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let rind = Color(red: 0.97, green: 0.79, blue: 0.18)
            let flesh = Color(red: 1.0, green: 0.92, blue: 0.55)

            ctx.fill(Circle().path(in: CGRect(x: c.x - r, y: c.y - r, width: d, height: d)),
                     with: .color(rind))
            let fr = r * 0.74
            ctx.fill(Circle().path(in: CGRect(x: c.x - fr, y: c.y - fr, width: fr * 2, height: fr * 2)),
                     with: .color(flesh))

            var segments = Path()
            let count = 8
            for i in 0..<count {
                let angle = Double(i) / Double(count) * 2 * .pi
                segments.move(to: c)
                segments.addLine(to: CGPoint(x: c.x + CGFloat(cos(angle)) * fr,
                                             y: c.y + CGFloat(sin(angle)) * fr))
            }
            ctx.stroke(segments, with: .color(.white), lineWidth: max(1, r * 0.13))
            ctx.fill(Circle().path(in: CGRect(x: c.x - r * 0.12, y: c.y - r * 0.12,
                                              width: r * 0.24, height: r * 0.24)),
                     with: .color(.white))
        }
    }
}
