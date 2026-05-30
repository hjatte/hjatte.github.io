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
        pinnedTags: Set<String> = [],
        interestTopics: [String] = [],
        now: Date = .now,
        explorationEpsilon: Double = 4
    ) -> [Article] {
        articles
            .map { article -> (Article, Double) in
                let interest = article.tags.reduce(0) { $0 + profile.effectiveScore($1, asOf: now) }

                // Pinned topics get a strong, non-decaying boost so the things
                // the user explicitly cares about reliably rise to the top.
                let pinnedHits = article.tags.filter(pinnedTags.contains).count
                let pinnedBoost = pinnedHits > 0 ? 200.0 + Double(pinnedHits - 1) * 30 : 0

                let ageHours = max(0, now.timeIntervalSince(article.publishedAt) / 3600)
                let recency = 12 * exp(-ageHours / 48)        // ~2-day freshness window

                let seenPenalty = seenIDs.contains(article.id) ? 30.0 : 0

                // Bubble-aware exploration: the serendipity dial lifts stories by
                // how far outside your usual topics they are (via TopicGraph), so
                // turning it up surfaces related-but-different areas — not noise.
                let bubbleDistance = TopicGraph.distance(article.tags, from: interestTopics)
                let exploration = explorationEpsilon * bubbleDistance + Double.random(in: 0...2)

                return (article, interest + pinnedBoost + recency - seenPenalty + exploration)
            }
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }
}
