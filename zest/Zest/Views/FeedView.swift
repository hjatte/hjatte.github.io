import SwiftUI

/// The main scrollable personalised feed.
struct FeedView: View {
    @StateObject private var vm: FeedViewModel
    @EnvironmentObject private var store: InterestStore
    @Binding var pendingURL: URL?

    @State private var reader: ReaderLink?
    @State private var searchText = ""

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
                .navigationTitle("Your Feed")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $searchText, prompt: "Search this feed")
                .toolbar {
                    Button { Task { await vm.refresh() } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
        }
        .task { await vm.loadIfNeeded() }
        // Open a story the widget asked for.
        .onChange(of: pendingURL) { _, url in
            if let url { reader = ReaderLink(url: url); pendingURL = nil }
        }
        .sheet(item: $reader) { link in
            SafariView(url: link.url).ignoresSafeArea()
        }
    }

    @ViewBuilder private var content: some View {
        switch vm.state {
        case .idle, .loading:
            ProgressView("Loading your feed…")
        case .failed(let message):
            ErrorState(message: message) { Task { await vm.refresh() } }
        case .empty:
            ContentUnavailableView("Nothing yet", systemImage: "newspaper",
                                   description: Text("Pull to refresh or tune your interests."))
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

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    SourceBadge(source: article.pillar ?? article.section.capitalized,
                                category: article.section)
                    if isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2).foregroundStyle(.tint)
                    }
                }
                Text(article.title).font(.headline).lineLimit(3)
                if let trail = article.trailText {
                    Text(trail).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                }
                Text(article.publishedAt, format: .relative(presentation: .named))
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            if let urlString = article.thumbnailURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { $0.resizable().scaledToFill() } placeholder: {
                    Rectangle().fill(.quaternary)
                }
                .frame(width: 88, height: 88).clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.vertical, 4)
    }
}
