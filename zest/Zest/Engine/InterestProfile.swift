import Foundation

/// A tag paired with its current score, for display and ranking.
struct TagScore: Identifiable, Hashable {
    let tag: String
    let score: Double
    var id: String { tag }
}

/// The weight the engine keeps for a single tag (e.g. "politics").
struct TagWeight: Codable {
    /// Raw score "banked" at `lastUpdated`. The *current* score is this value
    /// after time-decay is applied (see `InterestProfile.effectiveScore`).
    var score: Double
    var lastUpdated: Date

    /// How many times stories with this tag were shown to the user…
    var impressions: Int
    /// …versus how many of those they actually opened. A high impression /
    /// low click ratio is what makes a tag "fade away" over time.
    var clicks: Int
}

/// The user's evolving interest model: a dictionary of tag → weight, with
/// exponential time-decay so anything you stop engaging with bleeds away.
struct InterestProfile: Codable {
    private(set) var weights: [String: TagWeight] = [:]

    // MARK: Tuning knobs

    /// Days for a banked score to halve with no further interaction.
    /// Smaller = the feed forgets faster.
    var halfLifeDays: Double = 14

    /// Scores are clamped to this range so nothing dominates forever.
    /// (Static so they aren't part of the saved/synced Codable data.)
    static let minScore: Double = -40
    static let maxScore: Double = 120

    /// A tag is dropped entirely once its decayed score falls below this.
    static let pruneThreshold: Double = 0.4

    // MARK: Decay

    /// The score of `tag` *right now*, after applying time-decay since it was
    /// last touched. This is what ranking and display should use.
    func effectiveScore(_ tag: String, asOf now: Date = .now) -> Double {
        guard let w = weights[tag] else { return 0 }
        let days = max(0, now.timeIntervalSince(w.lastUpdated) / 86_400)
        let decayFactor = pow(0.5, days / halfLifeDays)
        return w.score * decayFactor
    }

    // MARK: Mutations

    /// Applies an interaction to every tag on the article.
    mutating func apply(_ event: InteractionEvent, tags: [String], now: Date = .now) {
        for tag in tags {
            settle(tag, asOf: now)
            var w = weights[tag] ?? TagWeight(score: 0, lastUpdated: now, impressions: 0, clicks: 0)
            w.score = clamp(w.score + event.delta)
            w.lastUpdated = now
            if case .openArticle = event { w.clicks += 1 }
            weights[tag] = w
        }
    }

    /// Records that stories with these tags were *shown*. Each impression nudges
    /// the score down a touch, so topics you keep seeing but never tap slowly
    /// fade — exactly the "displayed but never clicked → fade away" behaviour.
    mutating func registerImpressions(tags: [String], now: Date = .now) {
        for tag in tags {
            settle(tag, asOf: now)
            guard var w = weights[tag] else { continue } // only fade tags we already track
            w.impressions += 1
            // Gentle, click-aware penalty: tags you also click on barely move.
            let clickRatio = w.impressions > 0 ? Double(w.clicks) / Double(w.impressions) : 0
            let penalty = 0.6 * (1 - min(clickRatio, 1))
            w.score = clamp(w.score - penalty)
            w.lastUpdated = now
            weights[tag] = w
        }
    }

    /// Removes tags whose decayed score has dropped below the prune threshold.
    /// Call periodically to keep the profile small and let dead interests die.
    mutating func prune(now: Date = .now) {
        weights = weights.filter { abs(effectiveScore($0.key, asOf: now)) >= Self.pruneThreshold }
    }

    /// The strongest interests right now, most-positive first.
    func topTags(limit: Int = 12, now: Date = .now) -> [TagScore] {
        weights.keys
            .map { TagScore(tag: $0, score: effectiveScore($0, asOf: now)) }
            .filter { $0.score > 0 }
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0 }
    }

    var isEmpty: Bool { weights.isEmpty }

    // MARK: Helpers

    /// Bakes the current decayed value back into `score` and stamps `now`,
    /// so subsequent deltas are applied on top of the already-decayed value.
    private mutating func settle(_ tag: String, asOf now: Date) {
        guard var w = weights[tag] else { return }
        w.score = effectiveScore(tag, asOf: now)
        w.lastUpdated = now
        weights[tag] = w
    }

    private func clamp(_ v: Double) -> Double { min(max(v, Self.minScore), Self.maxScore) }
}
