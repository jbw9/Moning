# Moning AI News App - TODO Tracker

## 🎯 Current Status
**Frontend Progress**: 85% Complete ✅  
**Core Data**: 100% Complete ✅  
**Backend Integration**: 0% Complete  
**Widget Implementation**: 60% Complete  

---

## ✅ Completed Features

### App Architecture & UI
- [x] SwiftUI app structure with TabView navigation
- [x] Complete data models (Article, NewsSource, CategoryType, etc.)
- [x] TodayView with IndustryOverviewView and LatestArticlesView
- [x] ArchiveView and SettingsView placeholders
- [x] Audio playback system with AVFoundation + speech synthesis fallback
- [x] MiniAudioPlayer for persistent playback across app
- [x] Comprehensive mock data for development

### Widget Extension
- [x] Basic WidgetKit implementation
- [x] NewsWidget with medium size support
- [x] Deep linking support (`moning://play/` URLs)
- [x] Widget entry view with play button

### Core Data Implementation ✅ COMPLETED
- [x] **DataModel.xcdatamodeld file created and validated**
- [x] **Core Data entities defined:**
  - [x] ArticleEntity (id, title, summary, content, publishedAt, etc.)
  - [x] NewsSourceEntity (name, domain, reliability, categories)
  - [x] UserPreferencesEntity (preferredCategories, audioSettings)
  - [x] ReadingSessionEntity (articleId, startTime, duration, etc.)
- [x] **Core Data stack set up with SimplePersistenceController**
- [x] **Auto-generated NSManagedObject subclasses via Xcode**
- [x] **Data persistence layer with CRUD operations (SimpleDataService)**
- [x] **Smart fallback system: Core Data with MockData backup**
- [x] **Views updated to use real data service instead of MockData**
- [x] **App builds successfully with Core Data integration**

---

## 🔥 Critical Priority Tasks (Next Session)

### 1. API Integration Layer
**Status**: 🚨 URGENT - Replace MockData with real news
- [ ] Create APIService class for backend communication
- [ ] Implement HTTP client with URLSession
- [ ] Add request/response models for API communication
- [ ] Create news aggregation service:
  - [ ] RSS feed parser (TechCrunch, The Verge, Wired)
  - [ ] NewsAPI integration (1,000 requests/day free tier)
  - [ ] Content deduplication system
  - [ ] Article categorization logic
- [ ] Add offline caching strategy
- [ ] Implement network reachability monitoring
- [ ] **Connect SimpleDataService to real APIs instead of MockData**

### 2. Widget Data Integration
**Status**: 🚨 URGENT - Widgets still use MockData
- [ ] **Update NewsWidget to use SimpleDataService instead of MockData**
- [ ] Implement proper TimelineProvider with real article updates
- [ ] Add App Group for widget-app data sharing
- [ ] Fix widget timeline updates with real data
- [ ] Test widget functionality with Core Data

### 3. User Preferences & Settings
**Status**: 🔶 HIGH - Required for personalization
- [ ] Implement UserPreferences Core Data persistence (data layer ready)
- [ ] Create onboarding flow:
  - [ ] Welcome screen with feature introduction
  - [ ] Industry/topic selection screen
  - [ ] Notification permissions request
  - [ ] Audio settings preferences
- [ ] Complete SettingsView implementation:
  - [ ] Notification preferences (timing, categories)
  - [ ] Audio settings (voice, speed, quality)
  - [ ] Content preferences and filtering
  - [ ] Data usage controls

---

## 🎯 High Priority Tasks (Week 2)

### 4. Enhanced Widget Implementation
**Status**: 🔶 HIGH - Core feature
- [ ] Replace MockData with real Core Data integration
- [ ] Implement proper TimelineProvider with real article updates
- [ ] Add multiple widget sizes:
  - [ ] Small Widget: Single headline + audio button
  - [ ] Medium Widget: 3-4 top stories (current)
  - [ ] Large Widget: Daily digest with audio controls
- [ ] Add iOS 16+ Lock Screen widgets
- [ ] Implement widget refresh scheduling (every 1-2 hours)
- [ ] Add widget customization options

### 5. Audio System Enhancement
**Status**: 🔶 HIGH - Core feature
- [ ] Add background audio session management
- [ ] Implement Control Center integration
- [ ] Add lock screen media controls
- [ ] Support AirPods and CarPlay integration
- [ ] Add sleep timer functionality
- [ ] Implement audio-only mode
- [ ] Add 15-30 second skip forward/backward
- [ ] Create playlist functionality for multiple articles

### 6. Navigation & Deep Linking
**Status**: 🟡 MEDIUM - User experience
- [ ] Implement URL scheme handling for widget deep links
- [ ] Add proper navigation between views
- [ ] Handle article detail view navigation
- [ ] Support for external link sharing
- [ ] Add search functionality with Core Data

---

## 🔮 Medium Priority Tasks (Week 3-4)

### 7. Push Notifications
**Status**: 🟡 MEDIUM - Engagement feature
- [ ] Set up push notification certificates
- [ ] Implement notification scheduling
- [ ] Add breaking news notifications
- [ ] Create daily digest notifications
- [ ] Support notification categories and actions
- [ ] Add Do Not Disturb integration

