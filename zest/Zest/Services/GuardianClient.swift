import Foundation

/// `NewsAPIClient` backed by The Guardian's Open Platform content API.
/// Docs: https://open-platform.theguardian.com/documentation/
struct GuardianClient: NewsAPIClient {
    private let base = URL(string: "https://content.guardianapis.com/search")!
    private let session: URLSession

    /// A spread of sections so the tuning deck covers lots of ground.
    private let deckSections = [
        "politics", "technology", "business", "science", "sport", "football",
        "world", "uk-news", "culture", "film", "music", "environment",
        "money", "lifeandstyle", "games", "books", "food", "travel"
    ]

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchTuningDeck() async throws -> [Article] {
        guard APIConfig.hasKey else { throw NewsAPIError.missingKey }

        // Fetch several sections concurrently, then shuffle into one deck.
        var collected: [Article] = []
        try await withThrowingTaskGroup(of: [Article].self) { group in
            for section in deckSections {
                group.addTask { try await self.search(section: section, pageSize: 30) }
            }
            for try await batch in group { collected.append(contentsOf: batch) }
        }

        // De-dupe and shuffle for the Tinder-style deck.
        var seen = Set<String>()
        let unique = collected.filter { seen.insert($0.id).inserted }
        return unique.shuffled()
    }

    func fetchFeed(interests: [String]) async throws -> [Article] {
        guard APIConfig.hasKey else { throw NewsAPIError.missingKey }

        var collected: [Article] = []
        try await withThrowingTaskGroup(of: [Article].self) { group in
            // Targeted pulls for the user's strongest interests…
            for interest in interests.prefix(6) {
                group.addTask { try await self.search(query: interest, pageSize: 20) }
            }
            // …plus a general latest-news pull so there's always fresh exploration.
            group.addTask { try await self.search(pageSize: 30) }

            for try await batch in group { collected.append(contentsOf: batch) }
        }

        var seen = Set<String>()
        return collected.filter { seen.insert($0.id).inserted }
    }

    // MARK: Networking

    private func search(query: String? = nil,
                        section: String? = nil,
                        pageSize: Int) async throws -> [Article] {
        var comps = URLComponents(url: base, resolvingAgainstBaseURL: false)!
        var items: [URLQueryItem] = [
            .init(name: "api-key", value: APIConfig.guardianKey),
            .init(name: "page-size", value: String(pageSize)),
            .init(name: "order-by", value: "newest"),
            .init(name: "show-tags", value: "keyword"),
            .init(name: "show-fields", value: "trailText,thumbnail")
        ]
        if let query { items.append(.init(name: "q", value: query)) }
        if let section { items.append(.init(name: "section", value: section)) }
        comps.queryItems = items

        let (data, response) = try await session.data(from: comps.url!)
        guard let http = response as? HTTPURLResponse else { throw NewsAPIError.badResponse(-1) }
        guard (200...299).contains(http.statusCode) else {
            throw NewsAPIError.badResponse(http.statusCode)
        }

        do {
            let decoded = try JSONDecoder.shared.decode(GuardianEnvelope.self, from: data)
            return decoded.response.results.map(Self.makeArticle)
        } catch {
            throw NewsAPIError.decoding(error)
        }
    }

    private static func makeArticle(_ r: GuardianResult) -> Article {
        Article(
            id: r.id,
            title: r.webTitle,
            trailText: r.fields?.trailText?.strippingHTML,
            section: r.sectionId,
            pillar: r.pillarName,
            url: r.webUrl,
            thumbnailURL: r.fields?.thumbnail,
            publishedAt: r.webPublicationDate,
            tags: Article.tokens(
                section: r.sectionId,
                pillar: r.pillarName,
                rawTags: (r.tags ?? []).map(\.id)
            )
        )
    }
}

// MARK: - Guardian response DTOs

private struct GuardianEnvelope: Decodable { let response: GuardianResponse }

private struct GuardianResponse: Decodable { let results: [GuardianResult] }

private struct GuardianResult: Decodable {
    let id: String
    let webTitle: String
    let webUrl: String
    let sectionId: String
    let pillarName: String?
    let webPublicationDate: Date
    let tags: [GuardianTag]?
    let fields: GuardianFields?
}

private struct GuardianTag: Decodable { let id: String }

private struct GuardianFields: Decodable {
    let trailText: String?
    let thumbnail: String?
}

private extension String {
    /// Guardian trail text can contain light HTML; strip it for display.
    var strippingHTML: String {
        replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
