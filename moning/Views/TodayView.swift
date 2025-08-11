import SwiftUI

struct TodayView: View {
    @State private var selectedView: TodayViewType = .industryOverview
    
    enum TodayViewType {
        case industryOverview
        case latestArticles
        case weeklyRecaps
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                switch selectedView {
                case .industryOverview:
                    IndustryOverviewView(onCategoryTap: {
                        selectedView = .latestArticles
                    })
                case .latestArticles:
                    LatestArticlesView(onBackTap: {
                        selectedView = .industryOverview
                    })
                case .weeklyRecaps:
                    WeeklyRecapListView()
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            selectedView = .industryOverview
                        }) {
                            Label("Industry Overview", systemImage: "chart.pie")
                        }
                        
                        Button(action: {
                            selectedView = .latestArticles
                        }) {
                            Label("Latest Articles", systemImage: "doc.text")
                        }
                        
                        Button(action: {
                            selectedView = .weeklyRecaps
                        }) {
                            Label("Weekly Recaps", systemImage: "newspaper")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    private var navigationTitle: String {
        switch selectedView {
        case .industryOverview:
            return "News"
        case .latestArticles:
            return "Latest Articles"
        case .weeklyRecaps:
            return "Weekly Recaps"
        }
    }
}