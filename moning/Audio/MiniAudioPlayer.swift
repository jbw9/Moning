import SwiftUI

struct MiniAudioPlayer: View {
    @StateObject private var audioManager = AudioManager.shared
    @State private var isDragging = false
    
    var body: some View {
        if let article = audioManager.currentArticle {
            VStack(spacing: 0) {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 2)
                        
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * audioManager.playbackProgress, height: 2)
                    }
                }
                .frame(height: 2)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            let progress = max(0, min(1, value.location.x / UIScreen.main.bounds.width))
                            let newTime = progress * audioManager.duration
                            audioManager.seek(to: newTime)
                        }
                )
                
                // Mini player controls
                HStack(spacing: 12) {
                    // Article info
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(article.category.color.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: article.category.iconName)
                                    .font(.system(size: 16))
                                    .foregroundColor(article.category.color)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(article.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            
                            Text(article.source.name)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    // Controls
                    HStack(spacing: 16) {
                        Button(action: {
                            // Previous article (could implement)
                        }) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                        }
                        
                        Button(action: {
                            if audioManager.isPlaying {
                                audioManager.pause()
                            } else {
                                audioManager.play()
                            }
                        }) {
                            Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.black)
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            // Next article (could implement)
                        }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                        }
                        
                        Button(action: {
                            audioManager.stop()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
            }
            .background(Color(.systemBackground))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
            .transition(.move(edge: .bottom))
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: audioManager.currentArticle)
        }
    }
}

#Preview {
    VStack {
        Spacer()
        
        // Simulate playing article
        MiniAudioPlayer()
            .onAppear {
                AudioManager.shared.currentArticle = MockData.articles[0]
                AudioManager.shared.isPlaying = true
                AudioManager.shared.playbackProgress = 0.3
            }
    }
}