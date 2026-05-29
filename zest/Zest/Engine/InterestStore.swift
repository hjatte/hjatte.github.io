import Foundation
import Combine

/// Everything we persist, as one blob. Saved locally *and* mirrored to iCloud
/// so your interests follow you across your own devices.
private struct PersistedState: Codable {
    var profile: InterestProfile
    var seen: [String]
    var pinned: [String]
    var shown: [String]?     // optional so older saved data still decodes
    var activeDay: Int?      // how many distinct days the app has been opened
    var lastActiveDate: String?
    var updatedAt: Date
}

/// Owns the user's `InterestProfile`, persists it, and syncs it across the
/// user's devices via iCloud key-value storage (no login required — it uses
/// whatever iCloud account the device is signed into). Local storage is always
/// the source of truth; iCloud is a mirror that wins only when it's newer.
final class InterestStore: ObservableObject {
    /// Single shared instance observed across the app.
    static let shared = InterestStore()

    @Published private(set) var profile: InterestProfile
    @Published private(set) var seenIDs: Set<String>      // articles you opened/read
    @Published private(set) var pinnedTags: Set<String>
    /// Articles that scrolled into view (but weren't opened). Excluded from
    /// future feeds unless they very strongly match your interests.
    private(set) var shownIDs: Set<String> = []

    private let defaults = AppGroup.defaults
    private let cloud = NSUbiquitousKeyValueStore.default
    private let stateKey = "interest.state.v2"
    private var lastUpdatedAt: Date = .distantPast

    // MARK: Active-day decay clock
    // Interests decay by *days you open the app*, not calendar days. We model
    // this with a synthetic "now" that only advances on active days, so the
    // half-life logic in InterestProfile works unchanged.
    private(set) var activeDay: Int = 0
    private var lastActiveDate: String?
    private static let decayReference = Date(timeIntervalSinceReferenceDate: 0)
    var decayNow: Date { Self.decayReference.addingTimeInterval(Double(activeDay) * 86_400) }

