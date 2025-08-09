import SwiftUI
import WidgetKit
import CoreData

struct NewsWidgetEntryView: View {
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
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct NewsWidgetEntry: TimelineEntry {
    let date: Date
    let article: WidgetArticle
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
            let articles = await dataService.fetchLatestArticles(limit: 1)
            let article = articles.first ?? placeholderArticle
            
            await MainActor.run {
                let entry = NewsWidgetEntry(
                    date: Date(),
                    article: article
                )
                completion(entry)
            }
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<NewsWidgetEntry>) -> Void) {
        // Fetch real articles from Core Data via App Group
        Task {
            let articles = await dataService.fetchLatestArticles(limit: 5)
            let currentDate = Date()
            
            var entries: [NewsWidgetEntry] = []
            
            // Create entries for the next few hours, cycling through articles
            for hourOffset in 0..<5 {
                let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate) ?? currentDate
                let articleIndex = hourOffset % max(articles.count, 1)
                let article = articles.isEmpty ? placeholderArticle : articles[articleIndex]
                
                entries.append(NewsWidgetEntry(date: entryDate, article: article))
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
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    NewsWidget()
} timeline: {
    let placeholderArticle = WidgetArticle(
        id: UUID(),
        title: "AI Breakthrough in Neural Networks",
        summary: "Researchers achieve new milestone in artificial intelligence development.",
        sourceName: "TechNews",
        category: "AI",
        publishedAt: Date()
    )
    NewsWidgetEntry(date: Date(), article: placeholderArticle)
}