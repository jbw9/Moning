# Moning AI News Widget App - Development Context

## Project Overview
**Goal**: iOS news widget app delivering AI-summarized tech/AI news with voice capabilities  
**Current Status**: Production-ready MVP with 4 widget sizes and complete user experience  
**Target**: App Store submission ready  

## Architecture
- **Frontend**: SwiftUI + WidgetKit (4 widget sizes: Small/Medium/Large/Lock Screen)
- **Backend**: Local-only (Core Data + App Groups for widget sharing)  
- **Data Sources**: NewsAPI + 9 RSS feeds = 250-300 articles/day
- **Storage**: No login required, privacy-first local storage

## Test Commands
```bash
# Build project
xcodebuild build -project moning.xcodeproj -scheme moning

# Test with iPhone 16 simulator  
xcodebuild build -project moning.xcodeproj -scheme moning -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Current File Structure
```
moning/
├── Models.swift - All data models (Article, UserPreferences, etc.)
├── CoreData/
│   ├── SimpleDataService.swift - CRUD operations for all entities
│   └── SimplePersistenceController.swift - Core Data stack
├── Services/  
│   ├── NewsService.swift - Multi-source news aggregation
│   ├── APIService.swift - NewsAPI integration
│   └── RSSService.swift - RSS parsing (9 tech sources)
├── Views/
│   ├── SettingsView.swift - Complete user preferences UI
│   ├── OnboardingView.swift - 3-step first-time user flow
│   ├── AppRootView.swift - App launch coordinator
│   └── [other views] - TodayView, ArchiveView, etc.
└── Audio/ - AudioManager.swift, MiniAudioPlayer.swift

moningWidget/
├── NewsWidget.swift - 4 widget sizes with real data integration
└── WidgetDataService.swift - Lightweight Core Data access for widgets
```

## ✅ Completed Features
- **Core Data**: 4 entities with full CRUD operations
- **Multi-source News**: NewsAPI + 9 RSS feeds with deduplication
- **Complete UX**: Onboarding → Settings → Personalized content
- **4 Widget Sizes**: Small/Medium/Large/Lock Screen with real data
- **Audio System**: Basic playback with AVFoundation + speech synthesis
- **Deep Linking**: Widget taps open app with specific articles

## 🔥 Next Priority: Enhanced Audio System
**Missing**: Background playback, Control Center integration, lock screen controls
**Files to update**: `moning/Audio/AudioManager.swift`  
**Test requirement**: Real device needed for background audio testing

## Key Implementation Notes
- **Data Flow**: RSS/API → NewsService → SimpleDataService → Core Data → Views
- **Widget Updates**: Every 2 hours via Timeline with article rotation  
- **User Preferences**: Stored in Core Data, accessed via SimpleDataService
- **App Groups**: `group.com.jonathan.moning` enables widget-app data sharing
- **Build Status**: ✅ Compiles successfully (only minor Swift 6 concurrency warnings)

## Important Constraints
- **No server dependencies** - app works completely offline after initial news fetch
- **Privacy-first** - no user tracking, all data stays on device
- **iOS 18.5+ target** - leverages latest WidgetKit and SwiftUI features

## Development Workflow
1. Read PROJECT_STATUS.md and NEXT_TASKS.md for current context
2. Choose single priority task from NEXT_TASKS.md  
3. Use TodoWrite tool to track implementation progress
4. Test build regularly with xcodebuild
5. Update PROJECT_STATUS.md when major features complete

**Current Priority**: Enhanced Audio System implementation for production-ready background playback.