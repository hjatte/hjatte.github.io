import Foundation

/// The built-in catalogue of free, no-key, open RSS/Atom feeds.
///
/// All feeds are free to read and require no API key, so the app works for
/// everyone out of the box. If a feed ever goes away it's simply skipped at
/// fetch time — it never breaks the rest of the app.
enum FeedCatalog {
    static let all: [NewsSource] = bbc + guardian + others + more

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

    // MARK: More sources (added on request — failing feeds are skipped at runtime)

    private static let more: [NewsSource] = [
        source("sciencenews", "Science News", "science", "https://www.sciencenews.org/feed"),
        source("appleinsider", "AppleInsider", "technology", "https://appleinsider.com/rss/news/"),
        source("bloomberg", "Bloomberg", "business", "https://feeds.bloomberg.com/markets/news.rss"),
        source("euronews", "Euronews", "world", "https://www.euronews.com/rss"),
        source("independent", "The Independent", "world", "https://www.independent.co.uk/news/world/rss"),
        source("macworld", "Macworld", "technology", "https://www.macworld.com/feed"),
        source("esquire", "Esquire", "culture", "https://www.esquire.com/rss/all.xml/"),
        source("dw", "DW News", "world", "https://rss.dw.com/rdf/rss-en-all"),
        source("techradar", "TechRadar", "technology", "https://www.techradar.com/rss"),
        source("wsj", "Wall Street Journal", "business", "https://feeds.a.dj.com/rss/WSJcomUSBusiness.xml"),
        source("toi", "Times of India", "world", "https://timesofindia.indiatimes.com/rssfeedstopstories.cms"),
        source("physorg", "Phys.org", "science", "https://phys.org/rss-feed/"),
        source("spacedaily", "Space Daily", "science", "https://www.spacedaily.com/spacedaily.xml"),
        source("fortune", "Fortune", "business", "https://fortune.com/feed/"),
        source("zdnet", "ZDNet", "technology", "https://www.zdnet.com/news/rss.xml"),
        source("tomsguide", "Tom's Guide", "technology", "https://www.tomsguide.com/feeds/all"),
        source("verywell", "Verywell Health", "health", "https://www.verywellhealth.com/feed"),
        source("economist", "The Economist", "world", "https://www.economist.com/latest/rss.xml"),
        source("vogue", "Vogue", "fashion", "https://www.vogue.com/feed/rss"),
        source("cnbc", "CNBC", "business", "https://www.cnbc.com/id/100003114/device/rss/rss.html"),
        source("time", "TIME", "world", "https://time.com/feed/"),
        source("bof", "Business of Fashion", "fashion", "https://www.businessoffashion.com/feed/"),
        source("xda", "XDA", "technology", "https://www.xda-developers.com/feed/"),
        source("scitechdaily", "SciTechDaily", "science", "https://scitechdaily.com/feed/"),
        source("politicoeu", "Politico Europe", "politics", "https://www.politico.eu/feed/"),
        source("globaltimes", "Global Times", "world", "https://www.globaltimes.cn/rss/outbrain.xml"),
        source("9to5mac", "9to5Mac", "technology", "https://9to5mac.com/feed/"),
        source("standard", "Evening Standard", "world", "https://www.standard.co.uk/news/rss"),
        source("goodhousekeeping", "Good Housekeeping", "lifestyle", "https://www.goodhousekeeping.com/rss/all.xml/"),
        source("digitaltrends", "Digital Trends", "technology", "https://www.digitaltrends.com/feed/"),
        source("investinglive", "InvestingLive", "business", "https://www.investinglive.com/feed"),
        source("elpais", "El País", "world", "https://feeds.elpais.com/mrss-s/pages/ep/site/english.elpais.com/portada"),
        source("fragrantica", "Fragrantica", "lifestyle", "https://www.fragrantica.com/rss/news.xml"),
        source("scmp", "South China Morning Post", "world", "https://www.scmp.com/rss/91/feed"),
        source("itv", "ITV News", "world", "https://www.itv.com/news/index.rss"),
        source("register", "The Register", "technology", "https://www.theregister.com/headlines.atom"),
        source("france24", "France 24", "world", "https://www.france24.com/en/rss"),
        source("abcnews", "ABC News", "world", "https://abcnews.go.com/abcnews/topstories"),
        source("nbcnews", "NBC News", "world", "https://feeds.nbcnews.com/nbcnews/public/news"),
        source("cbsnews", "CBS News", "world", "https://www.cbsnews.com/latest/rss/main"),
        source("atlantic", "The Atlantic", "culture", "https://www.theatlantic.com/feed/all/")
    ]
}
