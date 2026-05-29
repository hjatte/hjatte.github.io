import SwiftUI

/// A compact publisher label: the publisher's real favicon + its name.
/// Falls back to a coloured monogram if the icon can't be loaded.
struct SourceBadge: View {
    let source: String
    var category: String? = nil
    /// The publisher's domain (e.g. "www.bbc.co.uk"), used to fetch its icon.
    var domain: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            icon
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    @ViewBuilder private var icon: some View {
        if let url = faviconURL {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFit()
                } else {
                    monogram   // loading or failed → monogram
                }
            }
            .frame(width: 18, height: 18)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 5))
        } else {
            monogram
        }
    }

    private var faviconURL: URL? {
        guard let host = domain?.replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: ""),
              !host.isEmpty else { return nil }
        return URL(string: "https://icons.duckduckgo.com/ip3/\(host).ico")
    }

    private var monogram: some View {
        Text(monogramText)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 18, height: 18)
            .background(color, in: RoundedRectangle(cornerRadius: 5))
    }

    private var label: String {
        guard let category, !category.isEmpty else { return source }
        return "\(source) · \(category.capitalized)"
    }

    private var monogramText: String {
        let letters = source.split(separator: " ").prefix(2).compactMap { $0.first }
        let text = String(letters).uppercased()
        return text.isEmpty ? "•" : text
    }

    /// Deterministic colour from the source name (stable across launches).
    private var color: Color {
        var hash: UInt64 = 5381
        for byte in source.utf8 { hash = (hash &* 33) &+ UInt64(byte) }
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.55, brightness: 0.75)
    }
}
