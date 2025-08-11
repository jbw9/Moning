import SwiftUI

struct WeeklyRecapView: View {
    let recap: WeeklyRecap
    @EnvironmentObject private var dataService: SimpleDataService
    @State private var selectedTheme: RecapTheme?
    @State private var isShowingArticles = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Section
                RecapHeaderView(recap: recap)
                
                // Biggest Story Section
                if let biggestStory = recap.biggestStory {
                    BiggestStorySection(story: biggestStory)
                }
                
                // Key Themes Section
                if !recap.themes.isEmpty {
                    KeyThemesSection(themes: recap.themes, selectedTheme: $selectedTheme)
                }
                
                // Statistics Section
                StatsSection(stats: recap.statistics)
                
                // Looking Ahead Section
                if !recap.lookingAhead.isEmpty {
                    LookingAheadSection(items: recap.lookingAhead)
                }
                
                // Bottom Line Section
                BottomLineSection(bottomLine: recap.bottomLine)
                
                // Actions Section
                RecapActionsView(recap: recap)
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .navigationTitle("Weekly Recap")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedTheme) { theme in
            RecapThemeDetailView(theme: theme)
        }
        .sheet(isPresented: $isShowingArticles) {
            RecapArticlesView(recap: recap)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Articles") {
                    isShowingArticles = true
                }
            }
        }
    }
}

// MARK: - Header View
struct RecapHeaderView: View {
    let recap: WeeklyRecap
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recap.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(recap.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(recap.readingTimeMinutes) min read")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(recap.weekDateRange)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(recap.summary.prefix(200) + "...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Biggest Story Section
struct BiggestStorySection: View {
    let story: RecapStory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                
                Text("This Week's Headline")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(story.title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(story.content)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(story.sourceName)
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    if let url = story.url {
                        Link("Read Full Story", destination: URL(string: url)!)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Key Themes Section
struct KeyThemesSection: View {
    let themes: [RecapTheme]
    @Binding var selectedTheme: RecapTheme?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("Key Industry Themes")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            LazyVStack(spacing: 12) {
                ForEach(themes) { theme in
                    ThemeCard(theme: theme)
                        .onTapGesture {
                            selectedTheme = theme
                        }
                }
            }
        }
    }
}

// MARK: - Theme Card
struct ThemeCard: View {
    let theme: RecapTheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: theme.iconName)
                .foregroundColor(theme.color)
                .font(.title2)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(theme.name)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(theme.stories.count) stories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(theme.content.prefix(150) + "...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

// MARK: - Statistics Section
struct StatsSection: View {
    let stats: WeeklyStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                Text("This Week by the Numbers")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(title: "Articles Analyzed", value: "\(stats.totalArticles)", icon: "doc.text")
                StatCard(title: "Sources", value: "\(stats.sourcesAnalyzed)", icon: "globe")
                StatCard(title: "AI Stories", value: "\(stats.aiStories)", icon: "brain.head.profile")
                StatCard(title: "Security Stories", value: "\(stats.securityStories)", icon: "shield")
                StatCard(title: "Funding News", value: "\(stats.startupFunding)", icon: "dollarsign.circle")
                StatCard(title: "Big Tech Moves", value: "\(stats.bigTechMoves)", icon: "building.2")
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(10)
    }
}

// MARK: - Looking Ahead Section
struct LookingAheadSection: View {
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "crystal.ball")
                    .foregroundColor(.purple)
                    .font(.title2)
                
                Text("Looking Ahead")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 12) {
                        Text("•")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text(item)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Bottom Line Section
struct BottomLineSection: View {
    let bottomLine: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
                
                Text("The Bottom Line")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Text(bottomLine)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Actions Section
struct RecapActionsView: View {
    let recap: WeeklyRecap
    @EnvironmentObject private var dataService: SimpleDataService
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                dataService.markRecapAsRead(recap)
            }) {
                HStack {
                    Image(systemName: "checkmark.circle")
                    Text("Mark as Read")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            Button(action: {
                // Share functionality
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Recap")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(10)
            }
        }
    }
}

#Preview {
    NavigationStack {
        WeeklyRecapView(recap: WeeklyRecap(
            title: "Tech Weekly: Industry Pulse",
            subtitle: "Week of August 11, 2025",
            weekStartDate: Date().addingTimeInterval(-7*24*60*60),
            weekEndDate: Date(),
            summary: "This week was dominated by AI developments and security concerns...",
            biggestStory: RecapStory(
                title: "OpenAI Announces GPT-5 with Revolutionary Capabilities",
                content: "The AI world was shaken this week by OpenAI's surprise announcement of GPT-5...",
                sourceName: "TechCrunch",
                importance: 9.5
            ),
            themes: [
                RecapTheme(
                    name: "AI Innovation Surge",
                    content: "Multiple AI companies announced significant breakthroughs...",
                    category: .artificialIntelligence,
                    importance: 8.0
                )
            ],
            statistics: WeeklyStats(
                totalArticles: 150,
                sourcesAnalyzed: 12,
                aiStories: 25,
                securityStories: 8,
                startupFunding: 12,
                bigTechMoves: 18
            ),
            lookingAhead: [
                "AI regulation discussions in Congress",
                "Apple's AI strategy announcement expected"
            ],
            bottomLine: "This week reinforced the rapid pace of AI development..."
        ))
    }
    .environmentObject(SimpleDataService())
}