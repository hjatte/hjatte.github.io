import SwiftUI
import SafariServices

/// Lightweight in-app browser for reading a full article.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}

/// Wraps a `URL` so it can drive `.sheet(item:)` without retroactively
/// conforming `URL` itself to `Identifiable`.
struct ReaderLink: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}
