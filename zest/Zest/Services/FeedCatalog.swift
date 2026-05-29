import Foundation

/// The built-in catalogue of free, no-key, open RSS/Atom feeds.
///
/// All feeds are free to read and require no API key, so the app works for
/// everyone out of the box. If a feed ever goes away it's simply skipped at
/// fetch time — it never breaks the rest of the app.
enum FeedCatalog {
    static let all: [NewsSource] = bbc + guardian + others

    /// Sources grouped by category for the Settings UI.
    static var byCategory: [CategoryGroup] {
        Dictionary(grouping: all, by: \.category)
            .map { CategoryGroup(category: $0.key, sources: $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.category < $1.category }
    }

    private static func source(_ id: String, _ name: String, _ category: String, _ url: String) -> NewsSource {
        NewsSource(id: id, name: name, category: category, feedURL: URL(string: url)!)
    }

    // MARK: BBC News

    private static let bbc: [NewsSource] = [
        source("bbc-top", "BBC News", "top", "https://feeds.bbci.co.uk/news/rss.xml"),
        source("bbc-world", "BBC News", "world", "https://feeds.bbci.co.uk/news/world/rss.xml"),
        source("bbc-politics", "BBC News", "politics", "https://feeds.bbci.co.uk/news/politics/rss.xml"),
        source("bbc-business", "BBC News", "business", "https://feeds.bbci.co.uk/news/business/rss.xml"),
        source("bbc-technology", "BBC News", "technology", "https://feeds.bbci.co.uk/news/technology/rss.xml"),
        source("bbc-science", "BBC News", "science", "https://feeds.bbci.co.uk/news/science_and_environment/rss.xml"),
        source("bbc-health", "BBC News", "health", "https://feeds.bbci.co.uk/news/health/rss.xml"),
        source("bbc-sport", "BBC Sport", "sport", "https://feeds.bbci.co.uk/sport/rss.xml"),
        source("bbc-culture", "BBC News", "culture", "https://feeds.bbci.co.uk/news/entertainment_and_arts/rss.xml")
    ]

    // MARK: The Guardian (free RSS, no key)

    private static let guardian: [NewsSource] = [
        source("guardian-world", "The Guardian", "world", "https://www.theguardian.com/world/rss"),
        source("guardian-politics", "The Guardian", "politics", "https://www.theguardian.com/politics/rss"),
        source("guardian-business", "The Guardian", "business", "https://www.theguardian.com/business/rss"),
        source("guardian-technology", "The Guardian", "technology", "https://www.theguardian.com/technology/rss"),
        source("guardian-science", "The Guardian", "science", "https://www.theguardian.com/science/rss"),
        source("guardian-environment", "The Guardian", "environment", "https://www.theguardian.com/environment/rss"),
        source("guardian-sport", "The Guardian", "sport", "https://www.theguardian.com/sport/rss"),
        source("guardian-football", "The Guardian", "football", "https://www.theguardian.com/football/rss"),
        source("guardian-culture", "The Guardian", "culture", "https://www.theguardian.com/culture/rss"),
        source("guardian-lifestyle", "The Guardian", "lifestyle", "https://www.theguardian.com/lifeandstyle/rss")
    ]

    // MARK: Other free sources

    private static let others: [NewsSource] = [
        source("npr-news", "NPR", "top", "https://feeds.npr.org/1001/rss.xml"),
        source("aljazeera-all", "Al Jazeera", "world", "https://www.aljazeera.com/xml/rss/all.xml"),
        source("skynews-home", "Sky News", "top", "https://feeds.skynews.com/feeds/rss/home.xml"),
        source("skynews-politics", "Sky News", "politics", "https://feeds.skynews.com/feeds/rss/politics.xml"),
        source("skynews-tech", "Sky News", "technology", "https://feeds.skynews.com/feeds/rss/technology.xml"),
        source("verge", "The Verge", "technology", "https://www.theverge.com/rss/index.xml"),
        source("techcrunch", "TechCrunch", "technology", "https://techcrunch.com/feed/"),
        source("arstechnica", "Ars Technica", "technology", "https://feeds.arstechnica.com/arstechnica/index"),
        source("wired", "Wired", "technology", "https://www.wired.com/feed/rss"),
        source("engadget", "Engadget", "technology", "https://www.engadget.com/rss.xml"),
        source("visualcapitalist", "Visual Capitalist", "business", "https://www.visualcapitalist.com/feed/"),
        source("conversation", "The Conversation", "science", "https://theconversation.com/uk/articles.atom"),
        source("nature", "Nature", "science", "https://www.nature.com/nature.rss"),
        source("espn", "ESPN", "sport", "https://www.espn.com/espn/rss/news"),
        source("polygon", "Polygon", "games", "https://www.polygon.com/rss/index.xml")
    ]
}
