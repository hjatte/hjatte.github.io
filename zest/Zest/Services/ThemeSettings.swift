import SwiftUI
import Combine

private func rgb(_ r: Double, _ g: Double, _ b: Double) -> Color {
    Color(red: r/255, green: g/255, blue: b/255)
}

/// A named "flavour" — a full look (accent + light/dark + card colours), shown
/// in the "Pick your flavour" picker and applied across the app.
struct Flavour: Identifiable, Hashable {
    let id: String
    let name: String
    let tagline: String
    let accent: Color
    let dark: Bool
    let cardBackground: Color
    let swatches: [Color]

    var colorScheme: ColorScheme { dark ? .dark : .light }
    var cardText: Color { dark ? .white : .black }

    // Six light flavours.
    static let lightFlavours: [Flavour] = [
        Flavour(id: "tangerine", name: "Tangerine", tagline: "Zesty & warm",
                accent: rgb(255,128,0), dark: false, cardBackground: rgb(255,243,224),
                swatches: [rgb(255,140,40), rgb(244,107,20)]),
        Flavour(id: "bluelemon", name: "Blue Lemon", tagline: "Crisp & cool",
                accent: rgb(40,120,220), dark: false, cardBackground: rgb(251,246,233),
                swatches: [rgb(40,120,220), rgb(247,206,70)]),
        Flavour(id: "rose", name: "Rose Grapefruit", tagline: "Soft & sweet",
                accent: rgb(224,84,120), dark: false, cardBackground: rgb(252,238,241),
                swatches: [rgb(224,84,120), rgb(245,160,120)]),
        Flavour(id: "mint", name: "Mint Lime", tagline: "Fresh & breezy",
                accent: rgb(34,158,108), dark: false, cardBackground: rgb(233,246,238),
                swatches: [rgb(34,158,108), rgb(170,210,90)]),
        Flavour(id: "brown", name: "Brown Bergamot", tagline: "Toasted & warm",
                accent: rgb(150,95,55), dark: false, cardBackground: rgb(237,224,206),
                swatches: [rgb(150,95,55), rgb(100,60,30)]),
        Flavour(id: "slate", name: "Slate Sudachi", tagline: "Calm & minimal",
                accent: rgb(78,128,92), dark: false, cardBackground: rgb(227,231,229),
                swatches: [rgb(90,110,120), rgb(78,140,90)])
    ]

    // Six dark flavours.
    static let darkFlavours: [Flavour] = [
        Flavour(id: "indigo", name: "Indigo Citron", tagline: "Deep & dreamy",
                accent: rgb(124,108,240), dark: true, cardBackground: rgb(20,20,42),
                swatches: [rgb(124,108,240), rgb(70,60,160)]),
        Flavour(id: "teal", name: "Teal Calamansi", tagline: "Bright & briny",
                accent: rgb(26,188,156), dark: true, cardBackground: rgb(14,31,27),
                swatches: [rgb(40,210,170), rgb(20,130,110)]),
        Flavour(id: "purple", name: "Purple Kumquat", tagline: "Rich & regal",
                accent: rgb(178,108,240), dark: true, cardBackground: rgb(30,14,42),
                swatches: [rgb(190,120,245), rgb(140,70,200)]),
        Flavour(id: "plum", name: "Plum Tangelo", tagline: "Dark & velvety",
                accent: rgb(214,93,148), dark: true, cardBackground: rgb(36,14,24),
                swatches: [rgb(214,93,148), rgb(150,50,90)]),
        Flavour(id: "crimson", name: "Crimson Blood Orange", tagline: "Bold & juicy",
                accent: rgb(232,84,60), dark: true, cardBackground: rgb(30,12,12),
                swatches: [rgb(232,84,60), rgb(150,40,30)]),
        Flavour(id: "ink", name: "Ink Oroblanco", tagline: "Bold & classic",
                accent: rgb(235,235,235), dark: true, cardBackground: rgb(10,10,10),
                swatches: [rgb(245,245,245), rgb(160,160,160)])
    ]

    static let all: [Flavour] = lightFlavours + darkFlavours
    static var fallback: Flavour { lightFlavours[0] }
    static func by(id: String) -> Flavour { all.first { $0.id == id } ?? fallback }
}

/// Stores the chosen flavour and exposes it live to the UI.
final class ThemeSettings: ObservableObject {
    static let shared = ThemeSettings()

    @Published var flavourID: String { didSet { defaults.set(flavourID, forKey: key) } }
    var flavour: Flavour { Flavour.by(id: flavourID) }

    private let defaults = UserDefaults.standard
    private let key = "theme.flavour"

    private init() {
        flavourID = defaults.string(forKey: key) ?? Flavour.fallback.id
    }

    func select(_ f: Flavour) { flavourID = f.id }
}
