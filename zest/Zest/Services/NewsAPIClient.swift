import Foundation

/// Abstraction over a news source so the rest of the app doesn't care whether
/// stories come from The Guardian, NewsAPI, GNews, etc. Swap the implementation
/// in `ZestApp` to change providers.
protocol NewsAPIClient {
    /// A big, shuffled mix across many topics — used to seed the swipe-to-tune deck.
    func fetchTuningDeck() async throws -> [Article]

    /// Fresh stories biased toward the user's interests for the main feed.
    func fetchFeed(interests: [String]) async throws -> [Article]
}

enum NewsAPIError: LocalizedError {
    case noSources
    case allSourcesFailed
    case badResponse(Int)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .noSources:        return "No sources selected. Turn some on in Settings."
        case .allSourcesFailed: return "Couldn't reach any news sources. Check your connection and try again."
        case .badResponse(let c): return "A news source returned an error (HTTP \(c))."
        case .decoding:         return "Couldn't read the news response."
        }
    }
}
