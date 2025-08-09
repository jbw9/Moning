//
//  RSSService.swift
//  moning
//
//  RSS feed parsing service for tech news sources
//

import Foundation

// MARK: - RSS Feed Models
struct RSSFeed {
    let title: String
    let description: String?
    let items: [RSSItem]
}

struct RSSItem {
    let title: String
    let description: String?
    let link: String
    let pubDate: Date?
    let author: String?
    let category: String?
    let content: String?
    let imageURL: String?
}

// MARK: - RSS Source Configuration
struct RSSSource {
    let name: String
    let url: String
    let category: CategoryType
    let reliability: Double
    let updateFrequency: TimeInterval // in seconds
    
    static let techSources: [RSSSource] = [
        // Tier 1 Sources (Highest Reliability)
        RSSSource(name: "Ars Technica", url: "https://feeds.arstechnica.com/arstechnica/index", category: .technology, reliability: 0.95, updateFrequency: 3600),
        RSSSource(name: "MIT Technology Review", url: "https://www.technologyreview.com/feed/", category: .artificialIntelligence, reliability: 0.95, updateFrequency: 7200),
        
        // Tier 2 Sources (High Reliability)
        RSSSource(name: "TechCrunch", url: "https://techcrunch.com/feed/", category: .startups, reliability: 0.90, updateFrequency: 1800),
        RSSSource(name: "The Verge", url: "https://www.theverge.com/rss/index.xml", category: .technology, reliability: 0.90, updateFrequency: 2400),
        RSSSource(name: "Wired", url: "https://www.wired.com/feed/rss", category: .technology, reliability: 0.90, updateFrequency: 3600),
        
        // Tier 3 Sources (Good Reliability)
        RSSSource(name: "Engadget", url: "https://www.engadget.com/rss.xml", category: .technology, reliability: 0.85, updateFrequency: 2400),
        RSSSource(name: "VentureBeat AI", url: "https://venturebeat.com/ai/feed/", category: .artificialIntelligence, reliability: 0.85, updateFrequency: 3600),
        
        // Company Blogs
        RSSSource(name: "Google AI Blog", url: "https://ai.googleblog.com/feeds/posts/default", category: .artificialIntelligence, reliability: 0.92, updateFrequency: 86400),
        RSSSource(name: "OpenAI Blog", url: "https://openai.com/blog/rss.xml", category: .artificialIntelligence, reliability: 0.95, updateFrequency: 86400)
    ]
}

// MARK: - RSS Parsing Errors
enum RSSError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case parsingError(String)
    case noData
    case invalidFeed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid RSS feed URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .parsingError(let message):
            return "RSS parsing error: \(message)"
        case .noData:
            return "No data received from RSS feed"
        case .invalidFeed:
            return "Invalid RSS feed format"
        }
    }
}

// MARK: - RSS Service
@MainActor
class RSSService: NSObject, ObservableObject {
    static let shared = RSSService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let session = URLSession.shared
    private let dateFormatter: DateFormatter
    private let altDateFormatter: DateFormatter
    private let cache = NSCache<NSString, NSData>()
    
    private override init() {
        // Primary date formatter for RSS feeds (RFC 822)
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        self.dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Alternative date formatter for ISO 8601
        self.altDateFormatter = DateFormatter()
        self.altDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        self.altDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        super.init()
        
        // Configure cache
        cache.countLimit = 50
        cache.totalCostLimit = 1024 * 1024 * 10 // 10MB
    }
    
    // MARK: - Public Methods
    
    /// Fetch articles from all RSS sources
    func fetchAllRSSArticles() async -> [Article] {
        isLoading = true
        errorMessage = nil
        
        var allArticles: [Article] = []
        
        // Fetch from all sources concurrently
        await withTaskGroup(of: [Article].self) { group in
            for source in RSSSource.techSources {
                group.addTask {
                    do {
                        return try await self.fetchRSSArticles(from: source)
                    } catch {
                        print("❌ Failed to fetch from \(source.name): \(error.localizedDescription)")
                        return []
                    }
                }
            }
            
            for await articles in group {
                allArticles.append(contentsOf: articles)
            }
        }
        
        isLoading = false
        
        // Sort by publication date and return
        return allArticles.sorted { $0.publishedAt > $1.publishedAt }
    }
    
