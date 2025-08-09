import SwiftUI

struct LatestArticlesView: View {
    let articles = MockData.articles
    let onBackTap: (() -> Void)?
    
    init(onBackTap: (() -> Void)? = nil) {
        self.onBackTap = onBackTap
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Latest Articles")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
                
                LazyVStack(spacing: 12) {
                    ForEach(articles) { article in
                        ArticleCard(article: article)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.top)
        }
    }
}

struct ArticleCard: View {
    let article: Article
    @State private var showingAudioPlayer = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(article.title)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(3)
            
            Text(article.summary)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(4)
            
            HStack(spacing: 12) {
                CategoryTag(category: article.category)
                
                Text(article.source.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(article.timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Spacer()
                
                Button(action: {
                    showingAudioPlayer = true
                }) {
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
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $showingAudioPlayer) {
            AudioPlayerView(article: article)
        }
    }
}