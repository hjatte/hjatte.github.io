import Foundation

/// A news article, normalised from whatever API produced it.
struct Article: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let trailText: String?
    let section: String          // e.g. "politics"
    let pillar: String?          // Guardian "pillar", e.g. "News", "Sport"
    let url: String
    let thumbnailURL: String?
    let publishedAt: Date

    /// Lower-cased interest tokens used by the learning engine, e.g.
    /// a UK politics story yields ["uk", "politics", "news", ...].
    /// These are what get +/- points when you interact.
    let tags: [String]
}

extension Article {
    /// Builds the set of interest tokens from a section id + raw tag ids.
    /// Splits on "/" and "-" so "uk-news" → ["uk", "news"] and
    /// "politics/politics" → ["politics"], matching how a human would
    /// describe the topic ("uk" and "politics" go up when you click).
    static func tokens(section: String, pillar: String?, rawTags: [String]) -> [String] {
        var tokens = Set<String>()

        func add(_ raw: String) {
            for piece in raw.split(whereSeparator: { $0 == "/" || $0 == "-" || $0 == " " }) {
                let token = piece.lowercased().trimmingCharacters(in: .whitespaces)
                if token.count >= 2, !Self.stopWords.contains(token) {
                    tokens.insert(token)
                }
            }
        }

        add(section)
        if let pillar { add(pillar) }
        rawTags.forEach(add)
        return Array(tokens)
    }

    private static let stopWords: Set<String> = [
        "the", "and", "for", "with", "from", "this", "that", "are", "was"
    ]
}
