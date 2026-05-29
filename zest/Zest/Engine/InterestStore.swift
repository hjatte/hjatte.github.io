import Foundation
import Combine

/// Owns the user's `InterestProfile`, persists it to the shared App Group
/// container, and turns user interactions into score changes. This is the
/// single source of truth the whole app observes.
final class InterestStore: ObservableObject {
    /// Single shared instance. Views build their view models against this and
    /// also observe it via `@EnvironmentObject`, so there's one source of truth.
    static let shared = InterestStore()

    @Published private(set) var profile: InterestProfile
    @Published private(set) var seenIDs: Set<String>
    /// Topics the user explicitly pinned. These are always boosted in the feed
    /// and never decay or get pruned — they sit on top of what the engine learns.
    @Published private(set) var pinnedTags: Set<String>

    private let defaults = AppGroup.defaults
    private let profileKey = "interest.profile.v1"
    private let seenKey = "interest.seen.v1"
    private let pinnedKey = "interest.pinned.v1"

    init() {
        if let data = defaults.data(forKey: profileKey),
           let saved = try? JSONDecoder.shared.decode(InterestProfile.self, from: data) {
            profile = saved
        } else {
            profile = InterestProfile()
        }

        if let data = defaults.data(forKey: seenKey),
           let saved = try? JSONDecoder.shared.decode([String].self, from: data) {
            seenIDs = Set(saved)
        } else {
            seenIDs = []
        }

        if let saved = defaults.array(forKey: pinnedKey) as? [String] {
            pinnedTags = Set(saved)
        } else {
            pinnedTags = []
        }

        profile.prune()
    }

    // MARK: Interactions

    func record(_ event: InteractionEvent, for article: Article) {
        profile.apply(event, tags: article.tags)
        if case .openArticle = event { markSeen(article) }
        persist()
    }

    /// Call when a batch of articles is shown in the feed so unclicked topics fade.
    func registerImpressions(for articles: [Article]) {
        let tags = articles.flatMap(\.tags)
        guard !tags.isEmpty else { return }
        profile.registerImpressions(tags: tags)
        persist()
    }

    func markSeen(_ article: Article) {
        seenIDs.insert(article.id)
        // Keep the seen set bounded so it doesn't grow forever.
        if seenIDs.count > 2_000 { seenIDs = Set(seenIDs.prefix(1_500)) }
    }

    /// Adjusts how fast interests decay (bound to the slider in Interests).
    func setHalfLife(_ days: Double) {
        profile.halfLifeDays = max(1, days)
        persist()
    }

    // MARK: Pinned topics

    /// Pins a free-text topic. Multi-word input is split into tokens (so
    /// "climate change" pins both "climate" and "change"), matching how
    /// articles are tagged. Also gives each token a learned-score head start.
    func pin(_ rawTopic: String) {
        let tokens = InterestStore.tokenize(rawTopic)
        guard !tokens.isEmpty else { return }
        pinnedTags.formUnion(tokens)
        profile.apply(.onboardingLike, tags: tokens) // so it shows up immediately
        persist()
    }

    func unpin(_ tag: String) {
        pinnedTags.remove(tag)
        persist()
    }

    func isPinned(_ tag: String) -> Bool { pinnedTags.contains(tag) }

    /// Normalises free text into interest tokens (lower-cased, split on spaces
    /// and hyphens, short/stop words dropped).
    static func tokenize(_ raw: String) -> [String] {
        raw.lowercased()
            .split { $0 == " " || $0 == "-" || $0 == "," }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.count >= 2 }
    }

    /// Wipe everything (used by "Reset interests").
    func reset() {
        profile = InterestProfile()
        seenIDs = []
        pinnedTags = []
        persist()
    }

    // MARK: Widget hand-off

    /// Publishes the top of the personalised feed to the widget.
    func publishToWidget(rankedTop articles: [Article]) {
        let headlines = articles.prefix(6).map {
            WidgetHeadline(id: $0.id, title: $0.title, section: $0.section,
                           source: $0.pillar ?? "", url: $0.url, publishedAt: $0.publishedAt,
                           score: $0.tags.reduce(0) { $0 + profile.effectiveScore($1) })
        }
        let snapshot = WidgetSnapshot(
            headlines: Array(headlines),
            updatedAt: .now,
            topInterests: profile.topTags(limit: 3).map(\.tag)
        )
        SharedStore.writeSnapshot(snapshot)
    }

    // MARK: Persistence

    private func persist() {
        if let data = try? JSONEncoder.shared.encode(profile) {
            defaults.set(data, forKey: profileKey)
        }
        if let data = try? JSONEncoder.shared.encode(Array(seenIDs)) {
            defaults.set(data, forKey: seenKey)
        }
        defaults.set(Array(pinnedTags), forKey: pinnedKey)
    }
}
