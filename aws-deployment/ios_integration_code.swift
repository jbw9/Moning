// iOS Integration Code for Moning News App
// Add this to your existing NewsService.swift

import Foundation

// MARK: - Summarization API Models
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

// MARK: - NewsService Extension for Summarization
extension NewsService {
    
    // Your deployed API endpoint
    private var summarizationAPIURL: String {
        return "https://y501z1431b.execute-api.us-west-2.amazonaws.com/prod"
    }
    
    /// Fetch summaries for multiple articles
    func fetchSummariesForArticles(_ articles: [Article]) async throws -> [String: String] {
        let articleIds = articles.compactMap { $0.id }
        
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
    
    /// Process articles and update with summaries
    func processArticlesWithSummaries(_ articles: [Article]) async {
        do {
            // Fetch summaries for all articles
            let summaries = try await fetchSummariesForArticles(articles)
            
            // Update articles with summaries in Core Data
            await MainActor.run {
                for article in articles {
                    guard let articleId = article.id,
                          let summary = summaries[articleId] else { continue }
                    
                    // Add summary to your Article model
                    // You'll need to add these properties to your Core Data model:
                    article.aiSummary = summary
                    article.summaryGeneratedAt = Date()
                    article.summaryModel = "openai.gpt-oss-20b-1:0"
                }
                
                // Save context
                do {
                    try dataService.context.save()
                    print("💾 Saved \(summaries.count) summaries to Core Data")
                } catch {
                    print("❌ Failed to save summaries: \(error)")
                }
            }
            
        } catch {
            print("❌ Failed to process summaries: \(error)")
        }
    }
    
    /// Enhanced news fetching with automatic summarization
    func fetchNewsWithSummaries() async throws -> [Article] {
        // Fetch news articles as usual
        let articles = try await fetchLatestNews()
        
        // Process articles in background for summaries
        Task {
            await processArticlesWithSummaries(articles)
        }
        
        return articles
    }
}

// MARK: - Core Data Model Updates
// Add these properties to your Article entity in Core Data:

/*
 Add to Article+CoreDataProperties.swift:
 
 @NSManaged public var aiSummary: String?
 @NSManaged public var summaryGeneratedAt: Date?
 @NSManaged public var summaryModel: String?
 
 Add computed property:
 
 var hasSummary: Bool {
     return aiSummary != nil && !aiSummary!.isEmpty
 }
 
 var needsSummaryUpdate: Bool {
     guard let generatedAt = summaryGeneratedAt else { return true }
     return Date().timeIntervalSince(generatedAt) > 86400 // 24 hours
 }
*/

// MARK: - Usage in Views
/*
 Update your views to use summaries:
 
 // In TodayView.swift or ArticleRowView.swift:
 
 struct ArticleRowView: View {
     let article: Article
     
     var body: some View {
         VStack(alignment: .leading, spacing: 8) {
             Text(article.title ?? "")
                 .font(.headline)
             
             // Show AI summary if available
             if let summary = article.aiSummary, !summary.isEmpty {
                 Text(summary)
                     .font(.subheadline)
                     .foregroundColor(.secondary)
                     .lineLimit(3)
                     .padding(.horizontal)
                     .padding(.vertical, 6)
                     .background(Color.blue.opacity(0.1))
                     .cornerRadius(8)
             }
             
             HStack {
                 Text(article.source ?? "Unknown")
                     .font(.caption)
                     .foregroundColor(.secondary)
                 
                 Spacer()
                 
                 if article.hasSummary {
                     Label("AI Summary", systemImage: "brain")
                         .font(.caption2)
                         .foregroundColor(.blue)
                 }
             }
         }
         .padding()
     }
 }
*/

// MARK: - Error Handling
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