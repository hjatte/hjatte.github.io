import Foundation

/// One free RSS/Atom feed in the catalogue.
struct NewsSource: Identifiable, Hashable, Codable {
    let id: String          // stable slug, e.g. "bbc-technology"
    let name: String        // publisher, e.g. "BBC News"
    let category: String    // our normalised category, e.g. "technology"
    let feedURL: URL

    /// Lower-cased token for the publisher, so the engine can also learn that
    /// you (say) prefer the BBC. e.g. "BBC News" -> "bbc".
    var sourceToken: String {
        name.lowercased().split(separator: " ").first.map(String.init) ?? name.lowercased()
    }
}

/// A category and the sources within it (for the Settings list).
struct CategoryGroup: Identifiable {
    let category: String
    let sources: [NewsSource]
    var id: String { category }
}
