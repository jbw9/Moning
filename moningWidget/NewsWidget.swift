import SwiftUI
import WidgetKit

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
                Text(entry.article.source.name)
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
    let article: Article
}

struct NewsWidgetProvider: TimelineProvider {
    private var placeholderArticle: Article {
        Article(
            title: "Loading latest AI & tech news...",
            summary: "Your personalized news digest will appear here once articles are loaded.",
            content: "Please open the Moning app to load the latest articles.",
            source: NewsSource(name: "Moning", domain: "moning.app"),
            category: .artificialIntelligence,
            publishedAt: Date(),
            audioURL: nil,
            audioDuration: 0,
            imageURL: nil
        )
    }
    
    func placeholder(in context: Context) -> NewsWidgetEntry {
        NewsWidgetEntry(
            date: Date(),
            article: placeholderArticle
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (NewsWidgetEntry) -> Void) {
        // TODO: Fetch real articles from Core Data via App Group
        let entry = NewsWidgetEntry(
            date: Date(),
            article: placeholderArticle
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<NewsWidgetEntry>) -> Void) {
        let currentDate = Date()
        // TODO: Fetch real articles from Core Data via App Group
        let entry = NewsWidgetEntry(
            date: currentDate,
            article: placeholderArticle
        )
        
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
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
    let placeholderArticle = Article(
        title: "AI Breakthrough in Neural Networks",
        summary: "Researchers achieve new milestone in artificial intelligence development.",
        content: "Latest developments in AI technology continue to push boundaries.",
        source: NewsSource(name: "TechNews", domain: "technews.com"),
        category: .artificialIntelligence,
        publishedAt: Date(),
        audioURL: nil,
        audioDuration: 0,
        imageURL: nil
    )
    NewsWidgetEntry(date: Date(), article: placeholderArticle)
}