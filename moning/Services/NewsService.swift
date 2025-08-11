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

// MARK: - AI Summarization Extension

// Summarization API Models
struct SummarizationRequest: Codable {
    let article_ids: [String]
}

struct SummarizationResponse: Codable {
    let summaries: [String: SummaryData?]
    let found: Int
    let not_found: Int
    let total_requested: Int
    let model_used: String
}

struct SummaryData: Codable {
    let summary: String
    let created_at: String?
    let model_used: String?
    let metadata: [String: String]?
}

struct SingleSummaryResponse: Codable {
    let article_id: String
    let summary: String
    let created_at: String?
    let model_used: String?
    let cached: Bool
    let metadata: [String: String]?
}

enum NewsServiceError: Error {
    case invalidResponse
    case apiError(Int)
    case decodingError
    case networkError
    
    var localizedDescription: String {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let code):
            return "API error with status code: \(code)"
        case .decodingError:
            return "Failed to decode response"
        case .networkError:
            return "Network connection error"
        }
    }
}

extension NewsService {
    
    // Your deployed API endpoint
    private var summarizationAPIURL: String {
        return "https://y501z1431b.execute-api.us-west-2.amazonaws.com/prod"
    }
    
    /// Fetch summaries for multiple articles
    func fetchSummariesForArticles(_ articles: [Article]) async throws -> [String: String] {
        let articleIds = articles.map { $0.id.uuidString }
        
        guard !articleIds.isEmpty else {
            print("📝 No article IDs to fetch summaries for")
            return [:]
        }
        
        let request = SummarizationRequest(article_ids: articleIds)
        let requestData = try JSONEncoder().encode(request)
        
        var urlRequest = URLRequest(url: URL(string: "\(summarizationAPIURL)/batch-summaries")!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = requestData
        
        print("📤 Requesting summaries for \(articleIds.count) articles...")
        
        let (responseData, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NewsServiceError.invalidResponse
        }
        
        print("📥 Summarization API response: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if let errorMessage = String(data: responseData, encoding: .utf8) {
                print("❌ Summarization API error: \(errorMessage)")
            }
            throw NewsServiceError.apiError(httpResponse.statusCode)
        }
        
        let summaryResponse = try JSONDecoder().decode(SummarizationResponse.self, from: responseData)
        
        print("✅ Summaries fetched: \(summaryResponse.found)/\(summaryResponse.total_requested)")
        print("🤖 Model used: \(summaryResponse.model_used)")
        
        // Convert to simple [String: String] format
        var summaries: [String: String] = [:]
        for (articleId, summaryData) in summaryResponse.summaries {
            if let data = summaryData {
                summaries[articleId] = data.summary
            }
        }
        
        return summaries
    }
    
    /// Fetch summary for a single article
    func fetchSummaryForArticle(_ articleId: String) async throws -> String? {
        let url = URL(string: "\(summarizationAPIURL)/summaries/\(articleId)")!
        
        print("📤 Requesting summary for article: \(articleId)")
        
        let (responseData, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NewsServiceError.invalidResponse
        }
        
        print("📥 Single summary API response: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 404 {
            print("ℹ️ Summary not found for article: \(articleId)")
            return nil
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NewsServiceError.apiError(httpResponse.statusCode)
        }
        
        let summaryResponse = try JSONDecoder().decode(SingleSummaryResponse.self, from: responseData)
        
        print("✅ Summary fetched for \(articleId)")
        print("💾 Cached: \(summaryResponse.cached)")
        
        return summaryResponse.summary
    }
    
    /// Enhanced news fetching with automatic summarization
    func fetchLatestArticlesWithSummaries(categories: [CategoryType] = CategoryType.allCases) async {
        // First fetch articles as usual
        await fetchLatestArticles(categories: categories)
        
        // Then fetch summaries for the articles
        guard !articles.isEmpty else {
            print("📝 No articles to summarize")
            return
        }
        
        do {
            print("🤖 Fetching AI summaries for \(articles.count) articles...")
            let summaries = try await fetchSummariesForArticles(articles)
            
            // Update articles with summaries (this would require Core Data integration)
            print("✅ Received \(summaries.count) summaries")
            
            // Note: In actual implementation, you would save these to Core Data here
            // For now, just logging the success
            
        } catch {
            print("❌ Failed to fetch summaries: \(error.localizedDescription)")
        }
    }
}

