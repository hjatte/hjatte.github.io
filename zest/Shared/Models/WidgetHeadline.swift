import Foundation

/// A single headline the app hands to the widget. Kept deliberately small so
/// it serialises cheaply into the shared App Group container.
struct WidgetHeadline: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let section: String
    let url: String
    let publishedAt: Date

    /// Personalisation score at the time it was written, for debugging/sorting.
    let score: Double
}

/// The snapshot the app publishes for the widget to render.
struct WidgetSnapshot: Codable {
    var headlines: [WidgetHeadline]
    var updatedAt: Date
    /// Top interest labels (e.g. "uk", "politics") for the widget footer.
    var topInterests: [String]

    static let empty = WidgetSnapshot(headlines: [], updatedAt: .distantPast, topInterests: [])
}
