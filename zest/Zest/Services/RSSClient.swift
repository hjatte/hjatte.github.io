import Foundation

/// Aggregates many free RSS/Atom feeds into one stream of articles.
/// No API key, works for everyone. Per-feed failures are swallowed so one
/// dead source never breaks the app.
struct RSSClient: NewsAPIClient {
    private let session: URLSession
    private let sources: @Sendable () -> [NewsSource]
    private let maxItemsPerFeed = 12
    private let maxConcurrent = 10

    /// `sources` is a closure so the live set of enabled sources is read fresh
    /// on every fetch (the user can toggle them in Settings).
    init(session: URLSession = .shared,
         sources: @escaping @Sendable () -> [NewsSource] = { SourceSettings.shared.enabledSources }) {
        self.session = session
        self.sources = sources
    }

    func fetchTuningDeck() async throws -> [Article] {
        try await aggregate().shuffled()
    }

    func fetchFeed(interests: [String]) async throws -> [Article] {
        // RSS can't be queried, so we pull everything enabled and let
        // FeedRanker personalise it against the interest profile.
        try await aggregate()
    }

    // MARK: Aggregation

    private func aggregate() async throws -> [Article] {
        let sources = self.sources()
        guard !sources.isEmpty else { throw NewsAPIError.noSources }

        var all: [Article] = []
        await withTaskGroup(of: [Article].self) { group in
            var iterator = sources.makeIterator()
            // Keep at most `maxConcurrent` feed fetches in flight at once.
            for _ in 0..<min(maxConcurrent, sources.count) {
                if let source = iterator.next() {
                    group.addTask { await self.fetchOne(source) }
                }
            }
            for await batch in group {
                all.append(contentsOf: batch)
                if let source = iterator.next() {
                    group.addTask { await self.fetchOne(source) }
                }
            }
        }

        guard !all.isEmpty else { throw NewsAPIError.allSourcesFailed }

        // De-dupe by article id (link/guid).
        var seen = Set<String>()
        return all.filter { seen.insert($0.id).inserted }
    }

    /// Fetches and parses a single feed. Never throws — returns [] on failure
    /// so a flaky source can't take down the whole feed.
    private func fetchOne(_ source: NewsSource) async -> [Article] {
        do {
            var request = URLRequest(url: source.feedURL)
            request.setValue("Zest/1.0 (RSS reader)", forHTTPHeaderField: "User-Agent")
            request.timeoutInterval = 12

            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return []
            }
            return RSSParser.parse(data)
                .prefix(maxItemsPerFeed)
                .compactMap { makeArticle($0, source: source) }
        } catch {
            return []
        }
    }

    /// Requests a larger version of small CDN thumbnails so cards aren't blurry.
    /// BBC's image CDN takes the pixel width in the path and is unsigned, so we
    /// can safely bump it up. Other providers are left untouched.
    private static func enhanceImageURL(_ url: String?) -> String? {
        guard let url else { return nil }
        // BBC's image CDN puts the pixel width in the path (e.g. /240/cpsprodpb/)
        // and is unsigned, so we can safely request a larger, sharper version.
        if url.contains("bbci.co.uk") {
            return url.replacingOccurrences(of: #"/\d{2,4}/cpsprodpb/"#,
                                            with: "/800/cpsprodpb/",
                                            options: .regularExpression)
        }
        return url
    }

    private func makeArticle(_ item: RSSParser.RawItem, source: NewsSource) -> Article? {
        let link = item.link.isEmpty ? item.guid : item.link
        guard !link.isEmpty, !item.title.isEmpty else { return nil }

        return Article(
            id: item.guid.isEmpty ? link : item.guid,
            title: item.title.decodingHTMLEntities,
            trailText: item.summary.strippingHTML.nilIfEmpty,
            section: source.category,
            pillar: source.name,
            url: link,
            thumbnailURL: Self.enhanceImageURL(item.imageURL),
            publishedAt: item.published ?? .now,
            tags: Article.tokens(
                section: source.category,
                pillar: source.sourceToken,
                rawTags: item.categories
            )
        )
    }
}

// MARK: - String cleanup

private extension String {
    /// Strips HTML tags from feed summaries.
    var strippingHTML: String {
        replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .decodingHTMLEntities
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Decodes the handful of common HTML entities seen in feed titles.
    var decodingHTMLEntities: String {
        var s = self
        let map = ["&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"",
                   "&#39;": "'", "&apos;": "'", "&nbsp;": " ", "&#x27;": "'", "&hellip;": "…"]
        for (k, v) in map { s = s.replacingOccurrences(of: k, with: v) }
        return s
    }

    var nilIfEmpty: String? { isEmpty ? nil : self }
}
