import SwiftUI

struct IndustryOverviewView: View {
    let categoryOverviews = MockData.categoryOverviews
    let onCategoryTap: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Industry Overview")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
                
                LazyVStack(spacing: 12) {
                    ForEach(categoryOverviews) { overview in
                        CategoryCard(overview: overview)
                            .padding(.horizontal)
                            .onTapGesture {
                                onCategoryTap()
                            }
                    }
                }
            }
            .padding(.top)
        }
    }
}

struct CategoryCard: View {
    let overview: CategoryOverview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                CategoryTag(category: overview.category)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(overview.category.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(overview.articleCount) articles")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14, weight: .semibold))
            }
            
            Text(overview.category.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Top Headlines:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                ForEach(overview.topHeadlines, id: \.self) { headline in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(headline)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CategoryTag: View {
    let category: CategoryType
    
    var body: some View {
        Text(category.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tagColor)
            .cornerRadius(6)
    }
    
    private var tagColor: Color {
        switch category {
        case .artificialIntelligence:
            return .blue
        case .startups:
            return .green
        case .technology:
            return .purple
        }
    }
}