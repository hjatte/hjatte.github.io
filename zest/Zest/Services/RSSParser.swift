import Foundation

/// A minimal RSS 2.0 + Atom parser built on Foundation's `XMLParser`.
/// Extracts the fields the app needs and tolerates the quirks of real feeds.
final class RSSParser: NSObject, XMLParserDelegate {

    /// One parsed entry before it's turned into an `Article`.
    struct RawItem {
        var title = ""
        var link = ""
        var summary = ""
        var published: Date?
        var guid = ""
        var imageURL: String?
        var imageWidth = 0
        var categories: [String] = []
    }

    private var items: [RawItem] = []
    private var current: RawItem?
    private var currentElement = ""
    private var buffer = ""
    /// Whether we're inside the Atom `<author>` block (so we ignore its name).
    private var insideAuthor = false

    /// Parses feed data into raw items. Returns [] on any failure.
    static func parse(_ data: Data) -> [RawItem] {
        let parser = RSSParser()
        let xml = XMLParser(data: data)
        xml.delegate = parser
        xml.shouldProcessNamespaces = false
        guard xml.parse() else { return parser.items }
        return parser.items
    }

    // MARK: XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String: String]) {
        currentElement = elementName
        buffer = ""

        switch elementName {
        case "item", "entry":
            current = RawItem()
        case "author":
            insideAuthor = true
        case "link":
            // Atom links carry the URL in an attribute, not text content.
            if let href = attributeDict["href"], current != nil {
                let rel = attributeDict["rel"] ?? "alternate"
                if rel == "alternate" { current?.link = href }
            }
        case "media:thumbnail", "media:content", "enclosure":
            if let url = attributeDict["url"], current != nil {
                let type = attributeDict["type"] ?? ""
                guard type.isEmpty || type.hasPrefix("image") else { break }
                let width = Int(attributeDict["width"] ?? "") ?? 0
                // Keep the biggest image the feed offers (sharper on the card).
                if current!.imageURL == nil || width > current!.imageWidth {
                    current!.imageURL = url
                    current!.imageWidth = width
                }
            }
        case "category":
            // Atom puts the value in `term`; RSS uses text content (handled below).
            if let term = attributeDict["term"], current != nil {
                current?.categories.append(term)
            }
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        buffer += string
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        if let s = String(data: CDATABlock, encoding: .utf8) { buffer += s }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        let text = buffer.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {
        case "item", "entry":
            if let item = current { items.append(item) }
            current = nil
        case "author":
            insideAuthor = false
        case "title" where !insideAuthor:
            current?.title = text
        case "link":
            if current?.link.isEmpty ?? false, !text.isEmpty { current?.link = text }
        case "description", "summary", "content":
            if current?.summary.isEmpty ?? false { current?.summary = text }
        case "guid", "id":
            if current?.guid.isEmpty ?? false { current?.guid = text }
        case "pubDate", "published", "updated", "dc:date":
            if current?.published == nil { current?.published = DateParsing.parse(text) }
        case "category":
            if !text.isEmpty { current?.categories.append(text) }
        default:
            break
        }
        buffer = ""
    }
}

/// Parses the date formats that show up across RSS (RFC 822) and Atom (ISO 8601).
///
/// Formatters are created locally per call because `DateFormatter` /
/// `ISO8601DateFormatter` are not thread-safe and feeds are parsed concurrently.
enum DateParsing {
    private static let rfc822Formats = [
        "EEE, dd MMM yyyy HH:mm:ss Z",
        "EEE, dd MMM yyyy HH:mm:ss zzz",
        "dd MMM yyyy HH:mm:ss Z"
    ]

    static func parse(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let d = ISO8601DateFormatter().date(from: trimmed) { return d }

        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        for format in rfc822Formats {
            f.dateFormat = format
            if let d = f.date(from: trimmed) { return d }
        }
        return nil
    }
}
