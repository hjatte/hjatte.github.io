import SwiftUI

/// The main scrollable personalised feed.
struct FeedView: View {
    @StateObject private var vm: FeedViewModel
    @EnvironmentObject private var store: InterestStore
    @Binding var pendingURL: URL?

    @State private var reader: ReaderLink?

    init(client: NewsAPIClient, pendingURL: Binding<URL?>) {
        _vm = StateObject(wrappedValue: FeedViewModel(client: client, store: InterestStore.shared))
        _pendingURL = pendingURL
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Your Feed")
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
            list
        }
    }

    private var list: some View {
        List(vm.articles) { article in
            Button {
                open(article)
            } label: {
                ArticleRow(article: article)
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

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(article.section.uppercased())
                    .font(.caption2.weight(.bold)).foregroundStyle(.tint)
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
