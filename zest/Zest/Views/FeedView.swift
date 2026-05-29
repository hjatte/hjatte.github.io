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
        .fullScreenCover(item: $reader) { link in
            SafariView(url: link.url).ignoresSafeArea()
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

    private var list: some View {
        List(visibleArticles) { article in
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
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    SourceBadge(source: article.pillar ?? article.section.capitalized,
                                category: article.section,
                                domain: URL(string: article.url)?.host)
                    if isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2).foregroundStyle(.tint)
                    }
                }
                Text(article.title).font(.headline).lineLimit(3)
                if let trail = article.trailText {
                    Text(trail).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                }
                if !displayTags.isEmpty {
                    TagChips(tags: displayTags)
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
