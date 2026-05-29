import Foundation
import GoogleMobileAds

/// Loads a single native ad for one feed slot and publishes it to SwiftUI.
final class NativeAdLoader: NSObject, ObservableObject, GADNativeAdLoaderDelegate {
    @Published var ad: GADNativeAd?

    private var adLoader: GADAdLoader?

    /// Loads once; repeated calls are ignored.
    func load() {
        guard ad == nil, adLoader == nil else { return }
        let loader = GADAdLoader(adUnitID: AdConfig.nativeUnitID,
                                 rootViewController: nil,
                                 adTypes: [.native],
                                 options: nil)
        loader.delegate = self
        adLoader = loader
        loader.load(GADRequest())
    }

    // MARK: GADNativeAdLoaderDelegate

    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        self.ad = nativeAd
    }

    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        // Leave `ad` nil — the slot simply renders nothing.
        self.adLoader = nil
    }
}
