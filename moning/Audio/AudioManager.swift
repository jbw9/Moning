import Foundation
import AVFoundation
import Combine

class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()
    
    private var audioPlayer: AVAudioPlayer?
    private var speechSynthesizer: AVSpeechSynthesizer?
    private var progressTimer: Timer?
    private var isSpeechMode = false
    private var speechStartTime: Date?
    
    @Published var currentArticle: Article?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playbackProgress: Double = 0
    
    private override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func playArticle(_ article: Article) {
        // Stop current playback
        stop()
        
        currentArticle = article
        
        // For demo purposes, we'll use a sample audio file
        // In production, you'd download/stream from article.audioURL
        guard let audioPath = Bundle.main.path(forResource: "sample_news", ofType: "mp3") else {
            // If no sample file, create a synthesized speech version
            speakArticle(article)
            return
        }
        
        do {
            let audioURL = URL(fileURLWithPath: audioPath)
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.delegate = self
            
            duration = audioPlayer?.duration ?? 0
            play()
        } catch {
            // Fallback to speech synthesis
            speakArticle(article)
        }
    }
    
    private func speakArticle(_ article: Article) {
        // Use AVSpeechSynthesizer as fallback
        speechSynthesizer = AVSpeechSynthesizer()
        speechSynthesizer?.delegate = self
        
        // Create a more natural reading text
        let readableText = "\(article.title). \(article.summary). \(article.content)"
        let utterance = AVSpeechUtterance(string: readableText)
        utterance.rate = 0.52 // Slightly faster for better listening
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        // Estimate duration (more accurate calculation)
        let wordCount = readableText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        duration = TimeInterval(wordCount) * 0.35 // ~0.35 seconds per word
        
        isSpeechMode = true
        speechStartTime = Date()
        speechSynthesizer?.speak(utterance)
        isPlaying = true
        startProgressTimer()
    }
    
    func play() {
        if isSpeechMode {
            speechSynthesizer?.continueSpeaking()
            speechStartTime = Date()
        } else {
            audioPlayer?.play()
        }
        isPlaying = true
        startProgressTimer()
    }
    
    func pause() {
        if isSpeechMode {
            speechSynthesizer?.pauseSpeaking(at: .immediate)
        } else {
            audioPlayer?.pause()
        }
        isPlaying = false
        stopProgressTimer()
    }
    
    func stop() {
        if isSpeechMode {
            speechSynthesizer?.stopSpeaking(at: .immediate)
            isSpeechMode = false
            speechStartTime = nil
        } else {
            audioPlayer?.stop()
        }
        
        isPlaying = false
        currentTime = 0
        playbackProgress = 0
        currentArticle = nil
        stopProgressTimer()
    }
    
    func seek(to time: TimeInterval) {
        if isSpeechMode {
            // Speech synthesis doesn't support seeking easily
            // For now, just update the visual progress
            currentTime = time
            if duration > 0 {
                playbackProgress = time / duration
            }
        } else {
            audioPlayer?.currentTime = time
            currentTime = time
            updateProgress()
        }
    }
    
    private func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.updateProgress()
        }
    }
    
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    private func updateProgress() {
        if isSpeechMode {
            if let startTime = speechStartTime {
                currentTime = Date().timeIntervalSince(startTime)
            } else {
                currentTime += 0.1
            }
        } else {
            currentTime = audioPlayer?.currentTime ?? currentTime + 0.1
        }
        
        if duration > 0 {
            playbackProgress = min(currentTime / duration, 1.0)
        }
    }
}

extension AudioManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stop()
    }
}

extension AudioManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        speechStartTime = Date()
        isPlaying = true
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        isPlaying = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        speechStartTime = Date().addingTimeInterval(-currentTime)
        isPlaying = true
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        stop()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        stop()
    }
}