import SwiftUI
import WebKit

/// Lets a `URL` drive `.fullScreenCover(item:)` / `.sheet(item:)`.
struct ReaderLink: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

/// In-app article reader: a full-screen web view with our own floating controls
/// — a Back button (bottom-left, returns to the feed) and a Share button
/// (bottom-right).
struct ArticleReaderView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true

    var body: some View {
        ZStack(alignment: .bottom) {
            WebView(url: url, isLoading: $isLoading)
                .ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .controlSize(.large)
            }

            HStack {
                control(systemName: "chevron.left") { dismiss() }
                Spacer()
                ShareLink(item: url) {
                    controlLabel(systemName: "square.and.arrow.up")
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 6)
        }
    }

    private func control(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { controlLabel(systemName: systemName) }
    }

    private func controlLabel(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.title3.weight(.semibold))
            .foregroundStyle(.tint)
            .frame(width: 54, height: 54)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().strokeBorder(.quaternary))
            .shadow(radius: 6, y: 3)
    }
}

/// Minimal `WKWebView` wrapper that reports its loading state.
struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebView
        init(_ parent: WebView) { self.parent = parent }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
    }
}
