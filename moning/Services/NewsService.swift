//
//  NewsService.swift
//  moning
//
//  Service layer for fetching and processing news articles
//

import Foundation
import CoreData

@MainActor
class NewsService: ObservableObject {
    static let shared = NewsService()
    
    private let apiService = APIService.shared
    private let rssService = RSSService.shared
    private let dateFormatter: DateFormatter
    
    // Published properties for UI updates
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var articles: [Article] = []
    @Published var lastUpdateTime: Date?
    
    private init() {
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        self.dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    }
    
    // MARK: - Public Methods
    
    /// Fetch latest articles for all preferred categories
    func fetchLatestArticles(categories: [CategoryType] = CategoryType.allCases) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch from both NewsAPI and RSS feeds concurrently
            async let newsAPIArticles = fetchNewsAPIArticles(categories: categories)
            async let rssArticles = rssService.fetchAllRSSArticles()
            
            let apiResults = try await newsAPIArticles
            let rssResults = await rssArticles
            
            // Combine all articles
            var allArticles: [Article] = []
            allArticles.append(contentsOf: apiResults)
            allArticles.append(contentsOf: rssResults)
            
            // Enhanced deduplication for multi-source content
            articles = enhancedDeduplication(from: allArticles)
                .sorted { $0.publishedAt > $1.publishedAt }
            
            lastUpdateTime = Date()
            
