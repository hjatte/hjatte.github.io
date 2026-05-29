import SwiftUI

@main
struct ZestApp: App {
    @StateObject private var store = InterestStore.shared

    /// Swap this line to use a different news provider.
    private let client: NewsAPIClient = GuardianClient()

    var body: some Scene {
        WindowGroup {
            RootView(client: client)
                .environmentObject(store)
        }
    }
}
