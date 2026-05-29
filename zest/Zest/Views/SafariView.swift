import SwiftUI
import SafariServices

/// Lets a `URL` drive `.fullScreenCover(item:)` / `.sheet(item:)`.
struct ReaderLink: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

/// In-app reader using Apple's Safari view: opens articles in **Reader mode**
/// automatically (clean, ad-free text) when the page supports it. Has a Done
/// button (returns to the app) and Share built in, and its own top bar so the
/// status bar / clock stays readable.
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(dismiss: dismiss) }

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true            // ← automatic Reader mode
        config.barCollapsingEnabled = true

        let controller = SFSafariViewController(url: url, configuration: config)
        controller.dismissButtonStyle = .done
        controller.preferredControlTintColor = UIColor(ThemeSettings.shared.flavour.accent)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}

    final class Coordinator: NSObject, SFSafariViewControllerDelegate {
        private let dismiss: DismissAction
        init(dismiss: DismissAction) { self.dismiss = dismiss }

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            dismiss()
        }
    }
}