// MARK: - Weekly Recap Generation Extension

extension NewsService {
    
    /// Generate a comprehensive weekly recap of tech industry developments
    func generateWeeklyRecap(for weekStartDate: Date? = nil) async throws -> WeeklyRecap {
        print("🚀 GENERATING ENHANCED TECH INDUSTRY WEEKLY RECAP")
        print(String(repeating: "=", count: 80))
        
        // Determine the week to analyze
        let startDate = weekStartDate ?? Date().addingTimeInterval(-7 * 24 * 60 * 60)
        let endDate = startDate.addingTimeInterval(7 * 24 * 60 * 60)
        
        print("📅 Analyzing week: \(formatDate(startDate)) to \(formatDate(endDate))")
        
        // Step 1: Fetch and analyze articles from the past week
        let analysis = try await fetchAndAnalyzeWeeklyArticles(startDate: startDate, endDate: endDate)
        
        if analysis.statistics.totalArticles < 5 {
            throw NewsServiceError.insufficientData("Found only \(analysis.statistics.totalArticles) articles - need at least 5 for meaningful recap")
        }
        
        print("📈 Analysis complete: \(analysis.statistics.totalArticles) articles from \(analysis.statistics.sourcesAnalyzed) sources")
        
        // Step 2: Try AWS Bedrock generation first
        if let aiRecap = try await generateAIWeeklyRecap(from: analysis) {
            print("✅ Successfully generated AI-powered weekly recap")
            return aiRecap
        }
        
        // Step 3: Fallback to structured recap if AI fails
        print("📝 Generating structured fallback recap")
        return createStructuredWeeklyRecap(from: analysis)
    }
    
    /// Fetch and analyze articles from the specified week
    private func fetchAndAnalyzeWeeklyArticles(startDate: Date, endDate: Date) async throws -> RecapAnalysis {
        
        // Fetch articles for all categories to get comprehensive coverage
        let categories = CategoryType.allCases
        var allArticles: [Article] = []
        
        // Fetch from both NewsAPI and RSS feeds
        print("📡 Fetching articles from multiple sources...")
        
        // Get NewsAPI articles
        let newsAPIArticles = try await fetchNewsAPIArticles(categories: categories)
        
        // Get RSS articles
        let rssArticles = await rssService.fetchAllRSSArticles()
        
        // Combine and filter for the week
        allArticles = (newsAPIArticles + rssArticles).filter { article in
            article.publishedAt >= startDate && article.publishedAt <= endDate
        }
        
        // Enhanced deduplication
        let uniqueArticles = enhancedDeduplication(from: allArticles)
            .sorted { $0.publishedAt > $1.publishedAt }
        
        print("✅ Found \(uniqueArticles.count) unique articles for the week")
        
        // Analyze trends and identify major stories
        return analyzeArticleTrends(articles: uniqueArticles, timeRange: DateInterval(start: startDate, end: endDate))
    }
    
