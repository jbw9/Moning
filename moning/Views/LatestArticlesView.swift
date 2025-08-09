import SwiftUI

struct LatestArticlesView: View {
    @EnvironmentObject private var dataService: SimpleDataService
    let onBackTap: (() -> Void)?
    
    init(onBackTap: (() -> Void)? = nil) {
        self.onBackTap = onBackTap
    }
    
    private var articles: [Article] {
        dataService.articles
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
    @StateObject private var audioManager = AudioManager.shared
    
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
                
                if article.hasAudio {
                    Image(systemName: "speaker.wave.2")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            HStack {
                if article.hasAudio {
                    Text(article.estimatedListeningTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if article.hasAudio {
                    Button(action: {
                        if audioManager.currentArticle?.id == article.id {
                            // Same article - toggle play/pause
                            if audioManager.isPlaying {
                                audioManager.pause()
                            } else {
                                audioManager.play()
                            }
                        } else {
                            // New article - start playing
                            audioManager.playArticle(article)
                        }
                    }) {
                        Image(systemName: audioManager.currentArticle?.id == article.id && audioManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(audioManager.currentArticle?.id == article.id ? Color.blue : Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}