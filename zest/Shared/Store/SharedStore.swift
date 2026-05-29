import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Bridges the app and the widget. The app writes a `WidgetSnapshot` whenever
/// the personalised feed changes; the widget reads it on its timeline refresh.
enum SharedStore {
    private static let snapshotKey = "widget.snapshot.v1"

    static func writeSnapshot(_ snapshot: WidgetSnapshot) {
        guard let data = try? JSONEncoder.shared.encode(snapshot) else { return }
        AppGroup.defaults.set(data, forKey: snapshotKey)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    static func readSnapshot() -> WidgetSnapshot {
        guard let data = AppGroup.defaults.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder.shared.decode(WidgetSnapshot.self, from: data)
        else { return .empty }
        return snapshot
    }
}

extension JSONEncoder {
    /// Shared encoder with ISO-8601 dates so app and widget agree on format.
    static let shared: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
}

extension JSONDecoder {
    static let shared: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
