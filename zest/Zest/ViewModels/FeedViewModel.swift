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

    private let defaults = AppGroup.defaults
    private let cacheKey = "feed.cache.v1"
    private let maxFeed = 200

    init(client: NewsAPIClient, store: InterestStore) {
        self.client = client
        self.store = store
    }

    func loadIfNeeded() async {
        if articles.isEmpty {
            // Show the cached, relevance-ordered feed instantly (works offline)…
            let cached = unreadOnly(loadCache())
            if !cached.isEmpty {
                articles = cached
                state = .loaded
            }
            // …then refresh in the background.
            await refresh()
        }
    }

    func refresh() async {
        if articles.isEmpty { state = .loading }
        do {
            let interests = store.profile.topTags(limit: 8).map(\.tag)
            let fetched = try await client.fetchFeed(interests: interests)

            // Merge fresh stories with the relevant ones we already had, drop
            // anything read or already scrolled past (unless it strongly matches),
            // de-dupe, and rank by relevance.
            let pool = dedupe(loadCache() + fetched)
            let fresh = pool.filter(isFresh)
            let ranked = Array(
                FeedRanker.rank(fresh, profile: store.profile,
                                seenIDs: store.seenIDs, pinnedTags: store.pinnedTags)
                    .prefix(maxFeed)
            )

            articles = ranked
            state = ranked.isEmpty ? .empty : .loaded
            saveCache(ranked)

            store.registerImpressions(for: Array(ranked.prefix(40)))
            store.publishToWidget(rankedTop: ranked)
        } catch {
            // Offline / fetch failed: keep showing the cached feed if we have one.
            if articles.isEmpty {
                state = .failed((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
            }
        }
    }

    /// Re-rank in place without refetching (e.g. after "show me less"), and drop
    /// anything now read.
    func reorder() {
        let unread = unreadOnly(articles)
        articles = FeedRanker.rank(unread, profile: store.profile,
                                   seenIDs: store.seenIDs, pinnedTags: store.pinnedTags)
        saveCache(articles)
    }

    // MARK: Helpers

    /// For the instant cache view: just hide what you've already read.
    private func unreadOnly(_ list: [Article]) -> [Article] {
        list.filter { !store.seenIDs.contains($0.id) }
    }

    /// For refreshes: hide read articles, and hide ones you scrolled past before
    /// unless they *really* strongly match your interests (or a pinned topic).
    private func isFresh(_ article: Article) -> Bool {
        if store.seenIDs.contains(article.id) { return false }
        if store.shownIDs.contains(article.id) {
            let pinned = store.pinnedTags.contains(where: article.tags.contains)
            return pinned || store.interestScore(for: article) >= 60
        }
        return true
    }

    private func dedupe(_ list: [Article]) -> [Article] {
        var seen = Set<String>()
        return list.filter { seen.insert($0.id).inserted }
    }

    // MARK: Cache

    private func loadCache() -> [Article] {
        guard let data = defaults.data(forKey: cacheKey),
              let cached = try? JSONDecoder.shared.decode([Article].self, from: data)
        else { return [] }
        return cached
    }

    private func saveCache(_ list: [Article]) {
        if let data = try? JSONEncoder.shared.encode(Array(list.prefix(maxFeed))) {
            defaults.set(data, forKey: cacheKey)
        }
    }
}
