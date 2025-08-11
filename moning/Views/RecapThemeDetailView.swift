import SwiftUI

struct RecapThemeDetailView: View {
    let theme: RecapTheme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    ThemeHeaderView(theme: theme)
                    
                    // Content
                    ThemeContentView(theme: theme)
                    
                    // Stories
                    if !theme.stories.isEmpty {
                        ThemeStoriesView(stories: theme.stories)
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Theme Details")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Theme Header View
struct ThemeHeaderView: View {
    let theme: RecapTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: theme.iconName)
                    .font(.system(size: 40))
                    .foregroundColor(theme.color)
                    .frame(width: 60, height: 60)
                    .background(theme.color.opacity(0.1))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(theme.category.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("\(theme.stories.count) stories")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(theme.color.opacity(0.2))
                            .foregroundColor(theme.color)
                            .cornerRadius(6)
                        
                        Text("Impact: \(String(format: "%.1f", theme.importance))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - Theme Content View
struct ThemeContentView: View {
    let theme: RecapTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analysis")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(theme.content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

// MARK: - Theme Stories View
struct ThemeStoriesView: View {
    let stories: [RecapStory]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Stories")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 12) {
                ForEach(Array(stories.enumerated()), id: \.element.id) { index, story in
                    ThemeStoryCard(story: story, rank: index + 1)
                }
            }
        }
    }
}

// MARK: - Theme Story Card
struct ThemeStoryCard: View {
    let story: RecapStory
    let rank: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Rank indicator
            Text("\(rank)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(importanceColor)
                .cornerRadius(15)
            
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(story.title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .lineLimit(3)
                
                // Content preview
                Text(story.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(4)
                
                // Footer
                HStack {
                    Text(story.sourceName)
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    if let url = story.url {
                        Link("Read Full Story", destination: URL(string: url)!)
                            .font(.caption)
                    }
                    
                    Text("Impact: \(String(format: "%.1f", story.importance))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
    
    private var importanceColor: Color {
        if story.importance >= 8.0 {
            return .red
        } else if story.importance >= 6.0 {
            return .orange
        } else {
            return .blue
        }
    }
}

#Preview {
    RecapThemeDetailView(
        theme: RecapTheme(
            name: "AI Innovation Surge",
            content: "The AI landscape continues its rapid evolution, with companies racing to deploy more capable and efficient systems. What's particularly notable is the shift from research breakthroughs to production deployments, suggesting we're moving from the 'wow factor' phase to the 'value creation' phase of the AI revolution.",
            category: .artificialIntelligence,
            stories: [
                RecapStory(
                    title: "OpenAI Announces GPT-5 with Revolutionary Capabilities",
                    content: "OpenAI surprised the tech world with the announcement of GPT-5, featuring breakthrough reasoning capabilities that surpass previous models. The new model demonstrates significant improvements in mathematical reasoning, code generation, and multi-modal understanding.",
                    sourceName: "TechCrunch",
                    importance: 9.2
                ),
                RecapStory(
                    title: "Google's Gemini Ultra Challenges GPT-4 in Comprehensive Benchmarks",
                    content: "Google's latest AI model shows impressive performance across multiple domains, particularly in scientific reasoning and creative tasks. The model represents Google's most ambitious attempt to compete directly with OpenAI.",
                    sourceName: "The Verge",
                    importance: 8.5
                ),
                RecapStory(
                    title: "Microsoft Integrates Advanced AI into Office Suite",
                    content: "Microsoft announced comprehensive AI integration across all Office applications, promising to transform how users interact with documents, spreadsheets, and presentations through natural language processing.",
                    sourceName: "Ars Technica",
                    importance: 7.8
                )
            ],
            importance: 8.5
        )
    )
}

// MARK: - Recap Articles View
struct RecapArticlesView: View {
    let recap: WeeklyRecap
    @EnvironmentObject private var dataService: SimpleDataService
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: CategoryType?
    
    private var articles: [Article] {
        dataService.getArticlesForRecap(recap)
    }
    
    private var filteredArticles: [Article] {
        var result = articles
        
        if !searchText.isEmpty {
            result = result.filter { article in
                article.title.localizedCaseInsensitiveContains(searchText) ||
                article.summary.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        return result.sorted { $0.publishedAt > $1.publishedAt }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if filteredArticles.isEmpty {
                    EmptyArticlesView()
                } else {
                    ArticlesList(articles: filteredArticles)
                }
            }
            .navigationTitle("Source Articles")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search articles...")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Button("All Categories") {
                            selectedCategory = nil
                        }
                        
                        ForEach(CategoryType.allCases, id: \.self) { category in
                            Button(category.displayName) {
                                selectedCategory = category
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }
}

// MARK: - Articles List
struct ArticlesList: View {
    let articles: [Article]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(articles) { article in
                    RecapArticleCard(article: article)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Recap Article Card
struct RecapArticleCard: View {
    let article: Article
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .lineLimit(3)
                    
                    Text(article.summary)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    CategoryBadge(category: article.category)
                    
                    Text(article.timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text(article.source.name)
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Spacer()
                
                if let url = article.sourceURL {
                    Link("Read Article", destination: URL(string: url)!)
                        .font(.caption)
                }
                
                Text("\(article.readingTimeMinutes) min read")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct CategoryBadge: View {
    let category: CategoryType
    
    var body: some View {
        Text(category.rawValue)
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(category.color.opacity(0.1))
            .foregroundColor(category.color)
            .cornerRadius(4)
    }
}

// MARK: - Empty Articles View
struct EmptyArticlesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No Articles Found")
                .font(.headline)
            
            Text("The source articles for this recap are not currently available.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}