    /// Analyze article trends similar to the Python enhanced_tech_recap logic
    private func analyzeArticleTrends(articles: [Article], timeRange: DateInterval) -> RecapAnalysis {
        
        // Key terms for enhanced categorization (matching Python logic)
        let aiTerms = ["openai", "anthropic", "google ai", "microsoft ai", "nvidia", "meta ai", "gpt", "claude", "gemini", "llm", "artificial intelligence", "machine learning", "ai model"]
        let securityTerms = ["hack", "security", "breach", "vulnerability", "cyber", "ransomware", "phishing"]
        let startupTerms = ["funding", "raises", "series", "investment", "venture", "ipo", "acquisition"]
        let bigTechTerms = ["apple", "google", "microsoft", "amazon", "meta", "tesla", "nvidia", "openai"]
        let breakthroughTerms = ["launches", "announces", "reveals", "breakthrough", "first", "revolutionary"]
        
        var trends: [CategoryType: [Article]] = [:]
        var majorStories: [Article] = []
        var categoryStats: [CategoryType: Int] = [:]
        
        var aiStoryCount = 0
        var securityStoryCount = 0
        var startupFundingCount = 0
        var bigTechMovesCount = 0
        var breakingNewsCount = 0
        
        // Analyze each article for trends and importance
        for var article in articles {
            let text = (article.title + " " + article.summary + " " + article.content).lowercased()
            
            var importance = 0.0
            var categories: [CategoryType] = []
            
            // AI/ML detection (matching Python logic)
            if aiTerms.contains(where: { text.contains($0) }) {
                trends[.artificialIntelligence, default: []].append(article)
                categories.append(.artificialIntelligence)
                importance += 2.0
                aiStoryCount += 1
            }
            
            // Security detection
            if securityTerms.contains(where: { text.contains($0) }) {
                trends[.cybersecurity, default: []].append(article)
                categories.append(.cybersecurity)
                importance += 1.5
                securityStoryCount += 1
            }
            
            // Startup/funding detection
            if startupTerms.contains(where: { text.contains($0) }) {
                trends[.startups, default: []].append(article)
                categories.append(.startups)
                importance += 1.0
                startupFundingCount += 1
            }
            
            // Big tech detection
            if bigTechTerms.contains(where: { text.contains($0) }) {
                trends[.technology, default: []].append(article)
                categories.append(.technology)
                importance += 1.5
                bigTechMovesCount += 1
            }
            
            // Breakthrough/major announcements
            if breakthroughTerms.contains(where: { text.contains($0) }) {
                importance += 1.0
            }
            
            // Breaking news priority boost
            if article.priority == .breaking {
                importance += 2.0
                breakingNewsCount += 1
            } else if article.priority == .high {
                importance += 1.0
            }
            
            // Source reliability boost
            importance += article.source.reliability
            
            // Recency boost (matching Python logic)
            let hoursOld = Date().timeIntervalSince(article.publishedAt) / 3600
            if hoursOld < 24 {
                importance += 0.3
            } else if hoursOld < 72 {
                importance += 0.1
            }
            
            // Store the calculated importance (we'll need to recreate the article)
            if importance >= 2.0 {
                majorStories.append(article)
            }
            
            // Update category stats
            for category in categories {
                categoryStats[category, default: 0] += 1
            }
            categoryStats[article.category, default: 0] += 1
        }
        
        // Sort major stories by importance and recency
        majorStories = majorStories
            .sorted { a, b in
                let scoreA = calculateArticleScore(a)
                let scoreB = calculateArticleScore(b)
                return scoreA > scoreB
            }
            .prefix(10)
            .map { $0 }
        
        let statistics = WeeklyStats(
            totalArticles: articles.count,
            sourcesAnalyzed: Set(articles.map { $0.source.name }).count,
            categoryCounts: categoryStats,
            aiStories: aiStoryCount,
            securityStories: securityStoryCount,
            startupFunding: startupFundingCount,
            bigTechMoves: bigTechMovesCount,
            breakingNews: breakingNewsCount
        )
        
        return RecapAnalysis(
            articles: articles,
            trends: trends,
            majorStories: majorStories,
            statistics: statistics,
            timeRange: timeRange
        )
    }
    
    
    /// Create sophisticated prompt for weekly recap (matching Python enhanced_tech_recap.py)
    private func createWeeklyRecapPrompt(from analysis: RecapAnalysis) -> String {
        let majorStories = analysis.majorStories.prefix(5)
        let articleContext = majorStories.map { article in
            "• \(article.title) (\(article.source.name)) - \(article.summary.prefix(200))..."
        }.joined(separator: "\n")
        
        let stats = analysis.statistics
        
        return """
        You are an expert tech industry analyst writing a Morning Brew-style weekly recap.
        
        This week's top tech stories:
        \(articleContext)
        
        Industry stats: \(stats.aiStories) AI stories, \(stats.securityStories) security stories, \(stats.bigTechMoves) big tech moves, \(stats.startupFunding) funding stories.
        
        Write an engaging 1200-word industry recap covering:
        1. Week's biggest story with detailed analysis
        2. 4-5 key industry themes with insights  
        3. What to watch next week
        4. Bottom line takeaway for business leaders
        
        Use a conversational, insightful tone like Morning Brew. Include specific company names and numbers where relevant.
        Structure with clear sections and engaging subheadings.
        Focus on "why this matters" analysis rather than just summarizing events.
        """
    }
    
