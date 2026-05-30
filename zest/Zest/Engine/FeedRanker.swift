import Foundation

/// Scores, diversifies and assembles the personalised feed.
enum FeedRanker {
    /// Produces the final ordered feed:
    ///  1. score = interest + pinned boost + recency − seen penalty + bubble-aware exploration
    ///  2. MMR diversity pass (no run of near-identical takes)
    ///  3. civic quota (a couple of fresh general-news items kept near the top)
    ///
    /// `decayDate` drives interest decay (the active-day clock); recency always
    /// uses real wall-clock time.
    static func rank(
        _ articles: [Article],
        profile: InterestProfile,
        seenIDs: Set<String>,
        pinnedTags: Set<String> = [],
        interestTopics: [String] = [],
        decayDate: Date = .now,
        explorationEpsilon: Double = 4
    ) -> [Article] {
        let realNow = Date()

        let scored = articles.map { article -> (Article, Double) in
            let interest = article.tags.reduce(0) { $0 + profile.effectiveScore($1, asOf: decayDate) }

            let pinnedHits = article.tags.filter(pinnedTags.contains).count
            let pinnedBoost = pinnedHits > 0 ? 200.0 + Double(pinnedHits - 1) * 30 : 0

            let ageHours = max(0, realNow.timeIntervalSince(article.publishedAt) / 3600)
            let recency = 12 * exp(-ageHours / 48)        // ~2-day freshness window

            let seenPenalty = seenIDs.contains(article.id) ? 30.0 : 0

            // Serendipity dial lifts stories by how far outside your topics they are.
            let bubbleDistance = TopicGraph.distance(article.tags, from: interestTopics)
            let exploration = explorationEpsilon * bubbleDistance + Double.random(in: 0...2)

            return (article, interest + pinnedBoost + recency - seenPenalty + exploration)
        }
        .sorted { $0.1 > $1.1 }

        return civicAdjusted(diversified(scored), now: realNow)
    }

    // MARK: Diversity (Maximal Marginal Relevance)

    /// Greedily reorders so each pick is penalised by similarity to the few
    /// already placed — prevents ten near-identical stories in a row.
    private static func diversified(_ scored: [(Article, Double)]) -> [Article] {
        var remaining = scored
        var result: [Article] = []
        var recentTags: [Set<String>] = []
        let lambda = 0.6

        while !remaining.isEmpty {
            var bestIndex = 0
            var bestValue = -Double.greatestFiniteMagnitude
            for (i, pair) in remaining.enumerated() {
                let tags = Set(pair.0.tags)
                let maxSim = recentTags.suffix(12).map { jaccard($0, tags) }.max() ?? 0
                let value = pair.1 - lambda * maxSim * 40
                if value > bestValue { bestValue = value; bestIndex = i }
            }
            let picked = remaining.remove(at: bestIndex)
            result.append(picked.0)
            recentTags.append(Set(picked.0.tags))
        }
        return result
    }

    private static func jaccard(_ a: Set<String>, _ b: Set<String>) -> Double {
        let union = a.union(b).count
        return union == 0 ? 0 : Double(a.intersection(b).count) / Double(union)
    }

    // MARK: Civic quota

    /// Guarantees a couple of fresh, important general-news items appear near the
    /// top, regardless of personalisation.
    private static func civicAdjusted(_ list: [Article], now: Date) -> [Article] {
        func isCivic(_ a: Article) -> Bool {
            ["top", "world", "politics"].contains(a.section)
                && now.timeIntervalSince(a.publishedAt) < 48 * 3600
        }
        var final = list
        let civic = list.filter(isCivic).sorted { $0.publishedAt > $1.publishedAt }
        for (slot, item) in zip([2, 5], civic.prefix(2)) {
            if let idx = final.firstIndex(of: item), idx > 6 {
                final.remove(at: idx)
                final.insert(item, at: min(slot, final.count))
            }
        }
        return final
    }
}
