import Foundation

/// A small, baked-in "map" of how news topics relate — a stand-in for the
/// collaborative signal a big platform gets from millions of users.
///
/// Topics are grouped into clusters; some clusters are marked adjacent (people
/// into one tend to dabble in the other). "Bubble distance" between an article
/// and your interests is just the distance between their clusters:
///   0.0 = squarely in your bubble · 0.5 = an adjacent, related area
///   1.0 = genuinely outside your usual topics.
///
/// It can be refined offline from public datasets (e.g. Microsoft's MIND), but
/// a curated version needs no network and ships in the app.
enum TopicGraph {
    /// topic token → cluster id
    static let cluster: [String: String] = build([
        "pol":     ["politics", "world", "uk", "us", "usa", "eu", "europe", "election",
                    "elections", "war", "ukraine", "russia", "china", "gaza", "israel",
                    "government", "immigration", "uk-news", "trump", "biden", "starmer",
                    "parliament", "westminster", "diplomacy", "protest", "law", "courts"],
        "biz":     ["business", "economy", "economics", "markets", "market", "finance",
                    "money", "tax", "trade", "banking", "stocks", "inflation", "jobs",
                    "housing", "retail", "property", "investing"],
        "tech":    ["technology", "tech", "ai", "gadgets", "apple", "iphone", "android",
                    "software", "startups", "startup", "internet", "crypto", "cybersecurity",
                    "google", "microsoft", "meta", "tesla", "robotics", "data", "privacy"],
        "sci":     ["science", "space", "astronomy", "physics", "biology", "research",
                    "nature", "environment", "climate", "energy", "weather", "ocean",
                    "wildlife", "genetics", "chemistry"],
        "health":  ["health", "wellbeing", "wellness", "medicine", "fitness", "mental",
                    "nutrition", "covid", "disease", "diet", "sleep", "longevity"],
        "sport":   ["sport", "sports", "football", "soccer", "tennis", "cricket", "rugby",
                    "f1", "formula", "olympics", "nba", "nfl", "golf", "boxing", "premier",
                    "league", "athletics", "cycling"],
        "culture": ["culture", "film", "films", "movies", "music", "books", "book", "art",
                    "arts", "entertainment", "tv", "television", "celebrity", "gaming",
                    "games", "theatre", "streaming", "design", "awards"],
        "life":    ["lifestyle", "food", "recipes", "travel", "fashion", "beauty", "home",
                    "style", "relationships", "parenting", "fragrance"]
    ])

    /// Clusters whose audiences overlap (distance 0.5 rather than 1.0).
    private static let adjacent: Set<String> = [
        "biz|pol", "pol|sci", "biz|tech", "sci|tech", "health|sci", "culture|life",
        "health|life", "culture|tech", "biz|life", "pol|health"
    ]

    private static func clusterDistance(_ a: String, _ b: String) -> Double {
        if a == b { return 0 }
        return adjacent.contains([a, b].sorted().joined(separator: "|")) ? 0.5 : 1.0
    }

    /// 0 (in-bubble) … 1 (well outside). Neutral 0.5 when we can't place either side.
    static func distance(_ articleTags: [String], from interests: [String]) -> Double {
        let a = Set(articleTags.compactMap { cluster[$0] })
        let i = Set(interests.compactMap { cluster[$0] })
        guard !a.isEmpty, !i.isEmpty else { return 0.5 }
        var best = 1.0
        for x in a { for y in i { best = min(best, clusterDistance(x, y)) } }
        return best
    }

    private static func build(_ groups: [String: [String]]) -> [String: String] {
        var map: [String: String] = [:]
        for (id, topics) in groups { for t in topics { map[t] = id } }
        return map
    }
}
