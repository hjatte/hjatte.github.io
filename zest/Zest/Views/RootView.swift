import SwiftUI

/// Top-level shell: a first-run tuning gate, then the main tabbed UI.
/// Also handles `zest://article/<id>` deep links from the widget.
struct RootView: View {
    let client: NewsAPIClient

    @EnvironmentObject private var store: InterestStore
    @StateObject private var theme = ThemeSettings.shared
    @AppStorage("hasPickedFlavour") private var hasPickedFlavour = false
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    /// A URL the widget asked us to open, surfaced once the feed is up.
    @State private var pendingURL: URL?

    var body: some View {
        Group {
            if !hasPickedFlavour {
                FlavourPickerView(isOnboarding: true) { hasPickedFlavour = true }
            } else if !hasOnboarded {
                OnboardingView(client: client, isFirstRun: true) {
                    hasOnboarded = true
                }
            } else {
                MainTabView(client: client, pendingURL: $pendingURL)
            }
        }
        .tint(theme.flavour.accent)
        .preferredColorScheme(hasPickedFlavour ? theme.flavour.colorScheme : .dark)
        .onOpenURL { url in
            // zest://article?u=<percent-encoded-web-url>
            if url.scheme == AppGroup.urlScheme,
               let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let target = comps.queryItems?.first(where: { $0.name == "u" })?.value,
               let articleURL = URL(string: target) {
                pendingURL = articleURL
            }
        }
    }
}

/// The main four-tab interface.
struct MainTabView: View {
    let client: NewsAPIClient
    @Binding var pendingURL: URL?

    var body: some View {
        TabView {
            FeedView(client: client, pendingURL: $pendingURL)
                .tabItem { Label("Feed", systemImage: "newspaper") }

            TopicsView()
                .tabItem { Label("Interests", systemImage: "heart.text.square") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
