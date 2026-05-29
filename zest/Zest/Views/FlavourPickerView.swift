import SwiftUI

/// "Pick your flavour" — the themed onboarding/Settings screen. Used as the
/// first launch step and again from Settings.
struct FlavourPickerView: View {
    @ObservedObject private var theme = ThemeSettings.shared
    var isOnboarding: Bool
    var onDone: () -> Void = {}

    private let columns = [GridItem(.flexible(), spacing: 14),
                           GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack(spacing: 0) {
                if isOnboarding { header.padding(.top, 24).padding(.bottom, 8) }

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(Flavour.all) { flavour in
                            card(flavour)
                        }
                    }
                    .padding()
                }

                if isOnboarding {
                    Button(action: onDone) {
                        Text("Get started")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(theme.flavour.accent, in: Capsule())
                            .foregroundStyle(theme.flavour.dark ? .black : .white)
                    }
                    .padding(.horizontal).padding(.bottom, 12)
                }
            }
        }
        .navigationTitle(isOnboarding ? "" : "Flavour")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: 6) {
            Image(systemName: "drop.halffull")
                .font(.system(size: 34))
                .foregroundStyle(theme.flavour.accent)
            Text("Pick your flavour")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.white)
            Text("You can switch any time in Settings")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private func card(_ flavour: Flavour) -> some View {
        let selected = theme.flavourID == flavour.id
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { theme.select(flavour) }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    ForEach(Array(flavour.swatches.enumerated()), id: \.offset) { _, c in
                        Circle().fill(c).frame(width: 22, height: 22)
                    }
                    Spacer()
                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(flavour.accent)
                    }
                }
                Spacer(minLength: 18)
                Text(flavour.name).font(.headline).foregroundStyle(flavour.cardText)
                Text(flavour.tagline).font(.subheadline)
                    .foregroundStyle(flavour.cardText.opacity(0.6))
            }
            .padding(16)
            .frame(height: 150, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(flavour.cardBackground, in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(flavour.accent, lineWidth: selected ? 3 : 0)
            )
        }
        .buttonStyle(.plain)
    }

    /// Classy dark gradient with a soft glow in the selected flavour's colour.
    private var background: some View {
        ZStack {
            LinearGradient(colors: [rgbBG(28,30,42), rgbBG(12,12,18)],
                           startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [theme.flavour.accent.opacity(0.35), .clear],
                           center: .top, startRadius: 0, endRadius: 460)
        }
    }

    private func rgbBG(_ r: Double, _ g: Double, _ b: Double) -> Color {
        Color(red: r/255, green: g/255, blue: b/255)
    }
}
