import Foundation
import SwiftUI

// MARK: - Category Management

enum CategoryType: String, CaseIterable, Codable {
    case artificialIntelligence = "AI"
    case startups = "Startups"
    case technology = "Tech"
    case blockchain = "Blockchain"
    case cybersecurity = "Security"
    case mobile = "Mobile"
    case cloud = "Cloud"
    case iot = "IoT"
    
    var displayName: String {
        switch self {
        case .artificialIntelligence:
            return "Artificial Intelligence"
        case .startups:
            return "Startup Ecosystem"
        case .technology:
            return "Technology"
        case .blockchain:
            return "Blockchain & Web3"
        case .cybersecurity:
            return "Cybersecurity"
        case .mobile:
            return "Mobile Development"
        case .cloud:
            return "Cloud Computing"
        case .iot:
            return "Internet of Things"
        }
    }
    
    var color: Color {
        switch self {
        case .artificialIntelligence:
            return .blue
        case .startups:
            return .green
        case .technology:
            return .purple
        case .blockchain:
            return .orange
        case .cybersecurity:
            return .red
        case .mobile:
            return .teal
        case .cloud:
            return .indigo
        case .iot:
            return .mint
        }
    }
    
    var iconName: String {
        switch self {
        case .artificialIntelligence:
            return "brain.head.profile"
        case .startups:
            return "rocket"
        case .technology:
            return "laptopcomputer"
        case .blockchain:
            return "link"
        case .cybersecurity:
            return "shield"
        case .mobile:
            return "iphone"
        case .cloud:
            return "cloud"
        case .iot:
            return "sensor.tag.radiowaves.forward"
        }
    }
    
    var description: String {
        switch self {
        case .artificialIntelligence:
            return "Latest breakthroughs in AI research, model developments, and enterprise adoption across industries."
        case .startups:
            return "Funding rounds, new ventures, and emerging companies shaping the technology landscape."
        case .technology:
            return "Hardware innovations, software updates, and cutting-edge developments in tech."
        case .blockchain:
            return "Cryptocurrency markets, DeFi protocols, and Web3 infrastructure developments."
        case .cybersecurity:
            return "Security threats, data breaches, protection technologies, and privacy developments."
        case .mobile:
            return "Mobile app trends, device launches, and platform updates for iOS and Android."
        case .cloud:
            return "Cloud services, infrastructure innovations, and enterprise cloud adoption trends."
        case .iot:
            return "Connected devices, smart home technology, and industrial IoT implementations."
        }
    }
}

// MARK: - News Source Management

struct NewsSource: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let domain: String
    let isActive: Bool
    let reliability: Double // 0.0 to 1.0
    let categories: [CategoryType]
    let rssURL: String?
    let logoURL: String?
    
    init(id: UUID = UUID(), name: String, domain: String, isActive: Bool = true, 
         reliability: Double = 1.0, categories: [CategoryType] = [], 
         rssURL: String? = nil, logoURL: String? = nil) {
        self.id = id
        self.name = name
        self.domain = domain
        self.isActive = isActive
        self.reliability = reliability
        self.categories = categories
        self.rssURL = rssURL
        self.logoURL = logoURL
    }
}

// MARK: - Article Management

enum ArticleStatus: String, CaseIterable, Codable {
    case unread = "unread"
    case read = "read"
    case bookmarked = "bookmarked"
    case archived = "archived"
}

enum ArticlePriority: String, CaseIterable, Codable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case breaking = "breaking"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        case .breaking: return "Breaking News"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .gray
        case .normal: return .primary
        case .high: return .orange
        case .breaking: return .red
        }
    }
}

struct Article: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let summary: String
    let content: String
    let source: NewsSource
    let category: CategoryType
    let publishedAt: Date
    let audioURL: String?
    let audioDuration: TimeInterval
    let imageURL: String?
    let sourceURL: String?
    let tags: [String]
    let priority: ArticlePriority
    let readingTimeMinutes: Int
    let sentiment: Double // -1.0 (negative) to 1.0 (positive)
    
    // User interaction data (would be stored separately in Core Data)
    var status: ArticleStatus
    var isBookmarked: Bool
    var readAt: Date?
    var audioPlaybackPosition: TimeInterval
    var userRating: Int? // 1-5 stars
    
    // AI Summary fields
    var aiSummary: String?
    var summaryGeneratedAt: Date?
    var summaryModel: String?
    
    init(id: UUID = UUID(), title: String, summary: String, content: String,
         source: NewsSource, category: CategoryType, publishedAt: Date,
         audioURL: String? = nil, audioDuration: TimeInterval = 0,
         imageURL: String? = nil, sourceURL: String? = nil, tags: [String] = [],
         priority: ArticlePriority = .normal, readingTimeMinutes: Int = 3,
         sentiment: Double = 0.0, status: ArticleStatus = .unread,
         isBookmarked: Bool = false, readAt: Date? = nil,
         audioPlaybackPosition: TimeInterval = 0, userRating: Int? = nil,
         aiSummary: String? = nil, summaryGeneratedAt: Date? = nil, summaryModel: String? = nil) {
        self.id = id
        self.title = title
        self.summary = summary
        self.content = content
        self.source = source
        self.category = category
        self.publishedAt = publishedAt
        self.audioURL = audioURL
        self.audioDuration = audioDuration
        self.imageURL = imageURL
        self.sourceURL = sourceURL
        self.tags = tags
        self.priority = priority
        self.readingTimeMinutes = readingTimeMinutes
        self.sentiment = sentiment
        self.status = status
        self.isBookmarked = isBookmarked
        self.readAt = readAt
        self.audioPlaybackPosition = audioPlaybackPosition
        self.userRating = userRating
        self.aiSummary = aiSummary
        self.summaryGeneratedAt = summaryGeneratedAt
        self.summaryModel = summaryModel
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: publishedAt, relativeTo: Date())
    }
    
    var isRecent: Bool {
        Date().timeIntervalSince(publishedAt) < 24 * 60 * 60 // Last 24 hours
    }
    
    var hasAudio: Bool {
        audioURL != nil && audioDuration > 0
    }
    
    var estimatedListeningTime: String {
        guard hasAudio else { return "" }
        let minutes = Int(audioDuration / 60)
        let seconds = Int(audioDuration.truncatingRemainder(dividingBy: 60))
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
    
    var hasSummary: Bool {
        return aiSummary != nil && !aiSummary!.isEmpty
    }
    
    var needsSummaryUpdate: Bool {
        guard let generatedAt = summaryGeneratedAt else { return true }
        return Date().timeIntervalSince(generatedAt) > 86400 // 24 hours
    }
}

