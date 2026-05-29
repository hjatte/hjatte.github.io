import Foundation

/// AdMob configuration. While testing (TestFlight), we serve Google's official
/// *test* native ads so you never click your own live ads (which can get an
/// account banned). Flip `useTestAds` to false for the public release.
enum AdConfig {
    /// Your AdMob app ID (also goes in Info.plist as GADApplicationIdentifier).
    static let applicationID = "ca-app-pub-5777536641877615~1641498693"

    /// Google's public test native-advanced unit.
    static let testNativeUnit = "ca-app-pub-3940256099942544/3986624511"
    /// Your real native-advanced unit.
    static let liveNativeUnit = "ca-app-pub-5777536641877615/3166333357"

    /// Keep true until the app is live on the App Store and AdMob-approved.
    static let useTestAds = true

    static var nativeUnitID: String { useTestAds ? testNativeUnit : liveNativeUnit }

    /// Insert a native ad after every N stories in the feed.
    static let adEveryN = 8
    /// Don't load more than this many ads per feed (keeps things light).
    static let maxAdsPerFeed = 6
}
