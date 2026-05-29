import XCTest
@testable import Zest

/// Verifies the learning engine behaves the way the feed depends on:
/// clicks boost, dislikes suppress, time decays, and ignored topics fade.
final class InterestEngineTests: XCTestCase {

    private func article(_ tags: [String], id: String = UUID().uuidString) -> Article {
        Article(id: id, title: "t", trailText: nil, section: tags.first ?? "news",
                pillar: nil, url: "https://example.com/\(id)", thumbnailURL: nil,
                publishedAt: .now, tags: tags)
    }

    func testClickBoostsTagsByTen() {
        var profile = InterestProfile()
        profile.apply(.openArticle, tags: ["uk", "politics"])
        XCTAssertEqual(profile.effectiveScore("uk"), 10, accuracy: 0.001)
        XCTAssertEqual(profile.effectiveScore("politics"), 10, accuracy: 0.001)
    }

    func testDislikeSuppresses() {
        var profile = InterestProfile()
        profile.apply(.onboardingDislike, tags: ["celebrity"])
        XCTAssertLessThan(profile.effectiveScore("celebrity"), 0)
    }

    func testScoreDecaysOverTime() {
        var profile = InterestProfile()
        profile.halfLifeDays = 10
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        profile.apply(.openArticle, tags: ["tech"], now: start)

        let tenDaysLater = start.addingTimeInterval(10 * 86_400)
        // One half-life later the score should be ~half.
        XCTAssertEqual(profile.effectiveScore("tech", asOf: tenDaysLater), 5, accuracy: 0.01)
    }

    func testIgnoredTopicsFadeViaImpressions() {
        var profile = InterestProfile()
        profile.apply(.onboardingLike, tags: ["finance"])  // starts at +6
        let before = profile.effectiveScore("finance")

        // Shown many times, never clicked -> should drift downward.
        for _ in 0..<10 { profile.registerImpressions(tags: ["finance"]) }
        XCTAssertLessThan(profile.effectiveScore("finance"), before)
    }

    func testPruneRemovesDeadInterests() {
        var profile = InterestProfile()
        profile.halfLifeDays = 1
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        profile.apply(.onboardingLike, tags: ["weather"], now: start)

        // Far in the future the decayed score is ~0, so prune drops it.
        let muchLater = start.addingTimeInterval(60 * 86_400)
        profile.prune(now: muchLater)
        XCTAssertEqual(profile.effectiveScore("weather", asOf: muchLater), 0, accuracy: 0.001)
        XCTAssertTrue(profile.topTags(now: muchLater).isEmpty)
    }

    func testRankerFavoursHigherInterest() {
        var profile = InterestProfile()
        profile.apply(.openArticle, tags: ["space"])  // strong interest

        let liked = article(["space"], id: "liked")
        let neutral = article(["gardening"], id: "neutral")
        // No exploration noise so the assertion is deterministic.
        let ranked = FeedRanker.rank([neutral, liked], profile: profile,
                                     seenIDs: [], explorationEpsilon: 0)
        XCTAssertEqual(ranked.first?.id, "liked")
    }
}
