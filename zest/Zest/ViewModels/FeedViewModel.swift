import Foundation

@MainActor
final class FeedViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle, loading, loaded, empty
        case failed(String)
    }

    @Published private(set) var articles: [Article] = []
    @Published private(set) var state: LoadState = .idle

    private let client: NewsAPIClient
    private let store: InterestStore

    init(client: NewsAPIClient, store: InterestStore) {
        self.client = client
        self.store = store
    }

    func loadIfNeeded() async {
        if articles.isEmpty { await refresh() }
    }

    func refresh() async {
        state = .loading
        do {
            let interests = store.profile.topTags(limit: 8).map(\.tag)
            let fetched = try await client.fetchFeed(interests: interests)
            let ranked = FeedRanker.rank(fetched, profile: store.profile,
                                         seenIDs: store.seenIDs, pinnedTags: store.pinnedTags)

            articles = ranked
            state = ranked.isEmpty ? .empty : .loaded

            // The feed shaped the user's world this session: record what was
            // shown (so unclicked topics fade) and hand the top to the widget.
            store.registerImpressions(for: Array(ranked.prefix(40)))
            store.publishToWidget(rankedTop: ranked)
        } catch {
            state = .failed((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
        }
    }

    /// Re-rank in place without refetching (cheap, e.g. after an interaction).
    func reorder() {
        articles = FeedRanker.rank(articles, profile: store.profile,
                                   seenIDs: store.seenIDs, pinnedTags: store.pinnedTags)
    }
}