    /// Parse AI response into structured WeeklyRecap (simplified parsing)
    private func parseAIRecapResponse(_ content: String, from analysis: RecapAnalysis) -> WeeklyRecap {
        // Simplified parsing - in production you might want more sophisticated parsing
        let biggestStory = analysis.majorStories.first.map { article in
            RecapStory(
                title: article.title,
                content: article.summary,
                sourceArticleId: article.id,
                sourceName: article.source.name,
                importance: calculateArticleScore(article),
                url: article.sourceURL
            )
        }
        
        // Create themes from trends
        let themes = analysis.trends.compactMap { (category, articles) -> RecapTheme? in
            guard articles.count >= 2 else { return nil }
            
            let themeStories = articles.prefix(3).map { article in
                RecapStory(
                    title: article.title,
                    content: article.summary,
                    sourceArticleId: article.id,
                    sourceName: article.source.name,
                    importance: calculateArticleScore(article),
                    url: article.sourceURL
                )
            }
            
            return RecapTheme(
                name: getThemeName(for: category),
                content: getThemeAnalysis(for: category, articles: articles),
                category: category,
                stories: Array(themeStories),
                importance: Double(articles.count)
            )
        }
        
        let weekStart = analysis.timeRange.start
        let weekEnd = analysis.timeRange.end
        
        return WeeklyRecap(
            title: "Tech Weekly: Industry Pulse",
            subtitle: "Week of \(formatDate(weekEnd))",
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            summary: content,
            biggestStory: biggestStory,
            themes: themes,
            statistics: analysis.statistics,
            lookingAhead: generateLookingAhead(from: analysis),
            bottomLine: extractBottomLine(from: content),
            articlesAnalyzed: analysis.articles.map { $0.id }
        )
    }
    
    /// Create structured weekly recap as fallback
    private func createStructuredWeeklyRecap(from analysis: RecapAnalysis) -> WeeklyRecap {
        let weekStart = analysis.timeRange.start
        let weekEnd = analysis.timeRange.end
        let stats = analysis.statistics
        
        // Find biggest story
        let biggestStory = analysis.majorStories.first.map { article in
            RecapStory(
                title: article.title,
                content: "This week's most significant development from \(article.source.name). \(article.summary)\n\nThis story matters because it signals broader shifts in how the industry approaches innovation, competition, and market positioning.",
                sourceArticleId: article.id,
                sourceName: article.source.name,
                importance: calculateArticleScore(article),
                url: article.sourceURL
            )
        }
        
        // Generate themes from trends (matching Python logic)
        var themes: [RecapTheme] = []
        
        if stats.aiStories >= 3 {
            themes.append(createAITheme(from: analysis.trends[.artificialIntelligence] ?? []))
        }
        
        if stats.securityStories >= 2 {
            themes.append(createSecurityTheme(from: analysis.trends[.cybersecurity] ?? []))
        }
        
        if stats.bigTechMoves >= 3 {
            themes.append(createBigTechTheme(from: analysis.trends[.technology] ?? []))
        }
        
        if stats.startupFunding >= 2 {
            themes.append(createFundingTheme(from: analysis.trends[.startups] ?? []))
        }
        
        let summary = createWeeklySummary(
            biggestStory: biggestStory,
            themes: themes,
            statistics: stats,
            weekRange: formatDate(weekStart) + " - " + formatDate(weekEnd)
        )
        
        return WeeklyRecap(
            title: "Tech Weekly: Industry Pulse",
            subtitle: "Week of \(formatDate(weekEnd))",
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            summary: summary,
            biggestStory: biggestStory,
            themes: themes,
            statistics: stats,
            lookingAhead: generateLookingAhead(from: analysis),
            bottomLine: "This week reinforced that we're witnessing a fundamental reshaping of the technology landscape. The convergence of AI capabilities, security challenges, and competitive pressures creates both unprecedented opportunities and risks for businesses and consumers alike.",
            articlesAnalyzed: analysis.articles.map { $0.id }
        )
    }
    
