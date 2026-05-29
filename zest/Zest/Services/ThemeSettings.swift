import SwiftUI
import Combine

/// Light / dark / follow-the-system.
enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

/// Accent colour presets used to tint the whole app.
enum AccentTheme: String, CaseIterable, Identifiable {
    case tangerine, cherry, ocean, forest, grape, graphite
    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .tangerine: return Color(red: 1.00, green: 0.50, blue: 0.00)
        case .cherry:    return Color(red: 0.90, green: 0.22, blue: 0.31)
        case .ocean:     return Color(red: 0.18, green: 0.53, blue: 0.87)
        case .forest:    return Color(red: 0.18, green: 0.62, blue: 0.36)
        case .grape:     return Color(red: 0.56, green: 0.27, blue: 0.68)
        case .graphite:  return Color(red: 0.36, green: 0.40, blue: 0.45)
        }
    }
}

/// App-wide theme choices, persisted and synced live to the UI.
final class ThemeSettings: ObservableObject {
    static let shared = ThemeSettings()

    @Published var appearance: AppAppearance { didSet { save() } }
    @Published var accent: AccentTheme { didSet { save() } }

    private let defaults = UserDefaults.standard
    private let appearanceKey = "theme.appearance"
    private let accentKey = "theme.accent"

    private init() {
        appearance = AppAppearance(rawValue: defaults.string(forKey: appearanceKey) ?? "") ?? .system
        accent = AccentTheme(rawValue: defaults.string(forKey: accentKey) ?? "") ?? .tangerine
    }

    private func save() {
        defaults.set(appearance.rawValue, forKey: appearanceKey)
        defaults.set(accent.rawValue, forKey: accentKey)
    }
}