// MARK: - User Preferences

struct UserPreferences: Codable, Equatable {
    var preferredCategories: [CategoryType]
    var readingSpeed: Int // Words per minute
    var audioPlaybackSpeed: Double // 0.5x to 2.0x
    var notificationsEnabled: Bool
    var dailyDigestTime: Date
    var autoPlayAudio: Bool
    var offlineModeEnabled: Bool
    var dataSaverMode: Bool
    var preferredAudioVoice: String
    
    static let `default` = UserPreferences(
        preferredCategories: [.artificialIntelligence, .technology],
        readingSpeed: 250,
        audioPlaybackSpeed: 1.0,
        notificationsEnabled: true,
        dailyDigestTime: Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date(),
        autoPlayAudio: false,
        offlineModeEnabled: false,
        dataSaverMode: false,
        preferredAudioVoice: "system"
    )
}

// MARK: - Category Overview

struct CategoryOverview: Identifiable, Codable {
    let id: UUID
    let category: CategoryType
    let articleCount: Int
    let unreadCount: Int
    let topHeadlines: [String]
    let articles: [Article]
    let lastUpdated: Date
    
    init(id: UUID = UUID(), category: CategoryType, articleCount: Int,
         unreadCount: Int, topHeadlines: [String], articles: [Article],
         lastUpdated: Date = Date()) {
        self.id = id
        self.category = category
        self.articleCount = articleCount
        self.unreadCount = unreadCount
        self.topHeadlines = topHeadlines
        self.articles = articles
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Reading History

struct ReadingSession: Identifiable, Codable {
    let id: UUID
    let articleId: UUID
    let startTime: Date
    let endTime: Date?
    let durationSeconds: TimeInterval
    let completionPercentage: Double // 0.0 to 1.0
    let readingMode: ReadingMode
    
    init(id: UUID = UUID(), articleId: UUID, startTime: Date = Date(),
         endTime: Date? = nil, durationSeconds: TimeInterval = 0,
         completionPercentage: Double = 0, readingMode: ReadingMode = .text) {
        self.id = id
        self.articleId = articleId
        self.startTime = startTime
        self.endTime = endTime
        self.durationSeconds = durationSeconds
        self.completionPercentage = completionPercentage
        self.readingMode = readingMode
    }
}

enum ReadingMode: String, CaseIterable, Codable {
    case text = "text"
    case audio = "audio"
    case mixed = "mixed"
    
    var displayName: String {
        switch self {
        case .text: return "Text"
        case .audio: return "Audio"
        case .mixed: return "Text + Audio"
        }
    }
}

// MARK: - Search and Filtering

struct ArticleFilter {
    var categories: Set<CategoryType> = []
    var sources: Set<UUID> = []
    var status: Set<ArticleStatus> = []
    var priority: Set<ArticlePriority> = []
    var dateRange: ClosedRange<Date>?
    var hasAudio: Bool?
    var searchQuery: String = ""
    var sortBy: ArticleSortOption = .publishedAt
    var sortOrder: SortOrder = .descending
    
    var isActive: Bool {
        !categories.isEmpty || !sources.isEmpty || !status.isEmpty ||
        !priority.isEmpty || dateRange != nil || hasAudio != nil ||
        !searchQuery.isEmpty
    }
}

enum ArticleSortOption: String, CaseIterable {
    case publishedAt = "publishedAt"
    case title = "title"
    case readingTime = "readingTime"
    case priority = "priority"
    case sentiment = "sentiment"
    
    var displayName: String {
        switch self {
        case .publishedAt: return "Date Published"
        case .title: return "Title"
        case .readingTime: return "Reading Time"
        case .priority: return "Priority"
        case .sentiment: return "Sentiment"
        }
    }
}

enum SortOrder: String, CaseIterable {
    case ascending = "ascending"
    case descending = "descending"
    
    var displayName: String {
        switch self {
        case .ascending: return "Ascending"
        case .descending: return "Descending"
        }
    }
}