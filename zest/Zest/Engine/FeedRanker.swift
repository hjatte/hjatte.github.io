import Foundation

/// Scores and orders articles for the personalised feed.
enum FeedRanker {
    /// Ranks `articles` against the user's `profile`.
    ///
    /// score = Σ effectiveScore(tag) over the article's tags
    ///       + a small recency bonus (fresher stories float up)
    ///       − a penalty for already-seen stories
    ///       + a little random "exploration" so the feed never collapses
    ///         into a single topic and faded interests can resurface.
    static func rank(
        _ articles: [Article],
        profile: InterestProfile,
        seenIDs: Set<String>,
        now: Date = .now,
        explorationEpsilon: Double = 4
    ) -> [Article] {
        articles
            .map { article -> (Article, Double) in
                let interest = article.tags.reduce(0) { $0 + profile.effectiveScore($1, asOf: now) }

                let ageHours = max(0, now.timeIntervalSince(article.publishedAt) / 3600)
                let recency = 12 * exp(-ageHours / 48)        // ~2-day freshness window

                let seenPenalty = seenIDs.contains(article.id) ? 30.0 : 0

                let exploration = Double.random(in: 0...explorationEpsilon)

                return (article, interest + recency - seenPenalty + exploration)
            }
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }
}
