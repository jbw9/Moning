import SwiftUI

struct TodayView: View {
    @State private var selectedView: TodayViewType = .industryOverview
    
    enum TodayViewType {
        case industryOverview
        case latestArticles
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if selectedView == .industryOverview {
                    IndustryOverviewView(onCategoryTap: {
                        selectedView = .latestArticles
                    })
                } else {
                    LatestArticlesView(onBackTap: {
                        selectedView = .industryOverview
                    })
                }
            }
            .navigationTitle("News")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}