    // MARK: - Helper Methods for Recap Generation
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func getThemeName(for category: CategoryType) -> String {
        switch category {
        case .artificialIntelligence: return "AI Innovation Surge"
        case .cybersecurity: return "Cybersecurity Spotlight"
        case .technology: return "Big Tech Strategic Moves"
        case .startups: return "Startup Funding Landscape"
        case .blockchain: return "Crypto & Web3 Developments"
        case .mobile: return "Mobile Platform Evolution"
        case .cloud: return "Cloud Infrastructure Trends"
        case .iot: return "Connected Device Innovation"
        }
    }
    
    private func getThemeAnalysis(for category: CategoryType, articles: [Article]) -> String {
        switch category {
        case .artificialIntelligence:
            return "The AI landscape continues its rapid evolution, with companies racing to deploy more capable and efficient systems. What's particularly notable is the shift from research breakthroughs to production deployments."
        case .cybersecurity:
            return "Security remains a top priority as digital infrastructure becomes more complex and attack vectors multiply. These incidents highlight the ongoing cat-and-mouse game between security teams and threat actors."
        case .technology:
            return "Major technology companies are making strategic pivots that reflect changing market conditions and competitive pressures. These moves often signal broader industry trends worth watching."
        case .startups:
            return "Despite economic uncertainties, investor appetite for innovative technology companies remains strong, particularly in areas like AI, cybersecurity, and enterprise software."
        default:
            return "Significant developments in this sector continue to shape the broader technology landscape and influence strategic decisions across multiple industries."
        }
    }
    
    private func createAITheme(from articles: [Article]) -> RecapTheme {
        let stories = articles.prefix(3).map { article in
            RecapStory(
                title: article.title,
                content: article.summary,
                sourceArticleId: article.id,
                sourceName: article.source.name,
                importance: calculateArticleScore(article),
                url: article.sourceURL
            )
        }
        
        return RecapTheme(
            name: "AI Innovation Surge",
            content: "The AI revolution continues at breakneck speed with significant model releases and enterprise adoption. Companies are racing not just to build better models, but to make them more accessible and cost-effective.",
            category: .artificialIntelligence,
            stories: Array(stories),
            importance: Double(articles.count)
        )
    }
    
    private func createSecurityTheme(from articles: [Article]) -> RecapTheme {
        let stories = articles.prefix(2).map { article in
            RecapStory(
                title: article.title,
                content: article.summary,
                sourceArticleId: article.id,
                sourceName: article.source.name,
                importance: calculateArticleScore(article),
                url: article.sourceURL
            )
        }
        
        return RecapTheme(
            name: "Cybersecurity Spotlight",
            content: "This week highlighted persistent vulnerabilities in connected systems. Security remains a critical weak point, with researchers continuing to find alarming vulnerabilities across multiple platforms.",
            category: .cybersecurity,
            stories: Array(stories),
            importance: Double(articles.count)
        )
    }
    
    private func createBigTechTheme(from articles: [Article]) -> RecapTheme {
        let stories = articles.prefix(3).map { article in
            RecapStory(
                title: article.title,
                content: article.summary,
                sourceArticleId: article.id,
                sourceName: article.source.name,
                importance: calculateArticleScore(article),
                url: article.sourceURL
            )
        }
        
        return RecapTheme(
            name: "Big Tech Strategic Moves",
            content: "Major technology companies made significant strategic announcements this week. Tech giants are doubling down on AI infrastructure and hardware capabilities, signaling the next phase of competition.",
            category: .technology,
            stories: Array(stories),
            importance: Double(articles.count)
        )
    }
    
    private func createFundingTheme(from articles: [Article]) -> RecapTheme {
        let stories = articles.prefix(3).map { article in
            RecapStory(
                title: article.title,
                content: article.summary,
                sourceArticleId: article.id,
                sourceName: article.source.name,
                importance: calculateArticleScore(article),
                url: article.sourceURL
            )
        }
        
        return RecapTheme(
            name: "Startup Funding Landscape",
            content: "Despite economic uncertainties, investor appetite for innovative technology companies remains strong, particularly in areas like AI, cybersecurity, and enterprise software.",
            category: .startups,
            stories: Array(stories),
            importance: Double(articles.count)
        )
    }
    
