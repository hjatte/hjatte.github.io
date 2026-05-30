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

extension Article {
    /// Ten deliberately varied sample stories used in onboarding so Zesty can
    /// gauge interests across the spectrum without fetching anything.
    static let onboardingSamples: [Article] = [
        sample("UK politics", "politics", "Chancellor unveils surprise overhaul of income tax",
               "The biggest shake-up to the tax system in a generation divides Westminster.",
               ["uk", "politics", "economy", "tax"]),
        sample("Technology", "technology", "New AI chip claims a tenfold leap in performance",
               "The startup says its processor could reshape how phones and laptops run AI.",
               ["technology", "ai", "us", "gadgets"]),
        sample("Football", "football", "Dramatic stoppage-time winner settles the cup final",
               "A 96th-minute strike crowns an unlikely champion in front of a roaring crowd.",
               ["sport", "football"]),
        sample("Science", "science", "Telescope captures the most distant galaxy ever seen",
               "Astronomers say the faint smudge of light dates to the universe's infancy.",
               ["science", "space", "astronomy"]),
        sample("Business", "business", "Markets rally as inflation cools faster than expected",
               "Investors cheer signs that interest rates may have peaked.",
               ["business", "markets", "economy", "finance"]),
        sample("Health", "health", "Large study links consistent sleep to a longer life",
               "Researchers tracked 100,000 people for a decade to reach the conclusion.",
               ["health", "science", "wellbeing"]),
        sample("Culture", "culture", "Low-budget indie film sweeps the awards season",
               "The surprise hit beat blockbusters to take the top prize.",
               ["culture", "film", "entertainment"]),
        sample("Environment", "environment", "Record heatwave grips southern Europe",
               "Authorities issue health warnings as temperatures break all-time highs.",
               ["environment", "climate", "world"]),
        sample("World", "world", "Historic peace deal signed after years of conflict",
               "Leaders shake hands in a ceremony watched around the globe.",
               ["world", "politics"]),
        sample("Lifestyle", "lifestyle", "Why fermented foods are taking over kitchens",
               "From kimchi to kefir, cooks are embracing gut-friendly flavours.",
               ["lifestyle", "food", "health"])
    ]

    private static func sample(_ source: String, _ section: String, _ title: String,
                               _ trail: String, _ tags: [String]) -> Article {
        Article(id: "sample-\(section)-\(title.prefix(8))", title: title, trailText: trail,
                section: section, pillar: source, url: "", thumbnailURL: nil,
                publishedAt: .now, tags: tags)
    }
}
