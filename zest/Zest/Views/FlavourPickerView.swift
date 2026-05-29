import SwiftUI

/// "Pick your flavour" — themed onboarding/Settings screen with clearly
/// separated Light and Dark sets (six each), sized to fit without scrolling.
struct FlavourPickerView: View {
    @ObservedObject private var theme = ThemeSettings.shared
    var isOnboarding: Bool
    var onDone: () -> Void = {}

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack(spacing: 16) {
                if isOnboarding { header.padding(.top, 12) }

                section("☀︎  Light", Flavour.lightFlavours)
                section("☾  Dark", Flavour.darkFlavours)

                Spacer(minLength: 0)

                if isOnboarding {
                    Button(action: onDone) {
                        Text("Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity).padding(.vertical, 15)
                            .background(theme.flavour.accent, in: Capsule())
                            .foregroundStyle(theme.flavour.dark ? .black : .white)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 12)
        }
        .navigationTitle(isOnboarding ? "" : "Flavour")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("Pick your flavour").font(.title.weight(.bold)).foregroundStyle(.white)
            Text("You can change it any time in Settings")
                .font(.footnote).foregroundStyle(.white.opacity(0.6))
        }
    }

    private func section(_ title: String, _ flavours: [Flavour]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.85))
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(flavours) { tile($0) }
            }
        }
    }

    private func tile(_ flavour: Flavour) -> some View {
        let selected = theme.flavourID == flavour.id
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { theme.select(flavour) }
        } label: {
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    ForEach(Array(flavour.swatches.enumerated()), id: \.offset) { _, c in
                        Circle().fill(c).frame(width: 13, height: 13)
                    }
                }
                Text(flavour.name)
                    .font(.caption2).foregroundStyle(flavour.cardText)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity).frame(height: 60)
            .background(flavour.cardBackground, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(selected ? flavour.accent : .clear, lineWidth: 3)
            )
            .overlay(alignment: .topTrailing) {
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2).foregroundStyle(flavour.accent)
                        .padding(4)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var background: some View {
        ZStack {
            LinearGradient(colors: [rgbBG(28,30,42), rgbBG(12,12,18)],
                           startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [theme.flavour.accent.opacity(0.30), .clear],
                           center: .top, startRadius: 0, endRadius: 420)
        }
    }

    private func rgbBG(_ r: Double, _ g: Double, _ b: Double) -> Color {
        Color(red: r/255, green: g/255, blue: b/255)
    }
}
