import SwiftUI

struct WeeklyRecapListView: View {
    @EnvironmentObject private var dataService: SimpleDataService
    @State private var searchText = ""
    @State private var selectedCategory: CategoryType?
    @State private var isShowingGenerationView = false
    
    private var filteredRecaps: [WeeklyRecap] {
        var recaps = dataService.weeklyRecaps
        
        // Apply search filter
        if !searchText.isEmpty {
            recaps = dataService.searchRecaps(query: searchText)
        }
        
        // Apply category filter
        if let category = selectedCategory {
            recaps = dataService.getRecapsByCategory(category)
        }
        
        return recaps
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if filteredRecaps.isEmpty {
                    EmptyRecapsView(isShowingGenerationView: $isShowingGenerationView)
                } else {
                    RecapsList(recaps: filteredRecaps)
                }
            }
            .navigationTitle("Weekly Recaps")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search recaps...")
            .toolbar {
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
                    
                    Button(action: {
                        isShowingGenerationView = true
                    }) {
                        Image(systemName: "plus.circle")
                    }
                }
            }
            .sheet(isPresented: $isShowingGenerationView) {
                WeeklyRecapGenerationView()
            }
        }
    }
}

// MARK: - Recaps List
struct RecapsList: View {
    let recaps: [WeeklyRecap]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(recaps) { recap in
                    NavigationLink(destination: WeeklyRecapView(recap: recap)) {
                        WeeklyRecapCard(recap: recap)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Weekly Recap Card
struct WeeklyRecapCard: View {
    let recap: WeeklyRecap
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recap.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(recap.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(recap.readingTimeMinutes) min")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    if recap.isCurrentWeek {
                        Text("This Week")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                }
            }
            
            // Preview of biggest story or summary
            if let biggestStory = recap.biggestStory {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        
                        Text("Biggest Story")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    }
                    
                    Text(biggestStory.title)
                        .font(.subheadline)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                }
            } else {
                Text(recap.summary.prefix(120) + "...")
                    .font(.subheadline)
                    .lineLimit(3)
                    .foregroundColor(.secondary)
            }
            
            // Themes preview
            if !recap.themes.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(recap.themes.prefix(3)), id: \.id) { theme in
                            ThemeTag(theme: theme)
                        }
                        
                        if recap.themes.count > 3 {
                            Text("+\(recap.themes.count - 3) more")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
            
            // Stats footer
            HStack {
                Label("\(recap.statistics.totalArticles)", systemImage: "doc.text")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label("\(recap.statistics.sourcesAnalyzed)", systemImage: "globe")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(recap.weekDateRange)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

// MARK: - Theme Tag
struct ThemeTag: View {
    let theme: RecapTheme
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: theme.iconName)
                .font(.caption)
            
            Text(theme.name)
                .font(.caption)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(theme.color.opacity(0.1))
        .foregroundColor(theme.color)
        .cornerRadius(8)
    }
}

// MARK: - Empty State
struct EmptyRecapsView: View {
    @EnvironmentObject private var dataService: SimpleDataService
    @Binding var isShowingGenerationView: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Weekly Recaps Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Generate your first weekly tech industry recap to get started.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                isShowingGenerationView = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Generate Weekly Recap")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            
            if dataService.shouldGenerateWeeklyRecap() {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "lightbulb")
                            .foregroundColor(.yellow)
                        
                        Text("Perfect Timing!")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    Text("It's the weekend - the ideal time to generate a recap of this past week's tech developments.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Auto-Generate This Week") {
                        Task {
                            await dataService.generateWeeklyRecap()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Generation Status View
struct RecapGenerationStatusView: View {
    @EnvironmentObject private var dataService: SimpleDataService
    
    var body: some View {
        if dataService.isGeneratingRecap {
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                
                VStack(spacing: 4) {
                    Text(dataService.recapGenerationStatus.displayName)
                        .font(.headline)
                    
                    Text("This may take a few moments...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

#Preview {
    NavigationStack {
        WeeklyRecapListView()
            .environmentObject(SimpleDataService())
    }
}