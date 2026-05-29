import SwiftUI
import GoogleMobileAds

@main
struct ZestApp: App {
    @StateObject private var store = InterestStore.shared

    /// Aggregates many free, no-key RSS sources. Swap for another
    /// `NewsAPIClient` to change providers.
    private let client: NewsAPIClient = RSSClient()

    init() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }

    var body: some Scene {
        WindowGroup {
            RootView(client: client)
                .environmentObject(store)
        }
    }
}
