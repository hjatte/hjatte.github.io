import SwiftUI
import WebKit

/// Lets a `URL` drive `.fullScreenCover(item:)`.
struct ReaderLink: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

/// Owns the web view and turns the loaded page into a clean reader article
/// using Mozilla's Readability. Falls back to the plain page if extraction fails.
/// (All WebKit callbacks arrive on the main thread.)
final class ReaderModel: NSObject, ObservableObject, WKNavigationDelegate {
    let webView = WKWebView()
    @Published var isLoading = true

    private let url: URL
    private let readabilityJS: String
    /// True while we still need to extract reader content from the loaded page.
    private var pendingExtraction = false
    /// Reader light/dark, defaulting to the app flavour; toggled by the user.
    var dark: Bool = ThemeSettings.shared.flavour.dark
    private var lastExtracted: (title: String, byline: String, content: String)?

    init(url: URL) {
        self.url = url
        if let path = Bundle.main.url(forResource: "Readability", withExtension: "js"),
           let js = try? String(contentsOf: path, encoding: .utf8) {
            readabilityJS = js
        } else {
            readabilityJS = ""
        }
        super.init()
        webView.navigationDelegate = self
    }

    func showReader() { pendingExtraction = true;  isLoading = true; webView.load(URLRequest(url: url)) }
    func showWeb()    { pendingExtraction = false; isLoading = true; webView.load(URLRequest(url: url)) }

    /// Flip reader light/dark and re-render the already-extracted article.
    func toggleDark() {
        dark.toggle()
        if let a = lastExtracted {
            webView.loadHTMLString(styledHTML(title: a.title, byline: a.byline, content: a.content),
                                   baseURL: url)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard pendingExtraction, !readabilityJS.isEmpty else { isLoading = false; return }

        let js = readabilityJS + """
        ;(function(){ try {
          // Restore lazy-loaded image URLs so they survive into the reader.
          document.querySelectorAll('img').forEach(function(img){
            var ds = img.getAttribute('data-src') || img.getAttribute('data-original')
                  || img.getAttribute('data-lazy-src') || img.getAttribute('data-srcset');
            if (ds) { img.setAttribute('src', ds.split(',')[0].trim().split(' ')[0]); }
            else if (img.getAttribute('srcset')) {
              img.setAttribute('src', img.getAttribute('srcset').split(',')[0].trim().split(' ')[0]);
            }
          });
          var a = new Readability(document.cloneNode(true)).parse();
          return a ? JSON.stringify({title:a.title||'', byline:a.byline||'', content:a.content||''}) : '';
        } catch (e) { return ''; } })();
        """
        webView.evaluateJavaScript(js) { [weak self] result, _ in
            guard let self else { return }
            self.pendingExtraction = false   // the next didFinish is our clean HTML
            if let json = result as? String, let data = json.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let content = obj["content"] as? String, !content.isEmpty {
                let title = obj["title"] as? String ?? ""
                let byline = obj["byline"] as? String ?? ""
                self.lastExtracted = (title, byline, content)
                webView.loadHTMLString(self.styledHTML(title: title, byline: byline, content: content),
                                       baseURL: self.url)
            } else {
                self.isLoading = false   // extraction failed → leave the plain page
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { isLoading = false }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { isLoading = false }

    private func styledHTML(title: String, byline: String, content: String) -> String {
        let isDark = dark
        let bg = isDark ? "#121212" : "#ffffff"
        let fg = isDark ? "#f2f2f2" : "#1a1a1a"
        let muted = isDark ? "#9a9a9a" : "#6a6a6a"
        let accent = Self.hex(ThemeSettings.shared.flavour.accent)
        let bylineHTML = byline.isEmpty ? "" : "<p class='byline'>\(byline)</p>"
        return """
        <!doctype html><html><head>
        <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
        <style>
          :root { color-scheme: \(dark ? "dark" : "light"); }
          * { font-family: "Helvetica Neue", Helvetica, Arial, sans-serif !important; }
          body { margin: 0; padding: 20px max(20px, env(safe-area-inset-left)) 120px; background: \(bg); color: \(fg);
                 font-size: 18px; line-height: 1.6; -webkit-text-size-adjust: 100%; }
          h1 { font-size: 28px; line-height: 1.2; margin: 0 0 6px; font-weight: 700; }
          .byline { color: \(muted); font-size: 15px; margin: 0 0 20px; }
          img, figure, video { max-width: 100%; height: auto; border-radius: 10px; margin: 14px 0; display: block; }
          figure { margin-inline: 0; } figcaption { color: \(muted); font-size: 14px; }
          a { color: \(accent); }
          p { margin: 0 0 16px; } pre { white-space: pre-wrap; }
        </style></head><body>
          <h1>\(title)</h1>\(bylineHTML)\(content)
        </body></html>
        """
    }

    private static func hex(_ color: Color) -> String {
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r*255), Int(g*255), Int(b*255))
    }
}

/// Full-screen custom reader with our own bottom controls:
/// Done (back to the app) · Reader/Web toggle · Share.
struct ArticleReaderView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @AppStorage("readerOpenMode") private var openMode = ReaderOpenMode.reader.rawValue
    @StateObject private var model: ReaderModel
    @State private var readerMode = true

    init(url: URL) {
        self.url = url
        _model = StateObject(wrappedValue: ReaderModel(url: url))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemBackground).ignoresSafeArea()          // keeps the clock readable
            // Hide the page until the final content is ready, so we never flash
            // the raw web page before Reader mode kicks in.
            WebViewHolder(webView: model.webView)
                .ignoresSafeArea(edges: .bottom)
                .opacity(model.isLoading ? 0 : 1)
            if model.isLoading { ProgressView().controlSize(.large) }

            HStack {
                control("chevron.left") { dismiss() }
                Spacer()
                control(readerMode ? "globe" : "doc.plaintext") {
                    readerMode.toggle()
                    readerMode ? model.showReader() : model.showWeb()
                }
                Spacer()
                control("circle.lefthalf.filled") { model.toggleDark() }
                Spacer()
                ShareLink(item: url) { controlLabel("square.and.arrow.up") }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 6)
        }
        .task {
            readerMode = (openMode != ReaderOpenMode.web.rawValue)
            readerMode ? model.showReader() : model.showWeb()
        }
    }

    private func control(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { controlLabel(systemName) }
    }

    private func controlLabel(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.title3.weight(.semibold))
            .foregroundStyle(.tint)
            .frame(width: 52, height: 52)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().strokeBorder(.quaternary))
            .shadow(radius: 5, y: 3)
    }
}

/// Hosts the model's `WKWebView` in SwiftUI.
struct WebViewHolder: UIViewRepresentable {
    let webView: WKWebView
    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ webView: WKWebView, context: Context) {}
}
