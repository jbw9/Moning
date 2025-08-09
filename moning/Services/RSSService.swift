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
        // Tier 1 Sources (Highest Reliability) - Verified URLs
        RSSSource(name: "Ars Technica", url: "https://feeds.arstechnica.com/arstechnica/index", category: .technology, reliability: 0.95, updateFrequency: 3600),
        RSSSource(name: "MIT Technology Review", url: "https://www.technologyreview.com/feed/", category: .artificialIntelligence, reliability: 0.95, updateFrequency: 7200),
        
        // Tier 2 Sources (High Reliability) - Verified URLs
        RSSSource(name: "TechCrunch", url: "https://techcrunch.com/feed/", category: .startups, reliability: 0.90, updateFrequency: 1800),
        RSSSource(name: "The Verge", url: "https://www.theverge.com/rss/index.xml", category: .technology, reliability: 0.90, updateFrequency: 2400),
        RSSSource(name: "Wired", url: "https://www.wired.com/feed/rss", category: .technology, reliability: 0.90, updateFrequency: 3600),
        
        // Tier 3 Sources (Good Reliability) - Verified URLs
        RSSSource(name: "Engadget", url: "https://www.engadget.com/rss.xml", category: .technology, reliability: 0.85, updateFrequency: 2400),
        RSSSource(name: "VentureBeat", url: "https://venturebeat.com/feed/", category: .technology, reliability: 0.85, updateFrequency: 3600),
        
        // Additional Verified Sources
        RSSSource(name: "9to5Mac", url: "https://9to5mac.com/feed/", category: .mobile, reliability: 0.80, updateFrequency: 3600),
        RSSSource(name: "TechRadar", url: "https://www.techradar.com/rss", category: .technology, reliability: 0.80, updateFrequency: 3600)
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
        
        print("🚀 Starting RSS fetch from \(RSSSource.techSources.count) sources")
        
        var allArticles: [Article] = []
        
        // Fetch from all sources concurrently
        await withTaskGroup(of: [Article].self) { group in
            for source in RSSSource.techSources {
                group.addTask {
                    print("📡 Fetching from \(source.name)...")
                    do {
                        let articles = try await self.fetchRSSArticles(from: source)
                        print("✅ \(source.name): \(articles.count) articles")
                        return articles
                    } catch {
                        print("❌ Failed to fetch from \(source.name): \(error.localizedDescription)")
                        return []
                    }
                }
            }
            
            for await articles in group {
                allArticles.append(contentsOf: articles)
                print("📈 Total articles so far: \(allArticles.count)")
            }
        }
        
        isLoading = false
        
        print("📊 RSS Fetch Complete: \(allArticles.count) total articles from all sources")
        
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
            // Use a standard browser User-Agent to avoid blocking
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
            request.setValue("application/rss+xml, application/xml, text/xml, */*", forHTTPHeaderField: "Accept")
            request.setValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
            request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
            request.timeoutInterval = 30
            
            let (data, response) = try await session.data(for: request)
            
            // Validate response with detailed error handling
            guard let httpResponse = response as? HTTPURLResponse else {
                throw RSSError.networkError(URLError(.badServerResponse))
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = "HTTP \(httpResponse.statusCode) for \(source.name): \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))"
                print("❌ RSS Error: \(errorMessage)")
                
                // Log response content for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Response content preview: \(String(responseString.prefix(200)))")
                }
                
                throw RSSError.networkError(URLError(.badServerResponse))
            }
            
            // Cache the data
            cache.setObject(data as NSData, forKey: cacheKey)
            
            // Debug: Log content type and size
            let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "unknown"
            print("✅ RSS Fetch Success: \(source.name) - \(data.count) bytes, Content-Type: \(contentType)")
            
            // Parse RSS with better error handling
            do {
                let feed = try parseRSSData(data)
                let articles = convertToArticles(feed.items, source: source)
                print("✅ RSS Parse Success: \(source.name) - \(articles.count) articles")
                return articles
            } catch {
                // Log parsing error details
                print("❌ RSS Parse Error for \(source.name): \(error)")
                if let dataString = String(data: data, encoding: .utf8) {
                    print("📄 XML Content Preview: \(String(dataString.prefix(500)))")
                }
                throw RSSError.parsingError("Failed to parse RSS from \(source.name): \(error.localizedDescription)")
            }
            
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
        // Debug the conversion process
        print("🔄 Converting RSS item to Article:")
        print("   Source: \(source.name)")
        print("   Title: '\(item.title)' (empty: \(item.title.isEmpty))")
        print("   Description: '\(item.description?.prefix(50) ?? "nil")...'")
        print("   Link: '\(item.link)' (valid URL: \(URL(string: item.link) != nil))")
        
        // Validate essential fields with more lenient validation
        guard !item.title.isEmpty else {
            print("❌ Dropped: Empty title")
            return nil
        }
        
        guard !item.link.isEmpty, URL(string: item.link) != nil else {
            print("❌ Dropped: Invalid link")
            return nil
        }
        
        // Use link as description fallback if description is missing
        let description = item.description ?? item.title
        if description.isEmpty {
            print("❌ Dropped: No description")
            return nil
        }
        
        // Use publication date or current date
        let publishedDate = item.pubDate ?? Date()
        
        // Create NewsSource
        let domain = URL(string: item.link)?.host?.replacingOccurrences(of: "www.", with: "") ?? "unknown"
        let newsSource = NewsSource(
            name: source.name,
            domain: domain,
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
        
        let article = Article(
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
        
        print("✅ Successfully converted RSS item to Article: '\(article.title.prefix(50))...'")
        return article
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
    private var insideItem = false // Track if we're inside an item/entry element
    
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
        
        // Handle both RSS and Atom formats
        if elementName == "item" || elementName == "entry" {
            // Start new item (RSS uses "item", Atom uses "entry")
            insideItem = true
            itemTitle = ""
            itemDescription = ""
            itemLink = ""
            itemPubDate = ""
            itemAuthor = ""
            itemCategory = ""
            itemContent = ""
            itemImageURL = ""
            print("📖 Starting new RSS item/entry")
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
        } else if elementName == "link" {
            // Handle Atom link elements
            if let href = attributeDict["href"], let rel = attributeDict["rel"], rel == "alternate" {
                itemLink = href
            } else if let href = attributeDict["href"], attributeDict["rel"] == nil {
                // Default link
                itemLink = href
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch currentElement {
        case "title":
            if insideItem {
                itemTitle += trimmedString
            } else {
                feedTitle += trimmedString
            }
        case "description", "summary":
            // Atom uses "summary", RSS uses "description"
            if insideItem {
                itemDescription += trimmedString
            } else {
                feedDescription += trimmedString
            }
        case "link":
            // Only capture text content for RSS links (Atom uses attributes)
            if insideItem {
                itemLink += trimmedString
            }
        case "pubDate", "dc:date", "published", "updated":
            // Handle different date formats (RSS: pubDate, Atom: published/updated)
            if insideItem {
                itemPubDate += trimmedString
            }
        case "author", "dc:creator", "name":
            // Atom author is often in <author><name>...</name></author>
            if insideItem {
                itemAuthor += trimmedString
            }
        case "category":
            if insideItem {
                itemCategory += trimmedString
            }
        case "content:encoded", "content":
            // Handle both RSS content:encoded and Atom content
            if insideItem {
                itemContent += trimmedString
            }
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" || elementName == "entry" {
            // Create and add the completed item
            insideItem = false
            let pubDate = parseDate(from: itemPubDate)
            
            print("📝 Completed RSS item:")
            print("   Title: '\(itemTitle)'")
            print("   Description: '\(itemDescription.prefix(100))...'")
            print("   Link: '\(itemLink)'")
            print("   PubDate: '\(itemPubDate)' → \(pubDate?.description ?? "nil")")
            
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
            print("✅ Added item #\(items.count) to RSS feed")
        }
        
        currentElement = ""
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        print("📄 XML Parsing Complete:")
        print("   Feed Title: '\(feedTitle)'")
        print("   Feed Description: '\(feedDescription.prefix(100))...'")
        print("   Total Items Parsed: \(items.count)")
        
        feed = RSSFeed(
            title: feedTitle,
            description: feedDescription.isEmpty ? nil : feedDescription,
            items: items
        )
        
        print("✅ RSSFeed object created with \(feed?.items.count ?? 0) items")
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