    /// Fetch articles from a specific RSS source
    func fetchRSSArticles(from source: RSSSource) async throws -> [Article] {
        guard let url = URL(string: source.url) else {
            throw RSSError.invalidURL
        }
        
        // Check cache first
        let cacheKey = NSString(string: source.url)
        if let cachedData = cache.object(forKey: cacheKey) {
            if let feed = try? parseRSSData(cachedData as Data) {
                return convertToArticles(feed.items, source: source)
            }
        }
        
        // Fetch from network
        do {
            var request = URLRequest(url: url)
            request.setValue("Moning/1.0 (+https://moning.app)", forHTTPHeaderField: "User-Agent")
            request.timeoutInterval = 30
            
            let (data, response) = try await session.data(for: request)
            
            // Validate response
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw RSSError.networkError(URLError(.badServerResponse))
            }
            
            // Cache the data
            cache.setObject(data as NSData, forKey: cacheKey)
            
            // Parse RSS
            let feed = try parseRSSData(data)
            return convertToArticles(feed.items, source: source)
            
        } catch {
            throw RSSError.networkError(error)
        }
    }
    
    // MARK: - Private Methods
    
    private func parseRSSData(_ data: Data) throws -> RSSFeed {
        let parser = XMLParser(data: data)
        let delegate = RSSParserDelegate()
        parser.delegate = delegate
        
        guard parser.parse() else {
            throw RSSError.parsingError(parser.parserError?.localizedDescription ?? "Unknown parsing error")
        }
        
        guard let feed = delegate.feed else {
            throw RSSError.invalidFeed
        }
        
        return feed
    }
    
    private func convertToArticles(_ items: [RSSItem], source: RSSSource) -> [Article] {
        return items.compactMap { item in
            convertRSSItemToArticle(item, source: source)
        }
    }
    
    private func convertRSSItemToArticle(_ item: RSSItem, source: RSSSource) -> Article? {
        // Validate essential fields
        guard !item.title.isEmpty,
              let description = item.description,
              !description.isEmpty,
              let url = URL(string: item.link) else {
            return nil
        }
        
        // Use publication date or current date
        let publishedDate = item.pubDate ?? Date()
        
        // Create NewsSource
        let newsSource = NewsSource(
            name: source.name,
            domain: url.host?.replacingOccurrences(of: "www.", with: "") ?? "unknown",
            reliability: source.reliability,
            categories: [source.category]
        )
        
        // Generate enhanced content
        let content = item.content ?? description
        let summary = generateSummary(from: description)
        let tags = extractTags(from: item.title + " " + description)
        let priority = determinePriority(title: item.title, description: description)
        let readingTime = estimateReadingTime(content: content)
        let sentiment = analyzeSentiment(text: item.title + " " + description)
        
        return Article(
            title: item.title.trimmingCharacters(in: .whitespacesAndNewlines),
            summary: summary,
            content: content,
            source: newsSource,
            category: determineCategory(item: item, defaultCategory: source.category),
            publishedAt: publishedDate,
            imageURL: item.imageURL,
            sourceURL: item.link,
            tags: tags,
            priority: priority,
            readingTimeMinutes: readingTime,
            sentiment: sentiment
        )
    }
    
    private func determineCategory(item: RSSItem, defaultCategory: CategoryType) -> CategoryType {
        let text = (item.title + " " + (item.description ?? "")).lowercased()
        
        // AI/ML keywords
        if text.contains("artificial intelligence") || text.contains(" ai ") || 
           text.contains("machine learning") || text.contains("neural network") ||
           text.contains("openai") || text.contains("chatgpt") || text.contains("llm") {
            return .artificialIntelligence
        }
        
        // Blockchain/Crypto keywords
        if text.contains("blockchain") || text.contains("cryptocurrency") ||
           text.contains("bitcoin") || text.contains("ethereum") || text.contains("web3") {
            return .blockchain
        }
        
        // Cybersecurity keywords
        if text.contains("security") || text.contains("breach") || 
           text.contains("hack") || text.contains("vulnerability") {
            return .cybersecurity
        }
        
        // Startup/Business keywords
        if text.contains("startup") || text.contains("funding") || 
           text.contains("venture capital") || text.contains("ipo") {
            return .startups
        }
        
        // Mobile keywords
        if text.contains("iphone") || text.contains("android") || 
           text.contains("mobile app") || text.contains("ios ") {
            return .mobile
        }
        
        // Cloud keywords  
        if text.contains("cloud") || text.contains("aws ") ||
           text.contains("azure") || text.contains("google cloud") {
            return .cloud
        }
        
        // IoT keywords
        if text.contains("iot") || text.contains("internet of things") ||
           text.contains("smart home") || text.contains("connected device") {
            return .iot
        }
        
        return defaultCategory
    }
    
    // MARK: - Content Processing Helpers
    
    private func generateSummary(from description: String) -> String {
        let maxLength = 150
        let cleanDescription = description.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        if cleanDescription.count <= maxLength {
            return cleanDescription
        }
        
        let truncated = String(cleanDescription.prefix(maxLength))
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpace]) + "..."
        }
        
        return truncated + "..."
    }
    
    private func extractTags(from text: String) -> [String] {
        let keywords = [
            "AI", "artificial intelligence", "machine learning", "blockchain",
            "cryptocurrency", "startup", "funding", "IPO", "acquisition",
            "cybersecurity", "data breach", "privacy", "IoT", "cloud",
            "mobile", "app", "software", "hardware", "innovation",
            "ChatGPT", "OpenAI", "Meta", "Google", "Apple", "Microsoft"
        ]
        
        let lowercaseText = text.lowercased()
        return keywords.filter { lowercaseText.contains($0.lowercased()) }
    }
    
    private func determinePriority(title: String, description: String) -> ArticlePriority {
        let text = (title + " " + description).lowercased()
        
        // Breaking news indicators
        let breakingIndicators = ["breaking", "urgent", "alert", "major breach", "emergency"]
        if breakingIndicators.contains(where: { text.contains($0) }) {
            return .breaking
        }
        
        // High priority indicators
        let highPriorityIndicators = ["acquisition", "IPO", "funding", "lawsuit", "scandal", "launch", "announcement"]
        if highPriorityIndicators.contains(where: { text.contains($0) }) {
            return .high
        }
        
        return .normal
    }
    
    private func estimateReadingTime(content: String) -> Int {
        let cleanContent = content.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        let wordCount = cleanContent.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let wordsPerMinute = 200
        return max(1, wordCount / wordsPerMinute)
    }
    
    private func analyzeSentiment(text: String) -> Double {
        let positiveWords = ["success", "growth", "innovation", "breakthrough", "excellent", "great", "good", "launch", "achievement"]
        let negativeWords = ["failure", "decline", "breach", "hack", "scandal", "crisis", "problem", "issue", "concern"]
        
        let lowercaseText = text.lowercased()
        let positiveCount = positiveWords.reduce(0) { count, word in
            count + lowercaseText.components(separatedBy: word).count - 1
        }
        let negativeCount = negativeWords.reduce(0) { count, word in
            count + lowercaseText.components(separatedBy: word).count - 1
        }
        
        let totalWords = positiveCount + negativeCount
        if totalWords == 0 { return 0.0 }
        
        return Double(positiveCount - negativeCount) / Double(totalWords)
    }
}

