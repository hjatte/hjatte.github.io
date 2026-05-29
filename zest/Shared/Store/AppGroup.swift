import Foundation

/// Constants shared between the app and the widget extension.
///
/// The App Group lets the app and widget read/write the same `UserDefaults`
/// container, so the widget can show the same personalised headlines the app
/// computed. After generating the project you must enable this exact App Group
/// on BOTH targets in Signing & Capabilities (it must match `identifier`).
enum AppGroup {
    /// Change `com.hjatte.zest` if you rename the app — must match on both targets.
    static let identifier = "group.com.hjatte.zest"

    /// Custom URL scheme used to deep-link from the widget into a specific article.
    static let urlScheme = "zest"

    /// Shared defaults container. Falls back to `.standard` if the App Group
    /// isn't configured yet, so the app still runs during early setup.
    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}