### 8. Advanced UI Features
**Status**: 🟡 MEDIUM - Polish
- [ ] Add pull-to-refresh functionality
- [ ] Implement infinite scrolling with pagination
- [ ] Create article bookmarking/favorites
- [ ] Add reading time estimation
- [ ] Implement expandable summary levels
- [ ] Add related articles section
- [ ] Support for Dynamic Type and accessibility

### 9. Testing Infrastructure
**Status**: 🟡 MEDIUM - Quality assurance
- [ ] Write unit tests for data models
- [ ] Test network layer and API services
- [ ] Test audio playback functionality
- [ ] Test Core Data operations
- [ ] Create UI tests for main user flows
- [ ] Test widget functionality
- [ ] Achieve >80% code coverage

---

## 🌟 Future Enhancements (Post-MVP)

### iOS System Integration
- [ ] Siri Shortcuts for voice commands
- [ ] Apple Watch companion app
- [ ] Spotlight search integration
- [ ] Share Sheet integration
- [ ] Focus modes integration

### Advanced AI Features
- [ ] Text-based chat for article follow-ups
- [ ] Real-time voice chat capabilities
- [ ] Personalization engine with ML
- [ ] Sentiment analysis for articles
- [ ] Trending topics identification

### Enterprise Features
- [ ] Team accounts and shared digests
- [ ] Custom industry focus areas
- [ ] Analytics dashboard
- [ ] White-label solutions

---

## 🏗️ Backend Infrastructure (Future Phase)

### AWS Services Setup
- [ ] Lambda functions for article aggregation
- [ ] DynamoDB for article storage
- [ ] S3 bucket for audio file storage
- [ ] API Gateway endpoints
- [ ] CloudWatch logging and monitoring
- [ ] SNS for push notifications

### AI Summarization Pipeline
- [ ] Deploy AI models on AWS EC2
- [ ] Create summarization pipeline
- [ ] Implement multi-level summary generation
- [ ] Add voice synthesis (AWS Polly or custom)
- [ ] Set up scheduled data collection jobs

---

## 🚨 Technical Debt & Known Issues

1. **Empty Core Data Directory**: Critical blocker for data persistence
2. **Mock Data Dependency**: All views currently use MockData instead of real data
3. **Widget Timeline**: Currently shows static data, needs real updates
4. **Audio Session Management**: Needs background audio and Control Center integration
5. **Error Handling**: Minimal error handling throughout the app
6. **Memory Management**: Need to optimize for large article datasets
7. **Network Resilience**: Need offline mode and graceful degradation

---

## 📊 Success Metrics to Track

### Technical Metrics
- [ ] App launch time < 2 seconds
- [ ] Widget update frequency (target: every 1-2 hours)
- [ ] Audio playback latency < 500ms
- [ ] Core Data query performance
- [ ] Memory usage optimization
- [ ] Crash-free rate > 99.5%

### User Engagement Metrics
- [ ] Daily active users
- [ ] Time spent in app
- [ ] Widget interaction rate
- [ ] Audio playback completion rate
- [ ] Article reading completion rate
- [ ] User retention (Day 1, 7, 30)

---

## 📊 Technical Architecture Status

### Core Data Layer ✅ COMPLETE
- **SimplePersistenceController**: Manages Core Data stack with programmatic model creation
- **SimpleDataService**: Handles all CRUD operations with intelligent MockData fallback  
- **Auto-generated Entities**: Xcode creates entity classes from DataModel.xcdatamodeld
- **Robust Error Handling**: Gracefully falls back to MockData if Core Data fails

### Data Flow Architecture ✅ WORKING
```
Views (TodayView, IndustryOverview) 
    ↓
SimpleDataService (Data Layer)
    ↓ 
SimplePersistenceController (Core Data)
    ↓ (fallback)
MockData (Backup Data)
```

### Current File Structure
```
moning/
├── CoreData/
│   ├── SimplePersistenceController.swift ✅
│   ├── SimpleDataService.swift ✅
│   └── DataModel.xcdatamodeld/ ✅
├── Views/ (Updated to use real data)
│   ├── IndustryOverviewView.swift ✅
│   ├── LatestArticlesView.swift ✅
│   └── TodayView.swift ✅
└── moningApp.swift ✅ (Core Data integrated)
```

---

## 🎯 Next Development Session Recommendations

**Immediate Action Items (Priority Order):**

1. **API Integration** (Highest Priority)
   - Create APIService.swift for news data fetching
   - Implement RSS feed parsing for major tech news sources  
   - Connect SimpleDataService.populateInitialData() to real APIs
   - Test with 1-2 sources before expanding

2. **Widget Data Connection** (High Priority)
   - Update moningWidget/ files to use SimpleDataService
   - Add App Group entitlements for data sharing
   - Replace MockData references in widget timeline provider

3. **User Testing & Polish** (Medium Priority)
   - Test Core Data persistence across app sessions
   - Implement user preferences UI in SettingsView
   - Add error handling and loading states

**Success Criteria for Next Session:**
- Real news articles populate from RSS feeds/APIs
- Articles persist between app launches via Core Data
- Widgets show real article data instead of MockData
- App handles network failures gracefully

**Files That Need Updates Next:**
- `moningWidget/NewsWidget.swift` - Replace MockData usage
- Create `moning/API/APIService.swift` - News data fetching  
- Update `moning/Views/SettingsView.swift` - User preferences UI

---

*Last Updated: August 9, 2025 - Core Data Implementation Complete*  
*Next Review: After API Integration*  
*Build Status: ✅ Compiles Successfully*