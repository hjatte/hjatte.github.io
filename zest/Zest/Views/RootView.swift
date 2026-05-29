import SwiftUI

/// Top-level shell: a first-run tuning gate, then the main tabbed UI.
/// Also handles `zest://article/<id>` deep links from the widget.
struct RootView: View {
    let client: NewsAPIClient

    @EnvironmentObject private var store: InterestStore
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    /// A URL the widget asked us to open, surfaced once the feed is up.
    @State private var pendingURL: URL?

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView(client: client, pendingURL: $pendingURL)
            } else {
                OnboardingView(client: client, isFirstRun: true) {
                    hasOnboarded = true
                }
            }
        }
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
                .tabItem { Label("Topics", systemImage: "pin") }

            OnboardingView(client: client, isFirstRun: false, onFinish: {})
                .tabItem { Label("Tune", systemImage: "slider.horizontal.3") }

            InterestsView()
                .tabItem { Label("Interests", systemImage: "chart.bar") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
