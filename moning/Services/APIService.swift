//
//  APIService.swift
//  moning
//
//  Network service for fetching news articles
//

import Foundation

// MARK: - API Response Models
struct NewsAPIResponse: Codable {
    let status: String
    let totalResults: Int
    let articles: [NewsAPIArticle]
}

struct NewsAPIArticle: Codable {
    let source: NewsAPISource
    let author: String?
    let title: String
    let description: String?
    let url: String
    let urlToImage: String?
    let publishedAt: String
    let content: String?
}

struct NewsAPISource: Codable {
    let id: String?
    let name: String
}

// MARK: - API Errors
enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case networkError(Error)
    case invalidAPIKey
    case rateLimitExceeded
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidAPIKey:
            return "Invalid API key"
        case .rateLimitExceeded:
            return "API rate limit exceeded"
        case .serverError(let code):
            return "Server error with code: \(code)"
        }
    }
}

// MARK: - API Service
@MainActor
class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL = APIConfig.newsAPIBaseURL
    private let apiKey = APIConfig.newsAPIKey
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Fetch top headlines for a specific category
    func fetchTopHeadlines(category: String = "technology", country: String = "us", pageSize: Int = 20) async throws -> [NewsAPIArticle] {
        let endpoint = "\(baseURL)/top-headlines"
        var components = URLComponents(string: endpoint)
        
        components?.queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "category", value: category),
            URLQueryItem(name: "country", value: country),
            URLQueryItem(name: "pageSize", value: "\(pageSize)")
        ]
        
        guard let url = components?.url else {
            throw APIError.invalidURL
        }
        
        return try await performRequest(url: url)
    }
    
    /// Search for articles with specific keywords
    func searchArticles(query: String, language: String = "en", sortBy: String = "publishedAt", pageSize: Int = 20) async throws -> [NewsAPIArticle] {
        let endpoint = "\(baseURL)/everything"
        var components = URLComponents(string: endpoint)
        
        components?.queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "language", value: language),
            URLQueryItem(name: "sortBy", value: sortBy),
            URLQueryItem(name: "pageSize", value: "\(pageSize)")
        ]
        
        guard let url = components?.url else {
            throw APIError.invalidURL
        }
        
        return try await performRequest(url: url)
    }
    
    /// Fetch articles from specific sources
    func fetchFromSources(sources: [String], pageSize: Int = 20) async throws -> [NewsAPIArticle] {
        let endpoint = "\(baseURL)/everything"
        var components = URLComponents(string: endpoint)
        
        let sourcesString = sources.joined(separator: ",")
        components?.queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "sources", value: sourcesString),
            URLQueryItem(name: "pageSize", value: "\(pageSize)")
        ]
        
        guard let url = components?.url else {
            throw APIError.invalidURL
        }
        
        return try await performRequest(url: url)
    }
    
    // MARK: - Private Methods
    
    private func performRequest(url: URL) async throws -> [NewsAPIArticle] {
        do {
            let (data, response) = try await session.data(from: url)
            
            // Check HTTP response status
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    break // Success
                case 401:
                    throw APIError.invalidAPIKey
                case 429:
                    throw APIError.rateLimitExceeded
                case 400...499:
                    throw APIError.serverError(httpResponse.statusCode)
                case 500...599:
                    throw APIError.serverError(httpResponse.statusCode)
                default:
                    throw APIError.serverError(httpResponse.statusCode)
                }
            }
            
            // Decode the response
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let newsResponse = try decoder.decode(NewsAPIResponse.self, from: data)
            return newsResponse.articles
            
        } catch let error as APIError {
            throw error
        } catch let decodingError as DecodingError {
            throw APIError.decodingError(decodingError)
        } catch {
            throw APIError.networkError(error)
        }
    }
}

// MARK: - Category Mapping
extension APIService {
    /// Map our app categories to News API categories
    func mapCategoryToNewsAPI(_ category: CategoryType) -> String {
        switch category {
        case .artificialIntelligence:
            return "technology"
        case .startups:
            return "business"
        case .technology:
            return "technology"
        case .blockchain:
            return "technology"
        case .cybersecurity:
            return "technology"
        case .mobile:
            return "technology"
        case .cloud:
            return "technology"
        case .iot:
            return "technology"
        }
    }
    
    /// Get search queries for specific categories
    func getSearchQuery(for category: CategoryType) -> String {
        switch category {
        case .artificialIntelligence:
            return "artificial intelligence OR machine learning OR AI OR neural networks"
        case .startups:
            return "startup OR venture capital OR funding OR entrepreneurship"
        case .technology:
            return "technology OR tech OR software OR hardware"
        case .blockchain:
            return "blockchain OR cryptocurrency OR bitcoin OR ethereum OR web3"
        case .cybersecurity:
            return "cybersecurity OR security breach OR hacking OR privacy"
        case .mobile:
            return "mobile app OR iOS OR Android OR smartphone"
        case .cloud:
            return "cloud computing OR AWS OR Azure OR Google Cloud"
        case .iot:
            return "IoT OR internet of things OR smart devices OR connected devices"
        }
    }
}