    init() {
        profile = InterestProfile()
        seenIDs = []
        pinnedTags = []

        if let local = decode(defaults.data(forKey: stateKey)) { apply(local) }
        if let remote = decode(cloud.data(forKey: stateKey)), remote.updatedAt > lastUpdatedAt {
            apply(remote)
            saveLocalOnly(remote)
        }

        // Migrate older saves (which decayed by calendar time) onto the clock.
        let migrating = (lastActiveDate == nil && !profile.isEmpty)
        if activeDay == 0 { activeDay = 1 }
        let today = Self.dayKey()
        if lastActiveDate != today {                 // a new active day
            activeDay += 1
            lastActiveDate = today
        }
        if migrating { profile.restampAll(to: decayNow) }

        profile.prune(now: decayNow)

        // React to changes pushed from the user's other devices (block-based
        // API so this plain Swift class needn't be an NSObject).
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloud, queue: .main) { [weak self] _ in
                self?.mergeFromCloud()
            }
        _ = cloud.synchronize()
        persist(syncCloud: false)   // save today's active-day bookkeeping
    }

    private static func dayKey(_ date: Date = Date()) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    /// Strongest interests right now, using the active-day decay clock.
    func topTags(limit: Int = 12) -> [TagScore] {
        profile.topTags(limit: limit, now: decayNow)
    }

    // MARK: Interactions

    func record(_ event: InteractionEvent, for article: Article) {
        profile.apply(event, tags: article.tags, now: decayNow)
        if case .openArticle = event { markSeen(article) }
        persist()
    }

    func registerImpressions(for articles: [Article]) {
        let tags = articles.flatMap(\.tags)
        guard !tags.isEmpty else { return }
        profile.registerImpressions(tags: tags, now: decayNow)
        persist()
    }

    func markSeen(_ article: Article) {
        seenIDs.insert(article.id)
        if seenIDs.count > 2_000 { seenIDs = Set(seenIDs.prefix(1_500)) }
    }

    /// Records that an article scrolled into view. Persisted locally only (no
    /// iCloud round-trip) since this fires often during scrolling.
    func markShown(_ article: Article) {
        guard shownIDs.insert(article.id).inserted else { return }
        if shownIDs.count > 2_000 { shownIDs = Set(shownIDs.prefix(1_500)) }
        persist(syncCloud: false)
    }

    /// How strongly an article matches the current interest profile.
    func interestScore(for article: Article) -> Double {
        article.tags.reduce(0) { $0 + profile.effectiveScore($1, asOf: decayNow) }
    }

    func setHalfLife(_ days: Double) {
        profile.halfLifeDays = max(1, days)
        persist()
    }

    // MARK: Pinned topics

    func pin(_ rawTopic: String) {
        let tokens = InterestStore.tokenize(rawTopic)
        guard !tokens.isEmpty else { return }
        pinnedTags.formUnion(tokens)
        profile.apply(.onboardingLike, tags: tokens, now: decayNow)
        persist()
    }

    func unpin(_ tag: String) {
        pinnedTags.remove(tag)
        persist()
    }

    func isPinned(_ tag: String) -> Bool { pinnedTags.contains(tag) }

    static func tokenize(_ raw: String) -> [String] {
        raw.lowercased()
            .split { $0 == " " || $0 == "-" || $0 == "," }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.count >= 2 }
    }

    func reset() {
        profile = InterestProfile()
        seenIDs = []
        pinnedTags = []
        shownIDs = []
        persist()
    }

    // MARK: Widget hand-off

    func publishToWidget(rankedTop articles: [Article]) {
        let headlines = articles.prefix(6).map {
            WidgetHeadline(id: $0.id, title: $0.title, section: $0.section,
                           source: $0.pillar ?? "", url: $0.url, publishedAt: $0.publishedAt,
                           score: interestScore(for: $0))
        }
        let snapshot = WidgetSnapshot(
            headlines: Array(headlines),
            updatedAt: .now,
            topInterests: profile.topTags(limit: 3, now: decayNow).map(\.tag)
        )
        SharedStore.writeSnapshot(snapshot)
    }

    // MARK: Persistence + sync

    private func persist(syncCloud: Bool = true) {
        lastUpdatedAt = Date()
        let state = PersistedState(profile: profile, seen: Array(seenIDs),
                                   pinned: Array(pinnedTags), shown: Array(shownIDs),
                                   activeDay: activeDay, lastActiveDate: lastActiveDate,
                                   updatedAt: lastUpdatedAt)
        guard let data = try? JSONEncoder.shared.encode(state) else { return }
        defaults.set(data, forKey: stateKey)   // local: always the source of truth
        if syncCloud {
            cloud.set(data, forKey: stateKey)   // mirror to iCloud
            _ = cloud.synchronize()
        }
    }

    private func saveLocalOnly(_ state: PersistedState) {
        if let data = try? JSONEncoder.shared.encode(state) {
            defaults.set(data, forKey: stateKey)
        }
    }

    private func apply(_ state: PersistedState) {
        profile = state.profile
        seenIDs = Set(state.seen)
        pinnedTags = Set(state.pinned)
        shownIDs = Set(state.shown ?? [])
        activeDay = state.activeDay ?? activeDay
        lastActiveDate = state.lastActiveDate
        lastUpdatedAt = state.updatedAt
    }

    private func decode(_ data: Data?) -> PersistedState? {
        guard let data else { return nil }
        return try? JSONDecoder.shared.decode(PersistedState.self, from: data)
    }

    /// Adopt the iCloud copy when another device saved something newer.
    private func mergeFromCloud() {
        guard let remote = decode(cloud.data(forKey: stateKey)),
              remote.updatedAt > lastUpdatedAt else { return }
        apply(remote)
        saveLocalOnly(remote)
    }
}
