import SwiftUI
import GoogleMobileAds

/// A feed slot that loads and shows one native ad. Renders nothing until (and
/// unless) an ad arrives.
struct NativeAdSlot: View {
    @StateObject private var loader = NativeAdLoader()

    var body: some View {
        Group {
            if let ad = loader.ad {
                NativeAdCardView(nativeAd: ad)
                    .frame(height: 330)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            } else {
                EmptyView()
            }
        }
        .task { loader.load() }
    }
}

/// Wraps a `GADNativeAdView` laid out to look like one of our story cards.
struct NativeAdCardView: UIViewRepresentable {
    let nativeAd: GADNativeAd

    func makeUIView(context: Context) -> GADNativeAdView {
        let adView = GADNativeAdView()
        adView.backgroundColor = .secondarySystemBackground
        adView.layer.cornerRadius = 16
        adView.layer.masksToBounds = true

        // "Sponsored" attribution (required by AdMob policy).
        let sponsored = makeLabel(.caption2, .secondaryLabel)
        sponsored.text = "Sponsored"

        let headline = makeLabel(.headline, .label); headline.numberOfLines = 2
        let body = makeLabel(.subheadline, .secondaryLabel); body.numberOfLines = 2
        let advertiser = makeLabel(.caption1, .secondaryLabel)

        let icon = UIImageView()
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 32).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 32).isActive = true

        let media = GADMediaView()
        media.translatesAutoresizingMaskIntoConstraints = false
        media.heightAnchor.constraint(equalToConstant: 160).isActive = true
        media.contentMode = .scaleAspectFill
        media.clipsToBounds = true
        media.layer.cornerRadius = 10

        let cta = UIButton(type: .system)
        cta.titleLabel?.font = .preferredFont(forTextStyle: .subheadline).bold()
        cta.backgroundColor = .tintColor
        cta.setTitleColor(.white, for: .normal)
        cta.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        cta.layer.cornerRadius = 10
        cta.isUserInteractionEnabled = false   // the SDK handles taps on the ad view

        let header = UIStackView(arrangedSubviews: [icon, headline])
        header.axis = .horizontal; header.spacing = 8; header.alignment = .center

        let ctaRow = UIStackView(arrangedSubviews: [advertiser, UIView(), cta])
        ctaRow.axis = .horizontal; ctaRow.alignment = .center; ctaRow.spacing = 8

        let stack = UIStackView(arrangedSubviews: [sponsored, header, media, body, ctaRow])
        stack.axis = .vertical; stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: adView.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -14),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: adView.bottomAnchor, constant: -12)
        ])

        // Register asset views with the ad view.
        adView.headlineView = headline
        adView.bodyView = body
        adView.iconView = icon
        adView.mediaView = media
        adView.advertiserView = advertiser
        adView.callToActionView = cta

        populate(adView)
        return adView
    }

    func updateUIView(_ adView: GADNativeAdView, context: Context) {
        populate(adView)
    }

    private func populate(_ adView: GADNativeAdView) {
        (adView.headlineView as? UILabel)?.text = nativeAd.headline
        (adView.bodyView as? UILabel)?.text = nativeAd.body
        adView.bodyView?.isHidden = (nativeAd.body ?? "").isEmpty
        (adView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        adView.iconView?.isHidden = nativeAd.icon == nil
        (adView.advertiserView as? UILabel)?.text = nativeAd.advertiser
        adView.mediaView?.mediaContent = nativeAd.mediaContent
        (adView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        adView.callToActionView?.isHidden = (nativeAd.callToAction ?? "").isEmpty

        // Assign last so the SDK records the impression and wires up clicks.
        adView.nativeAd = nativeAd
    }

    private func makeLabel(_ style: UIFont.TextStyle, _ color: UIColor) -> UILabel {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: style)
        l.textColor = color
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }
}

private extension UIFont {
    func bold() -> UIFont {
        guard let d = fontDescriptor.withSymbolicTraits(.traitBold) else { return self }
        return UIFont(descriptor: d, size: 0)
    }
}
