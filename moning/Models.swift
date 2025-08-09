import Foundation

enum CategoryType: String, CaseIterable {
    case artificialIntelligence = "AI"
    case startups = "Startups"
    case technology = "Tech"
    
    var displayName: String {
        switch self {
        case .artificialIntelligence:
            return "Artificial Intelligence"
        case .startups:
            return "Startup Ecosystem"
        case .technology:
            return "Technology"
        }
    }
    
    var color: String {
        switch self {
        case .artificialIntelligence:
            return "blue"
        case .startups:
            return "green"
        case .technology:
            return "purple"
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
        }
    }
}

struct NewsSource: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let domain: String
}

struct Article: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let summary: String
    let content: String
    let source: NewsSource
    let category: CategoryType
    let publishedAt: Date
    let audioURL: String?
    let audioDuration: TimeInterval
    let imageURL: String?
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: publishedAt, relativeTo: Date())
    }
}

struct CategoryOverview: Identifiable {
    let id = UUID()
    let category: CategoryType
    let articleCount: Int
    let topHeadlines: [String]
    let articles: [Article]
}