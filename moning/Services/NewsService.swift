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
            var allArticles: [Article] = []
            
            // Fetch articles for each category
            for category in categories {
                let categoryArticles = try await fetchArticlesForCategory(category)
                allArticles.append(contentsOf: categoryArticles)
            }
            
            // Remove duplicates and sort by publication date
            articles = removeDuplicates(from: allArticles)
                .sorted { $0.publishedAt > $1.publishedAt }
            
            lastUpdateTime = Date()
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error fetching articles: \(error)")
        }
        
        isLoading = false
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
    
    /// Remove duplicate articles based on title similarity
    private func removeDuplicates(from articles: [Article]) -> [Article] {
        var seen = Set<String>()
        var uniqueArticles: [Article] = []
        
        for article in articles {
            // Create a normalized key for deduplication
            let key = article.title.lowercased()
                .replacingOccurrences(of: "[^a-z0-9\\s]", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !seen.contains(key) && key.count > 10 {
                seen.insert(key)
                uniqueArticles.append(article)
            }
        }
        
        return uniqueArticles
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