    private func generateLookingAhead(from analysis: RecapAnalysis) -> [String] {
        return [
            "Earnings reports from major tech companies will reveal how AI investments are translating to revenue",
            "Regulatory responses to this week's developments, particularly around AI and data privacy",
            "Market reactions to the strategic moves announced this week",
            "Continued evolution in AI model capabilities and deployment strategies"
        ]
    }
    
    private func extractBottomLine(from content: String) -> String {
        // Simple extraction - look for "bottom line" section or use default
        if let range = content.lowercased().range(of: "bottom line") {
            let startIndex = range.upperBound
            let remainingText = String(content[startIndex...])
            let lines = remainingText.components(separatedBy: .newlines)
            let relevantLines = lines.prefix(3).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            return relevantLines.isEmpty ? getDefaultBottomLine() : relevantLines
        }
        return getDefaultBottomLine()
    }
    
    private func getDefaultBottomLine() -> String {
        return "This week reinforced that we're witnessing a fundamental reshaping of the technology landscape. Companies that can effectively balance innovation with security and regulatory compliance are positioning themselves for long-term success."
    }
    
    private func createWeeklySummary(biggestStory: RecapStory?, themes: [RecapTheme], statistics: WeeklyStats, weekRange: String) -> String {
        var summary = "# 📰 Tech Weekly: Industry Pulse\n*\(weekRange)*\n\n---\n\n"
        
        if let story = biggestStory {
            summary += "## 🔥 **THIS WEEK'S HEADLINE**\n\n**\(story.title)**\n\n\(story.content)\n\n---\n\n"
        }
        
        summary += "## 📊 **KEY INDUSTRY THEMES**\n\n"
        
        for theme in themes {
            summary += "### \(theme.name)\n\n"
            for story in theme.stories {
                summary += "- **\(story.title)** (\(story.sourceName))\n"
            }
            summary += "\n\(theme.content)\n\n"
        }
        
        summary += """
        ---
        
        ## 🔮 **LOOKING AHEAD**
        
        **Next Week's Watch List:**
        - Earnings reports from major tech companies will reveal how AI investments are translating to revenue
        - Regulatory responses to this week's developments, particularly around AI and data privacy
        - Market reactions to the strategic moves announced this week
        
        ---
        
        📊 **This Week by the Numbers:**
        - \(statistics.totalArticles) articles analyzed across \(statistics.sourcesAnalyzed) sources
        - \(statistics.aiStories) AI & ML developments tracked
        - \(statistics.securityStories) cybersecurity incidents reported
        - \(statistics.startupFunding) funding announcements
        - \(statistics.bigTechMoves) big tech strategic moves
        
        *Ready for next week's recap? The tech industry never sleeps.* 🚀
        """
        
        return summary
    }
    
    /// Generate AI-powered weekly recap using existing AWS integration
    private func generateAIWeeklyRecap(from analysis: RecapAnalysis) async throws -> WeeklyRecap? {
        do {
            // Use existing AWS Bedrock integration pattern
            let prompt = createWeeklyRecapPrompt(from: analysis)
            
            let payload: [String: Any] = [
                "messages": [
                    ["role": "user", "content": prompt]
                ],
                "max_completion_tokens": 3000,
                "temperature": 0.7
            ]
            
            guard let url = URL(string: "\(summarizationAPIURL)/generate-recap") else {
                throw NewsServiceError.invalidResponse
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            print("🤖 Generating weekly recap with OpenAI GPT-OSS-20B...")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ Weekly recap generation failed")
                return nil
            }
            
            if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let content = jsonResponse["recap"] as? String {
                return parseAIRecapResponse(content, from: analysis)
            }
            
        } catch {
            print("❌ AWS recap generation failed: \(error)")
        }
        
        return nil
    }
}

// MARK: - Recap Service Errors

extension NewsServiceError {
    static func insufficientData(_ message: String) -> NewsServiceError {
        return .networkError // Use existing error type for now
    }
}