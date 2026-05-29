import SwiftUI

/// A compact publisher label: a coloured monogram + the source name.
/// We use a generated monogram rather than shipping publishers' logos, which
/// avoids trademark/asset issues while still clearly attributing each story.
struct SourceBadge: View {
    let source: String
    var category: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            Text(monogram)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(color, in: RoundedRectangle(cornerRadius: 5))
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var label: String {
        guard let category, !category.isEmpty else { return source }
        return "\(source) · \(category.capitalized)"
    }

    private var monogram: String {
        let letters = source.split(separator: " ").prefix(2).compactMap { $0.first }
        let text = String(letters).uppercased()
        return text.isEmpty ? "•" : text
    }

    /// Deterministic colour from the source name, so each publisher is
    /// consistently coloured across launches (Swift's `hashValue` is
    /// randomised per process, so we roll a stable hash instead).
    private var color: Color {
        var hash: UInt64 = 5381
        for byte in source.utf8 { hash = (hash &* 33) &+ UInt64(byte) }
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.55, brightness: 0.75)
    }
}
