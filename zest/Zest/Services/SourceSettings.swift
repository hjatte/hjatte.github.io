import Foundation
import Combine

/// Tracks which sources the user has switched on. Defaults to all enabled, so
/// the app works fully on first launch with no setup.
final class SourceSettings: ObservableObject {
    static let shared = SourceSettings()

    @Published private(set) var disabledIDs: Set<String>

    private let key = "sources.disabled.v1"
    private let defaults = UserDefaults.standard

    private init() {
        if let saved = defaults.array(forKey: key) as? [String] {
            disabledIDs = Set(saved)
        } else {
            disabledIDs = []
        }
    }

    func isEnabled(_ source: NewsSource) -> Bool { !disabledIDs.contains(source.id) }

    func setEnabled(_ enabled: Bool, for source: NewsSource) {
        if enabled { disabledIDs.remove(source.id) } else { disabledIDs.insert(source.id) }
        defaults.set(Array(disabledIDs), forKey: key)
    }

    /// The sources the aggregator should actually fetch.
    var enabledSources: [NewsSource] {
        FeedCatalog.all.filter(isEnabled)
    }
}
