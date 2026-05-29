import SwiftUI

@main
struct ZestApp: App {
    @StateObject private var store = InterestStore.shared

    /// Aggregates many free, no-key RSS sources. Swap for another
    /// `NewsAPIClient` to change providers.
    private let client: NewsAPIClient = RSSClient()

    var body: some Scene {
        WindowGroup {
            RootView(client: client)
                .environmentObject(store)
        }
    }
}
