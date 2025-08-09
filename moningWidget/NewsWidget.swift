import SwiftUI
import WidgetKit
import CoreData

struct NewsWidgetEntryView: View {
    let entry: NewsWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .systemLarge:
                LargeWidgetView(entry: entry)
            case .accessoryRectangular:
                LockScreenWidgetView(entry: entry)
            default:
                MediumWidgetView(entry: entry)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: NewsWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category badge
            HStack {
                Text(entry.article.category)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue)
                    .clipShape(Capsule())
                
                Spacer()
            }
            
            // Title (more lines for small widget)
            Text(entry.article.title)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(6)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            
            // Bottom row with source and play button
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.article.sourceName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(timeAgo(from: entry.article.publishedAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Smaller play button for small widget
                Link(destination: URL(string: "moning://play/\(entry.article.id.uuidString)")!) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
        }
        .padding(12)
    }
}

// MARK: - Medium Widget View (Current Implementation)

struct MediumWidgetView: View {
    let entry: NewsWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(entry.article.title)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(4)
            
            Spacer()
            
            HStack {
                Text(entry.article.sourceName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Link(destination: URL(string: "moning://play/\(entry.article.id.uuidString)")!) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Large Widget View

struct LargeWidgetView: View {
    let entry: NewsWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with app name and controls
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Moning AI News")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Daily Tech Digest")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Play all button
                Link(destination: URL(string: "moning://play/all")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12))
                        Text("Play All")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .clipShape(Capsule())
                }
            }
            
            // Article list (show up to 3 articles)
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(entry.articles.prefix(3).enumerated()), id: \.element.id) { index, article in
                    LargeWidgetArticleRow(
                        article: article, 
                        index: index + 1,
                        isLast: index == min(entry.articles.count - 1, 2)
                    )
                }
            }
            
            Spacer()
            
            // Footer with summary
            HStack {
                Text("Updated \(timeAgo(from: entry.date))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(entry.articles.count) articles available")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
    }
}

struct LargeWidgetArticleRow: View {
    let article: WidgetArticle
    let index: Int
    let isLast: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Article number badge
                Text("\(index)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(Color.blue)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    HStack {
                        Text(article.category)
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                        
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(article.sourceName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Individual play button
                Link(destination: URL(string: "moning://play/\(article.id.uuidString)")!) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
            }
            
            // Divider (except for last item)
            if !isLast {
                Divider()
                    .padding(.leading, 32)
                    .padding(.top, 8)
            }
        }
    }
}

// MARK: - Lock Screen Widget View (iOS 16+)