// MARK: - RSS Parser Delegate
private class RSSParserDelegate: NSObject, XMLParserDelegate {
    var feed: RSSFeed?
    
    // Parsing state
    private var currentElement = ""
    private var currentItem: RSSItem?
    private var items: [RSSItem] = []
    private var feedTitle = ""
    private var feedDescription = ""
    
    // Current item properties
    private var itemTitle = ""
    private var itemDescription = ""
    private var itemLink = ""
    private var itemPubDate = ""
    private var itemAuthor = ""
    private var itemCategory = ""
    private var itemContent = ""
    private var itemImageURL = ""
    
    private let dateFormatter: DateFormatter
    private let altDateFormatter: DateFormatter
    
    override init() {
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        self.dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        self.altDateFormatter = DateFormatter()
        self.altDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        self.altDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        super.init()
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        if elementName == "item" {
            // Start new item
            itemTitle = ""
            itemDescription = ""
            itemLink = ""
            itemPubDate = ""
            itemAuthor = ""
            itemCategory = ""
            itemContent = ""
            itemImageURL = ""
        } else if elementName == "enclosure" {
            // Handle media enclosures (images)
            if let url = attributeDict["url"], let type = attributeDict["type"], type.hasPrefix("image/") {
                itemImageURL = url
            }
        } else if elementName == "media:thumbnail" || elementName == "media:content" {
            // Handle media RSS extensions
            if let url = attributeDict["url"] {
                itemImageURL = url
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch currentElement {
        case "title":
            if currentItem == nil {
                feedTitle += trimmedString
            } else {
                itemTitle += trimmedString
            }
        case "description":
            if currentItem == nil {
                feedDescription += trimmedString
            } else {
                itemDescription += trimmedString
            }
        case "link":
            itemLink += trimmedString
        case "pubDate", "dc:date":
            itemPubDate += trimmedString
        case "author", "dc:creator":
            itemAuthor += trimmedString
        case "category":
            itemCategory += trimmedString
        case "content:encoded":
            itemContent += trimmedString
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            // Create and add the completed item
            let pubDate = parseDate(from: itemPubDate)
            
            let item = RSSItem(
                title: itemTitle,
                description: itemDescription.isEmpty ? nil : itemDescription,
                link: itemLink,
                pubDate: pubDate,
                author: itemAuthor.isEmpty ? nil : itemAuthor,
                category: itemCategory.isEmpty ? nil : itemCategory,
                content: itemContent.isEmpty ? nil : itemContent,
                imageURL: itemImageURL.isEmpty ? nil : itemImageURL
            )
            
            items.append(item)
        }
        
        currentElement = ""
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        feed = RSSFeed(
            title: feedTitle,
            description: feedDescription.isEmpty ? nil : feedDescription,
            items: items
        )
    }
    
    private func parseDate(from string: String) -> Date? {
        if let date = dateFormatter.date(from: string) {
            return date
        }
        
        if let date = altDateFormatter.date(from: string) {
            return date
        }
        
        // Try ISO 8601 with seconds fraction
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601Formatter.date(from: string) {
            return date
        }
        
        return nil
    }
}