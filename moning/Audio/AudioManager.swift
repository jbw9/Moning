import Foundation
import AVFoundation
import Combine
import MediaPlayer
import UIKit

class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()
    
    private var audioPlayer: AVAudioPlayer?
    private var speechSynthesizer: AVSpeechSynthesizer?
    private var progressTimer: Timer?
    private var sleepTimer: Timer?
    private var isSpeechMode = false
    private var speechStartTime: Date?
    private var wasPlayingBeforeInterruption = false
    private var articleQueue: [Article] = []
    private var currentQueueIndex = 0
    
    @Published var currentArticle: Article?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playbackProgress: Double = 0
    @Published var playbackSpeed: Float = 1.0
    @Published var sleepTimerRemaining: TimeInterval = 0
    @Published var isSleepTimerActive = false
    @Published var queueCount = 0
    @Published var hasNextArticle = false
    @Published var hasPreviousArticle = false
    
    private override init() {
        super.init()
        setupAudioSession()
        setupNotifications()
        setupRemoteCommandCenter()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Configure for background audio with spoken audio content
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.allowBluetooth, .allowAirPlay])
            try audioSession.setActive(true)
            
            print("✅ Audio session configured for background playback")
        } catch {
            print("❌ Failed to set up audio session: \(error)")
        }
    }
    
    private func setupNotifications() {
        let notificationCenter = NotificationCenter.default
        
        // Handle audio interruptions (phone calls, alarms, etc.)
        notificationCenter.addObserver(
            self,
            selector: #selector(handleAudioInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        
        // Handle route changes (headphones plugged/unplugged, Bluetooth, etc.)
        notificationCenter.addObserver(
            self,
            selector: #selector(handleAudioRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }
    
    @objc private func handleAudioInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // Audio interrupted (phone call, alarm, etc.)
            wasPlayingBeforeInterruption = isPlaying
            if isPlaying {
                pause()
            }
            
        case .ended:
            // Interruption ended
            guard let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            
            if options.contains(.shouldResume) && wasPlayingBeforeInterruption {
                // Resume playback if it should resume and was playing before
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.play()
                }
            }
            
        @unknown default:
            break
        }
    }
    
    @objc private func handleAudioRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .oldDeviceUnavailable:
            // Headphones unplugged, pause playback
            if isPlaying {
                pause()
            }
        default:
            break
        }
    }
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        
        // Pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        // Stop command
        commandCenter.stopCommand.isEnabled = true
        commandCenter.stopCommand.addTarget { [weak self] _ in
            self?.stop()
            return .success
        }
        
        // Skip forward command (15 seconds)
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            self?.skipForward(seconds: 15)
            return .success
        }
        
        // Skip backward command (15 seconds)
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            self?.skipBackward(seconds: 15)
            return .success
        }
        
        // Change playback position command
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let event = event as? MPChangePlaybackPositionCommandEvent {
                self?.seek(to: event.positionTime)
                return .success
            }
            return .commandFailed
        }
        
        // Next track command
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            return self?.playNext() == true ? .success : .commandFailed
        }
        
        // Previous track command
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            return self?.playPrevious() == true ? .success : .commandFailed
        }
        
        print("✅ Remote command center configured")
    }
    
    private func updateNowPlayingInfo() {
        guard let article = currentArticle else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: article.title,
            MPMediaItemPropertyArtist: article.source,
            MPMediaItemPropertyAlbumTitle: "AI News Summary",
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? playbackSpeed : 0.0
        ]
        
        // Add article summary as lyrics if available
        if !article.summary.isEmpty {
            nowPlayingInfo[MPMediaItemPropertyComments] = article.summary
        }
        
        // Add a default audio artwork (you could customize this with article images)
        if let image = UIImage(systemName: "waveform.circle.fill") {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func playArticle(_ article: Article, fromQueue: Bool = false) {
        // Stop current playback
        stop()
        
        // Set up queue with single article if not already in queue mode
        if !fromQueue && (articleQueue.isEmpty || !articleQueue.contains(where: { $0.id == article.id })) {
            setQueue([article])
            return // setQueue will call playArticle again
        }
        
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
        
        // Update now playing info when article changes
        updateNowPlayingInfo()
    }
    
    private func speakArticle(_ article: Article) {
        // Use AVSpeechSynthesizer as fallback
        speechSynthesizer = AVSpeechSynthesizer()
        speechSynthesizer?.delegate = self
        
        // Create a more natural reading text
        let readableText = "\(article.title). \(article.summary). \(article.content)"
        let utterance = AVSpeechUtterance(string: readableText)
        utterance.rate = 0.52 * playbackSpeed // Base rate adjusted by current speed
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        // Estimate duration (more accurate calculation, adjusted for speed)
        let wordCount = readableText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        duration = TimeInterval(wordCount) * 0.35 / TimeInterval(playbackSpeed) // Adjusted for playback speed
        
        isSpeechMode = true
        speechStartTime = Date()
        speechSynthesizer?.speak(utterance)
        isPlaying = true
        startProgressTimer()
        updateNowPlayingInfo()
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
        updateNowPlayingInfo()
        savePlaybackState()
    }
    
    func pause() {
        if isSpeechMode {
            speechSynthesizer?.pauseSpeaking(at: .immediate)
        } else {
            audioPlayer?.pause()
        }
        isPlaying = false
        stopProgressTimer()
        updateNowPlayingInfo()
        savePlaybackState()
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
        stopSleepTimer()
        updateNowPlayingInfo()
        savePlaybackState()
    }
    
    func skipForward(seconds: TimeInterval) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }
    
    func skipBackward(seconds: TimeInterval) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
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
    
    // MARK: - Sleep Timer
    func setSleepTimer(minutes: Int) {
        // Cancel existing timer
        stopSleepTimer()
        
        let duration = TimeInterval(minutes * 60)
        sleepTimerRemaining = duration
        isSleepTimerActive = true
        
        sleepTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSleepTimer()
        }
        
        print("✅ Sleep timer set for \(minutes) minutes")
    }
    
    func stopSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        sleepTimerRemaining = 0
        isSleepTimerActive = false
    }
    
    private func updateSleepTimer() {
        guard isSleepTimerActive else { return }
        
        sleepTimerRemaining -= 1
        
        if sleepTimerRemaining <= 0 {
            // Timer expired - stop playback
            DispatchQueue.main.async {
                self.stop()
                self.stopSleepTimer()
                print("😴 Sleep timer expired - stopping playback")
            }
        }
    }
    
    // MARK: - Playback Speed
    func setPlaybackSpeed(_ speed: Float) {
        playbackSpeed = max(0.5, min(speed, 2.0)) // Clamp between 0.5x and 2.0x
        
        if isSpeechMode {
            // For speech synthesis, we need to restart with new rate
            if let article = currentArticle, isPlaying {
                let currentProgress = currentTime / duration
                speechSynthesizer?.stopSpeaking(at: .immediate)
                
                // Recreate utterance with new rate
                let readableText = "\(article.title). \(article.summary). \(article.content)"
                let utterance = AVSpeechUtterance(string: readableText)
                utterance.rate = 0.52 * playbackSpeed // Base rate adjusted by speed
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                
                // Resume from current position (approximate)
                if currentProgress > 0.1 { // Skip ahead if we were significantly into the content
                    let wordsToSkip = Int(Double(readableText.components(separatedBy: .whitespacesAndNewlines).count) * currentProgress)
                    let components = readableText.components(separatedBy: .whitespacesAndNewlines)
                    if wordsToSkip < components.count {
                        let resumeText = components.dropFirst(wordsToSkip).joined(separator: " ")
                        let resumeUtterance = AVSpeechUtterance(string: resumeText)
                        resumeUtterance.rate = 0.52 * playbackSpeed
                        resumeUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                        speechSynthesizer?.speak(resumeUtterance)
                    }
                } else {
                    speechSynthesizer?.speak(utterance)
                }
            }
        } else {
            // For audio files, adjust the rate
            audioPlayer?.enableRate = true
            audioPlayer?.rate = playbackSpeed
        }
        
        updateNowPlayingInfo()
        savePlaybackState()
        print("⚡ Playback speed set to \(playbackSpeed)x")
    }
    
    // MARK: - Persistence
    private func savePlaybackState() {
        let userDefaults = UserDefaults.standard
        
        // Save current article ID if exists
        if let article = currentArticle {
            userDefaults.set(article.id.uuidString, forKey: "AudioManager_CurrentArticleID")
            userDefaults.set(currentTime, forKey: "AudioManager_CurrentTime")
            userDefaults.set(duration, forKey: "AudioManager_Duration")
        } else {
            userDefaults.removeObject(forKey: "AudioManager_CurrentArticleID")
            userDefaults.removeObject(forKey: "AudioManager_CurrentTime")
            userDefaults.removeObject(forKey: "AudioManager_Duration")
        }
        
        // Save queue state
        let articleIDs = articleQueue.map { $0.id.uuidString }
        userDefaults.set(articleIDs, forKey: "AudioManager_ArticleQueue")
        userDefaults.set(currentQueueIndex, forKey: "AudioManager_QueueIndex")
        
        // Save playback settings
        userDefaults.set(playbackSpeed, forKey: "AudioManager_PlaybackSpeed")
        
        // Save sleep timer state
        if isSleepTimerActive {
            userDefaults.set(sleepTimerRemaining, forKey: "AudioManager_SleepTimer")
        } else {
            userDefaults.removeObject(forKey: "AudioManager_SleepTimer")
        }
    }
    
    func loadPlaybackState(articles: [Article]) {
        let userDefaults = UserDefaults.standard
        
        // Load playback settings
        let savedSpeed = userDefaults.float(forKey: "AudioManager_PlaybackSpeed")
        if savedSpeed > 0 {
            playbackSpeed = savedSpeed
        }
        
        // Load queue state
        if let savedArticleIDs = userDefaults.array(forKey: "AudioManager_ArticleQueue") as? [String] {
            let savedQueue = articles.filter { savedArticleIDs.contains($0.id.uuidString) }
            if !savedQueue.isEmpty {
                articleQueue = savedQueue
                currentQueueIndex = userDefaults.integer(forKey: "AudioManager_QueueIndex")
                currentQueueIndex = max(0, min(currentQueueIndex, savedQueue.count - 1))
                updateQueueState()
            }
        }
        
        // Load current article and progress
        if let savedArticleID = userDefaults.string(forKey: "AudioManager_CurrentArticleID"),
           let savedArticle = articles.first(where: { $0.id.uuidString == savedArticleID }) {
            
            let savedTime = userDefaults.double(forKey: "AudioManager_CurrentTime")
            let savedDuration = userDefaults.double(forKey: "AudioManager_Duration")
            
            if savedTime > 0 && savedDuration > 0 {
                currentArticle = savedArticle
                currentTime = savedTime
                duration = savedDuration
                playbackProgress = savedTime / savedDuration
                
                // Don't auto-resume playback, just restore state
                updateNowPlayingInfo()
                print("📱 Restored playback state: \(savedArticle.title) at \(savedTime)s")
            }
        }
        
        // Load sleep timer state
        let savedSleepTimer = userDefaults.double(forKey: "AudioManager_SleepTimer")
        if savedSleepTimer > 0 {
            sleepTimerRemaining = savedSleepTimer
            isSleepTimerActive = true
            
            sleepTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.updateSleepTimer()
            }
        }
    }
    
    func resumePlayback() {
        guard let article = currentArticle, !isPlaying else { return }
        
        if currentTime > 0 {
            // Resume from saved position
            playArticle(article, fromQueue: true)
            seek(to: currentTime)
            print("▶️ Resumed playback from \(currentTime)s")
        }
    }
    
    // MARK: - Queue Management
    func setQueue(_ articles: [Article], startingAt index: Int = 0) {
        articleQueue = articles
        currentQueueIndex = max(0, min(index, articles.count - 1))
        updateQueueState()
        
        if !articles.isEmpty {
            playArticle(articles[currentQueueIndex], fromQueue: true)
        }
    }
    
    func addToQueue(_ articles: [Article]) {
        articleQueue.append(contentsOf: articles)
        updateQueueState()
    }
    
    func clearQueue() {
        articleQueue.removeAll()
        currentQueueIndex = 0
        updateQueueState()
    }
    
    func playNext() -> Bool {
        guard hasNextArticle else { return false }
        
        currentQueueIndex += 1
        playArticle(articleQueue[currentQueueIndex], fromQueue: true)
        updateQueueState()
        return true
    }
    
    func playPrevious() -> Bool {
        guard hasPreviousArticle else { return false }
        
        currentQueueIndex -= 1
        playArticle(articleQueue[currentQueueIndex], fromQueue: true)
        updateQueueState()
        return true
    }
    
    private func updateQueueState() {
        queueCount = articleQueue.count
        hasNextArticle = currentQueueIndex < articleQueue.count - 1
        hasPreviousArticle = currentQueueIndex > 0
    }
    
    private func playNextInQueue() {
        if hasNextArticle {
            _ = playNext()
        } else {
            // End of queue reached
            stop()
            print("📝 End of article queue reached")
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
        
        // Update now playing info with current progress
        updateNowPlayingInfo()
        
        // Save progress periodically (every 10 seconds)
        if Int(currentTime) % 10 == 0 {
            savePlaybackState()
        }
    }
}

extension AudioManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            // Successfully finished - try to play next in queue
            playNextInQueue()
        } else {
            // Error occurred - stop playback
            stop()
        }
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
        // Successfully finished - try to play next in queue
        playNextInQueue()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        stop()
    }
}