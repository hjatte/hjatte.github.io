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
    @State private var lastOpened: Article?
    @State private var learnToast: [String]?
    @State private var whyText: String?

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
            ArticleReaderView(url: link.url) { fraction in
                // Only count it as a positive if they actually read ~70%+.
                guard fraction >= 0.7, let article = lastOpened else { return }
                store.record(.readToEnd, for: article)
                announceLearning()
            }
        }
        .alert("Why you're seeing this", isPresented: Binding(
            get: { whyText != nil }, set: { if !$0 { whyText = nil } }
        ), presenting: whyText) { _ in
            Button("OK", role: .cancel) {}
        } message: { Text($0) }
        .overlay(alignment: .bottom) {
            if let tags = learnToast, !tags.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile").foregroundStyle(.tint)
                    Text("Learning your interest in \(tags.joined(separator: ", "))")
                        .font(.footnote.weight(.medium)).lineLimit(2)
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(.quaternary))
                .shadow(radius: 6, y: 3)
                .padding(.horizontal, 24).padding(.bottom, 10)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func announceLearning() {
        guard let article = lastOpened else { return }
        let src = (article.pillar ?? "").lowercased().split(separator: " ").first.map(String.init) ?? ""
        let tags = article.tags.filter { $0 != src && $0 != "news" }.prefix(3).map { TagChips.display($0) }
        guard !tags.isEmpty else { return }
        withAnimation(.spring) { learnToast = tags }
        Task {
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            withAnimation { learnToast = nil }
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
            List {
                ForEach(feedItems) { item in
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
                        .contextMenu {
                            Button { whyText = whyReason(for: article) } label: {
                                Label("Why am I seeing this?", systemImage: "questionmark.circle")
                            }
                            Button(role: .destructive) {
                                store.record(.hideArticle, for: article)
                                vm.reorder()
                            } label: { Label("Show me less like this", systemImage: "hand.thumbsdown") }
                        }
                    case .ad:
                        NativeAdSlot()
                    }
                }
                caughtUpFooter
            }
            .listStyle(.plain)
            .refreshable { await vm.refresh() }
            .onAppear { scrollProxy = proxy }
        }
    }

    private var caughtUpFooter: some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.circle").font(.title2).foregroundStyle(.green)
            Text("You're all caught up").font(.subheadline.weight(.semibold))
            Text("Pull down to check for fresh stories.").font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .listRowSeparator(.hidden)
    }

    /// Explains why an article is in the feed, from on-device signals.
    private func whyReason(for article: Article) -> String {
        let pinned = article.tags.filter(store.pinnedTags.contains).prefix(2).map { TagChips.display($0) }
        let top = Set(store.topTags(limit: 25).map(\.tag))
        let matches = article.tags.filter { top.contains($0) }.prefix(3).map { TagChips.display($0) }

        var line: String
        if !pinned.isEmpty {
            line = "You pinned \(pinned.joined(separator: ", "))."
        } else if !matches.isEmpty {
            line = "It matches your interest in \(matches.joined(separator: ", "))."
        } else {
            line = "A fresh pick to broaden your feed beyond your usual topics."
        }
        return line + "\n\nFrom \(article.pillar ?? article.section.capitalized)."
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
        lastOpened = article
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