struct LockScreenWidgetView: View {
    let entry: NewsWidgetEntry
    
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.article.category.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                Text(entry.article.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "waveform.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Helper Functions

private func timeAgo(from date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter.localizedString(for: date, relativeTo: Date())
}

struct NewsWidgetEntry: TimelineEntry {
    let date: Date
    let article: WidgetArticle
    let articles: [WidgetArticle] // For large widget multiple articles
    
    init(date: Date, article: WidgetArticle, articles: [WidgetArticle] = []) {
        self.date = date
        self.article = article
        self.articles = articles.isEmpty ? [article] : articles
    }
}

struct NewsWidgetProvider: TimelineProvider {
    private let dataService = WidgetDataService.shared
    
    private var placeholderArticle: WidgetArticle {
        WidgetArticle(
            id: UUID(),
            title: "Loading latest AI & tech news...",
            summary: "Your personalized news digest will appear here once articles are loaded.",
            sourceName: "Moning",
            category: "AI",
            publishedAt: Date()
        )
    }
    
    func placeholder(in context: Context) -> NewsWidgetEntry {
        NewsWidgetEntry(
            date: Date(),
            article: placeholderArticle
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (NewsWidgetEntry) -> Void) {
        // Fetch real articles from Core Data via App Group
        Task {
            let articleCount = context.family == .systemLarge ? 5 : 1
            let articles = await dataService.fetchLatestArticles(limit: articleCount)
            let article = articles.first ?? placeholderArticle
            
            await MainActor.run {
                let entry = NewsWidgetEntry(
                    date: Date(),
                    article: article,
                    articles: articles.isEmpty ? [placeholderArticle] : articles
                )
                completion(entry)
            }
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<NewsWidgetEntry>) -> Void) {
        // Fetch real articles from Core Data via App Group
        Task {
            let articleCount = context.family == .systemLarge ? 8 : 5
            let articles = await dataService.fetchLatestArticles(limit: articleCount)
            let currentDate = Date()
            
            var entries: [NewsWidgetEntry] = []
            
            // Create entries for the next few hours, cycling through articles
            for hourOffset in 0..<5 {
                let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate) ?? currentDate
                let articleIndex = hourOffset % max(articles.count, 1)
                let article = articles.isEmpty ? placeholderArticle : articles[articleIndex]
                
                // For large widgets, provide all articles; for others, just the main article
                let widgetArticles = context.family == .systemLarge ? articles : [article]
                
                entries.append(NewsWidgetEntry(
                    date: entryDate, 
                    article: article,
                    articles: widgetArticles.isEmpty ? [placeholderArticle] : widgetArticles
                ))
            }
            
            await MainActor.run {
                let nextUpdate = Calendar.current.date(byAdding: .hour, value: 2, to: currentDate)!
                let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
                completion(timeline)
            }
        }
    }
}

struct NewsWidget: Widget {
    let kind: String = "NewsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NewsWidgetProvider()) { entry in
            NewsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("News Widget")
        .description("Stay updated with the latest AI and tech news.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular])
    }
}

// MARK: - Previews for All Widget Sizes

#Preview("Small Widget", as: .systemSmall) {
    NewsWidget()
} timeline: {
    let article = WidgetArticle(
        id: UUID(),
        title: "OpenAI Releases Revolutionary GPT-5 with Breakthrough Reasoning Capabilities",
        summary: "The new model demonstrates unprecedented problem-solving abilities.",
        sourceName: "TechCrunch",
        category: "AI",
        publishedAt: Date()
    )
    NewsWidgetEntry(date: Date(), article: article, articles: [article])
}

#Preview("Medium Widget", as: .systemMedium) {
    NewsWidget()
} timeline: {
    let article = WidgetArticle(
        id: UUID(),
        title: "AI Breakthrough in Neural Networks Transforms Medical Diagnostics",
        summary: "Researchers achieve new milestone in artificial intelligence development.",
        sourceName: "MIT Tech Review",
        category: "AI",
        publishedAt: Date()
    )
    NewsWidgetEntry(date: Date(), article: article, articles: [article])
}

#Preview("Large Widget", as: .systemLarge) {
    NewsWidget()
} timeline: {
    let articles = [
        WidgetArticle(
            id: UUID(),
            title: "OpenAI Unveils GPT-5: Revolutionary AI Model Changes Everything",
            summary: "The latest language model demonstrates unprecedented reasoning capabilities.",
            sourceName: "TechCrunch", 
            category: "AI",
            publishedAt: Date()
        ),
        WidgetArticle(
            id: UUID(),
            title: "Quantum Computing Breakthrough Achieves 1000-Qubit Milestone",
            summary: "New quantum processor delivers unprecedented performance for complex calculations.",
            sourceName: "Nature",
            category: "Tech",
            publishedAt: Date().addingTimeInterval(-3600)
        ),
        WidgetArticle(
            id: UUID(),
            title: "Healthcare Startup Raises $100M for AI-Powered Drug Discovery",
            summary: "Innovative platform uses machine learning to accelerate pharmaceutical research.",
            sourceName: "Forbes",
            category: "Startups", 
            publishedAt: Date().addingTimeInterval(-7200)
        ),
        WidgetArticle(
            id: UUID(),
            title: "Apple's New Neural Engine Delivers 40% Performance Boost",
            summary: "Latest M4 chip architecture optimized for AI workloads and machine learning.",
            sourceName: "9to5Mac",
            category: "Mobile",
            publishedAt: Date().addingTimeInterval(-10800)
        )
    ]
    
    NewsWidgetEntry(date: Date(), article: articles[0], articles: articles)
}

#Preview("Lock Screen Widget", as: .accessoryRectangular) {
    NewsWidget()
} timeline: {
    let article = WidgetArticle(
        id: UUID(),
        title: "Meta Launches Advanced AR Glasses for Mainstream Market",
        summary: "Consumer-ready augmented reality device hits stores nationwide.",
        sourceName: "The Verge",
        category: "Tech",
        publishedAt: Date()
    )
    NewsWidgetEntry(date: Date(), article: article, articles: [article])
}