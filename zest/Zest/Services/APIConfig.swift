import Foundation

/// Reads configuration baked in at build time (from Configs/Secrets.xcconfig →
/// Info.plist) and lets the user override the key at runtime in Settings.
enum APIConfig {
    private static let runtimeKeyDefault = "guardian.apiKey.override"

    /// The Guardian API key, preferring a value the user typed in Settings,
    /// falling back to the one compiled in from the xcconfig.
    static var guardianKey: String {
        if let override = UserDefaults.standard.string(forKey: runtimeKeyDefault),
           !override.isEmpty {
            return override
        }
        let baked = (Bundle.main.object(forInfoDictionaryKey: "GuardianAPIKey") as? String) ?? ""
        return baked.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static var hasKey: Bool { !guardianKey.isEmpty }

    static func setRuntimeKey(_ key: String) {
        UserDefaults.standard.set(key.trimmingCharacters(in: .whitespacesAndNewlines),
                                  forKey: runtimeKeyDefault)
    }
}