            print("✅ Fetched \(apiResults.count) NewsAPI + \(rssResults.count) RSS = \(allArticles.count) total, \(articles.count) after deduplication")
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error fetching articles: \(error)")
        }
        
        isLoading = false
    }
    
    /// Fetch articles from NewsAPI only (helper method)
    private func fetchNewsAPIArticles(categories: [CategoryType]) async throws -> [Article] {
        var allArticles: [Article] = []
        
        // Fetch articles for each category
        for category in categories {
            let categoryArticles = try await fetchArticlesForCategory(category)
            allArticles.append(contentsOf: categoryArticles)
        }
        
        return allArticles
    }
    
    /// Fetch articles for a specific category
    func fetchArticlesForCategory(_ category: CategoryType) async throws -> [Article] {
        // Try both top headlines and search to get comprehensive results
        async let headlines = fetchTopHeadlinesForCategory(category)
        async let searchResults = fetchSearchResultsForCategory(category)
        
        let headlinesArray = try await headlines
        let searchResultsArray = try await searchResults
        
        let combined = headlinesArray + searchResultsArray
        return removeDuplicates(from: combined)
    }
    
    /// Search for articles with a specific query
    func searchArticles(query: String) async throws -> [Article] {
        let apiArticles = try await apiService.searchArticles(query: query, pageSize: 50)
        return apiArticles.compactMap { convertToAppArticle($0, category: .technology) }
    }
    
    /// Fetch articles from specific tech sources
    func fetchFromTechSources() async throws -> [Article] {
        let techSources = [
            "techcrunch", "the-verge", "engadget", "ars-technica", 
            "hacker-news", "wired", "recode", "tech-radar"
        ]
        
        let apiArticles = try await apiService.fetchFromSources(sources: techSources, pageSize: 50)
        return apiArticles.compactMap { convertToAppArticle($0, category: .technology) }
    }
    
    // MARK: - Private Methods
    
    private func fetchTopHeadlinesForCategory(_ category: CategoryType) async throws -> [Article] {
        let newsAPICategory = apiService.mapCategoryToNewsAPI(category)
        let apiArticles = try await apiService.fetchTopHeadlines(category: newsAPICategory, pageSize: 30)
        return apiArticles.compactMap { convertToAppArticle($0, category: category) }
    }
    
    private func fetchSearchResultsForCategory(_ category: CategoryType) async throws -> [Article] {
        let searchQuery = apiService.getSearchQuery(for: category)
        let apiArticles = try await apiService.searchArticles(query: searchQuery, pageSize: 20)
        return apiArticles.compactMap { convertToAppArticle($0, category: category) }
    }
    
    /// Convert NewsAPI article to our app's Article model
    private func convertToAppArticle(_ apiArticle: NewsAPIArticle, category: CategoryType) -> Article? {
        // Validate essential fields
        guard !apiArticle.title.isEmpty,
              let description = apiArticle.description,
              !description.isEmpty else {
            return nil
        }
        
        // Parse publication date
        guard let publishedDate = dateFormatter.date(from: apiArticle.publishedAt) else {
            return nil
        }
        
        // Create news source
        let source = NewsSource(
            name: apiArticle.source.name,
            domain: extractDomain(from: apiArticle.url),
            reliability: calculateSourceReliability(apiArticle.source.name),
            categories: [category]
        )
        
        // Generate content summary and tags
        let summary = generateSummary(from: description)
        let tags = extractTags(from: apiArticle.title + " " + description)
        let priority = determinePriority(title: apiArticle.title, description: description)
        let readingTime = estimateReadingTime(content: apiArticle.content ?? description)
        let sentiment = analyzeSentiment(text: apiArticle.title + " " + description)
        
        return Article(
            title: apiArticle.title,
            summary: summary,
            content: apiArticle.content ?? description,
            source: source,
            category: category,
            publishedAt: publishedDate,
            imageURL: apiArticle.urlToImage,
            sourceURL: apiArticle.url,
            tags: tags,
            priority: priority,
            readingTimeMinutes: readingTime,
            sentiment: sentiment
        )
    }
    
    /// Enhanced deduplication for multi-source content
    private func enhancedDeduplication(from articles: [Article]) -> [Article] {
        var uniqueArticles: [Article] = []
        var seenTitles = Set<String>()
        var seenUrls = Set<String>()
        var titleGroups: [String: [Article]] = [:]
        
        // First pass: Group by normalized title
        for article in articles {
            let normalizedTitle = normalizeTitle(article.title)
            
            if normalizedTitle.count > 10 {
                if titleGroups[normalizedTitle] == nil {
                    titleGroups[normalizedTitle] = []
                }
                titleGroups[normalizedTitle]?.append(article)
            }
        }
        
        // Second pass: Select best article from each group
        for (normalizedTitle, articleGroup) in titleGroups {
            guard !seenTitles.contains(normalizedTitle) else { continue }
            
            // Find the best article in this group
            let bestArticle = selectBestArticle(from: articleGroup)
            
            // Check for URL duplicates
            let canonicalURL = canonicalizeURL(bestArticle.sourceURL ?? "")
            if !seenUrls.contains(canonicalURL) {
                uniqueArticles.append(bestArticle)
                seenTitles.insert(normalizedTitle)
                seenUrls.insert(canonicalURL)
            }
        }
        
        // Third pass: Fuzzy deduplication for remaining potential duplicates
        return fuzzyDeduplication(from: uniqueArticles)
    }
    
    /// Remove duplicate articles based on title similarity (fallback method)
    private func removeDuplicates(from articles: [Article]) -> [Article] {
        return enhancedDeduplication(from: articles)
    }
    
    private func normalizeTitle(_ title: String) -> String {
        return title.lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func canonicalizeURL(_ url: String) -> String {
        guard let urlObj = URL(string: url) else { return url }
        
        // Remove tracking parameters and fragments
        var components = URLComponents(url: urlObj, resolvingAgainstBaseURL: false)
        components?.fragment = nil
        
        // Remove common tracking parameters
        let trackingParams = ["utm_source", "utm_medium", "utm_campaign", "utm_content", "utm_term", "fbclid", "gclid"]
        if let queryItems = components?.queryItems {
            components?.queryItems = queryItems.filter { item in
                !trackingParams.contains(item.name)
            }
        }
        
        // Normalize domain (remove www)
        if let host = components?.host {
            components?.host = host.replacingOccurrences(of: "www.", with: "")
        }
        
        return components?.url?.absoluteString ?? url
    }
    
    private func selectBestArticle(from articles: [Article]) -> Article {
        // Priority scoring: reliability * recency * content quality
        return articles.max { a, b in
            let scoreA = calculateArticleScore(a)
            let scoreB = calculateArticleScore(b)
            return scoreA < scoreB
        } ?? articles.first!
    }
    
    private func calculateArticleScore(_ article: Article) -> Double {
        let reliabilityScore = article.source.reliability
        let recencyScore = max(0.1, 1.0 - (Date().timeIntervalSince(article.publishedAt) / (24 * 3600))) // Decay over 24 hours
        let contentQualityScore = Double(article.content.count) / 1000.0 // Prefer longer content
        let priorityScore = article.priority == .breaking ? 2.0 : (article.priority == .high ? 1.5 : 1.0)
        
        return reliabilityScore * recencyScore * min(contentQualityScore, 2.0) * priorityScore
    }
    
    private func fuzzyDeduplication(from articles: [Article]) -> [Article] {
        var result: [Article] = []
        
        for article in articles {
            let isDuplicate = result.contains { existingArticle in
                return calculateTitleSimilarity(article.title, existingArticle.title) > 0.85
            }
            
            if !isDuplicate {
                result.append(article)
            }
        }
        
        return result
    }
    
    private func calculateTitleSimilarity(_ title1: String, _ title2: String) -> Double {
        let words1 = Set(normalizeTitle(title1).components(separatedBy: " ").filter { !$0.isEmpty })
        let words2 = Set(normalizeTitle(title2).components(separatedBy: " ").filter { !$0.isEmpty })
        
        let intersection = words1.intersection(words2).count
        let union = words1.union(words2).count
        
        return union > 0 ? Double(intersection) / Double(union) : 0.0
    }
    
    // MARK: - Helper Methods
    
    private func extractDomain(from url: String) -> String {
        if let urlObj = URL(string: url),
           let host = urlObj.host {
            return host.replacingOccurrences(of: "www.", with: "")
        }
        return "unknown"
    }
    
    private func calculateSourceReliability(_ sourceName: String) -> Double {
        // Simple reliability scoring based on known sources
        let reliableSources = [
            "TechCrunch": 0.9, "The Verge": 0.9, "Ars Technica": 0.95,
            "Wired": 0.9, "Engadget": 0.85, "Reuters": 0.95,
            "Associated Press": 0.95, "BBC News": 0.9
        ]
        
        return reliableSources[sourceName] ?? 0.7
    }
    
    private func generateSummary(from description: String) -> String {
        // For now, use the first 150 characters as summary
        // In a full implementation, this would use AI summarization
        let maxLength = 150
        if description.count <= maxLength {
            return description
        }
        
        let truncated = String(description.prefix(maxLength))
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
            "mobile", "app", "software", "hardware", "tech", "innovation"
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
        let highPriorityIndicators = ["acquisition", "IPO", "funding", "lawsuit", "scandal"]
        if highPriorityIndicators.contains(where: { text.contains($0) }) {
            return .high
        }
        
        return .normal
    }
    
    private func estimateReadingTime(content: String) -> Int {
        let wordCount = content.components(separatedBy: .whitespacesAndNewlines).count
        let wordsPerMinute = 200
        return max(1, wordCount / wordsPerMinute)
    }
    
    private func analyzeSentiment(text: String) -> Double {
        // Simple sentiment analysis - in production would use ML model
        let positiveWords = ["success", "growth", "innovation", "breakthrough", "excellent", "great", "good"]
        let negativeWords = ["failure", "decline", "breach", "hack", "scandal", "crisis", "problem"]
        
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