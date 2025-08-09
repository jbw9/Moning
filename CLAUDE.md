# CLAUDE.md - Moning AI News Widget App

## Project Analysis

**Current State**: Basic iOS SwiftUI project skeleton with minimal implementation
- Project name: "moning" (AI News Widget app)
- Platform: iOS native app using SwiftUI and WidgetKit
- Current files: Basic app structure with placeholder "Hello, world!" content
- Testing: Swift Testing framework for unit tests, XCTest for UI tests

**Project Goal**: Create a mobile widget app that delivers AI-summarized tech/AI news with voice capabilities and interactive chat features.

## Test Commands
```bash
# Run tests in Xcode
xcodebuild test -project moning.xcodeproj -scheme moning -destination 'platform=iOS Simulator,name=iPhone 15'

# Build project
xcodebuild build -project moning.xcodeproj -scheme moning

# Run app in simulator
open moning.xcodeproj
```

## Implementation Plan & Todo List

### Phase 1: Core App Foundation (Weeks 1-2)

#### 1.1 Project Structure Setup
- [ ] Set up proper project organization with feature-based folder structure
- [ ] Configure Core Data model for local data persistence
- [ ] Set up proper Info.plist configurations for network permissions
- [ ] Add necessary iOS frameworks (AVFoundation, WidgetKit, UserNotifications)
- [ ] Create shared App Group for widget communication
- [ ] Set up proper Swift package dependencies

#### 1.2 Data Models & Core Data
- [ ] Create Article entity with properties (id, title, summary, content, source, publishDate, audioURL, category)
- [ ] Create User entity for preferences and settings
- [ ] Create Category entity for news categorization (AI, Tech, Startups, etc.)
- [ ] Set up Core Data stack with proper configurations
- [ ] Implement data persistence layer with CRUD operations
- [ ] Add data migration strategies

#### 1.3 Network Layer
- [ ] Create APIService class for backend communication
- [ ] Implement HTTP client with proper error handling
- [ ] Create request/response models for API communication
- [ ] Add authentication layer (JWT token management)
- [ ] Implement offline caching strategy
- [ ] Add network reachability monitoring

### Phase 2: Backend Integration (Weeks 3-4)

#### 2.1 AWS Backend Setup
- [ ] Set up AWS Lambda functions for article aggregation
- [ ] Configure DynamoDB tables for article storage
- [ ] Set up S3 bucket for audio file storage
- [ ] Configure API Gateway endpoints
- [ ] Implement CloudWatch logging and monitoring
- [ ] Set up CloudFront CDN for content delivery

#### 2.2 News Data Collection
- [ ] Implement RSS feed parser for tech news sources
- [ ] Add API integrations (NewsAPI, Reddit, Hacker News)
- [ ] Create content deduplication system
- [ ] Implement article categorization logic
- [ ] Add content quality scoring
- [ ] Set up scheduled data collection jobs

#### 2.3 AI Summarization & Voice Generation
- [ ] Deploy OpenAI gpt-oss-20b model on AWS Lambda + EFS for text summarization
- [ ] Deploy XTTS-v2 model on AWS Lambda + EFS for voice synthesis
- [ ] Set up separate EFS storage for both models (gpt-oss-20b and XTTS-v2)
- [ ] Create parallel processing pipeline: text summarization + voice generation
- [ ] Implement multi-level summary generation (short, medium, detailed)
- [ ] Configure voice cloning with custom news presenter voices
- [ ] Set up streaming TTS with <150ms latency for real-time playback
- [ ] Add sentiment analysis for articles
- [ ] Create trending topics identification
- [ ] Implement personalization based on user preferences
- [ ] Configure CloudWatch events for Lambda container warming (both models)

### Phase 3: Main iOS App Development (Weeks 5-6)

#### 3.1 App Architecture & Navigation
- [ ] Replace ContentView with proper app structure
- [ ] Create TabView with main navigation (Home, Categories, Settings, Profile)
- [ ] Implement NavigationStack for article details
- [ ] Add proper state management with @StateObject and @ObservedObject
- [ ] Create ViewModels for each major feature
- [ ] Implement proper error handling and loading states

#### 3.2 Home Screen & Article List
- [ ] Create ArticleListView with daily digest
- [ ] Implement pull-to-refresh functionality
- [ ] Add infinite scrolling with pagination
- [ ] Create ArticleCardView with summary preview
- [ ] Add category filtering and search
- [ ] Implement article bookmarking/favorites

#### 3.3 Article Detail View
- [ ] Create detailed article view with full content
- [ ] Add source attribution and external links
- [ ] Implement share functionality
- [ ] Add reading time estimation
- [ ] Create expandable summary levels
- [ ] Add related articles section

#### 3.4 Audio Playback System
- [ ] Integrate AVFoundation for audio playback with XTTS-v2 generated audio
- [ ] Create AudioPlayer service with proper session management
- [ ] Implement streaming audio support for real-time TTS (<150ms latency)
- [ ] Implement media controls (play, pause, skip, speed control)
- [ ] Add background audio support for continuous news playback
- [ ] Integrate with Control Center and lock screen controls
- [ ] Support for AirPods and CarPlay integration
- [ ] Add sleep timer functionality
- [ ] Implement audio-only mode for hands-free news consumption
- [ ] Add voice speed controls (0.5x - 2x playback speed)
- [ ] Support for multiple voice personas (news anchor, conversational, etc.)

### Phase 4: Widget Development (Week 7)

#### 4.1 WidgetKit Implementation
- [ ] Create Widget Extension target
- [ ] Set up App Group for data sharing
- [ ] Implement TimelineProvider for widget updates
- [ ] Create widget configuration with IntentHandler

#### 4.2 Widget Variants
- [ ] Small Widget: Single headline with audio button
- [ ] Medium Widget: 3-4 top stories with previews
- [ ] Large Widget: Daily digest with audio controls
- [ ] Lock Screen Widgets (iOS 16+): Quick headlines
- [ ] Interactive widgets with Button controls (iOS 17+)

#### 4.3 Widget Functionality
- [ ] Deep linking to main app and specific articles
- [ ] Widget refresh scheduling and timeline management
- [ ] Audio playback controls in widgets
- [ ] Widget customization and user preferences
- [ ] Widget performance optimization

### Phase 5: User Experience & Settings (Week 8)

#### 5.1 User Onboarding
- [ ] Create welcome flow with feature introduction
- [ ] Add industry/topic selection screen
- [ ] Implement notification permissions request
- [ ] Create audio settings and preferences
- [ ] Add privacy and terms acceptance

#### 5.2 Settings & Preferences
- [ ] Create Settings screen with proper sections
- [ ] Add notification preferences (timing, categories)
- [ ] Implement audio settings (voice, speed, quality)
- [ ] Add content preferences and filtering
- [ ] Create account management features
- [ ] Add data usage and privacy controls

#### 5.3 Notifications & Alerts
- [ ] Implement push notifications for breaking news
- [ ] Add daily digest notifications
- [ ] Create notification categories and actions
- [ ] Support for notification scheduling
- [ ] Add Do Not Disturb integration

### Phase 6: Advanced Features (Weeks 9-10)

#### 6.1 Siri Integration
- [ ] Create Siri Shortcuts for voice commands
- [ ] Implement custom intents for specific actions
- [ ] Add "Hey Siri, play my AI news" functionality
- [ ] Support for voice-activated article search
- [ ] Integration with Shortcuts app

#### 6.2 Apple Watch Companion
- [ ] Create Watch Extension target
- [ ] Implement basic news headlines view
- [ ] Add audio playback controls on watch
- [ ] Support for Handoff between devices
- [ ] Watch complications for quick news access

#### 6.3 iOS System Integration
- [ ] Share Sheet integration for article sharing
- [ ] Spotlight search for article content
- [ ] Today View widget integration
- [ ] Focus modes integration
- [ ] Dynamic Type and accessibility support

### Phase 7: Testing & Quality Assurance (Week 11)

#### 7.1 Unit Testing
- [ ] Write unit tests for data models
- [ ] Test network layer and API services
- [ ] Test audio playback functionality
- [ ] Test Core Data operations
- [ ] Test business logic and view models
- [ ] Achieve >80% code coverage

#### 7.2 UI Testing
- [ ] Create UI tests for main user flows
- [ ] Test widget functionality
- [ ] Test audio playback in different scenarios
- [ ] Test accessibility features
- [ ] Performance testing and optimization

#### 7.3 Integration Testing
- [ ] Test backend integration
- [ ] Test widget-app communication
- [ ] Test push notifications
- [ ] Test offline functionality
- [ ] Cross-device testing (iPhone, iPad, Watch)

### Phase 8: Deployment & Launch Preparation (Week 12)

#### 8.1 App Store Preparation
- [ ] Create App Store Connect app record
- [ ] Design app icons and screenshots
- [ ] Write app description and keywords
- [ ] Set up App Store review guidelines compliance
- [ ] Configure TestFlight for beta testing

#### 8.2 Production Deployment
- [ ] Set up production AWS environment
- [ ] Configure monitoring and alerting
- [ ] Set up crash reporting (Crashlytics)
- [ ] Configure analytics and user tracking
- [ ] Implement feature flags for gradual rollout

#### 8.3 Launch Strategy
- [ ] Beta testing with internal users
- [ ] App Store review submission
- [ ] Marketing materials and press kit
- [ ] User documentation and help center
- [ ] Launch metrics and success tracking

### Future Enhancements (Post-MVP)

#### Text-Based Chat Integration
- [ ] Create chat interface for article follow-ups
- [ ] Implement context-aware AI responses
- [ ] Add conversation history and context
- [ ] Support for multi-turn conversations

#### Advanced Voice Features
- [ ] Real-time voice chat with interruption support
- [ ] Voice activity detection
- [ ] Streaming responses for natural conversation
- [ ] Multi-language support

#### Enterprise Features
- [ ] Team accounts and shared digests
- [ ] Custom industry focus areas
- [ ] Analytics dashboard for organizations
- [ ] White-label solutions

## Development Standards

### Code Quality
- Use SwiftUI best practices and architectural patterns
- Implement proper error handling and logging
- Follow iOS Human Interface Guidelines
- Maintain code coverage above 80%
- Use dependency injection for testability

### Performance
- Optimize for battery life and memory usage
- Implement proper caching strategies
- Use lazy loading for large data sets
- Optimize widget update frequency
- Monitor and optimize app launch time

### Security & Privacy
- Implement proper data encryption
- Follow iOS security best practices
- Minimize data collection and storage
- Provide clear privacy controls
- Regular security audits

### Accessibility
- Support Dynamic Type and font scaling
- Implement VoiceOver compatibility
- Provide proper accessibility labels
- Support for high contrast and reduced motion
- Keyboard navigation support

## Risk Mitigation

### Technical Risks
- **Model Performance**: Implement fallback mechanisms and A/B testing for both text and voice models
- **Lambda Cold Starts**: Use CloudWatch warming and optimize model loading (especially for XTTS-v2)
- **Voice Quality Consistency**: Monitor XTTS-v2 output quality and implement quality checks
- **Cost Management**: Monitor Lambda execution time for both models and optimize batch processing
- **Storage Costs**: Manage EFS storage for large model files (gpt-oss-20b + XTTS-v2)

### User Adoption
- **Onboarding**: Clear value proposition and smooth user experience
- **Engagement**: Push notifications and personalized content
- **Retention**: Regular content updates and feature improvements

### Business Risks
- **Competition**: Focus on unique voice + widget combination
- **Cost Management**: Monitor AWS usage and optimize efficiency
- **Legal Compliance**: Proper content attribution and fair use policies

## Success Metrics
- Daily active users and retention rates
- Time spent in app and widget interaction
- Audio playback completion rates
- User satisfaction scores and app store ratings
- Technical performance (crash rates, response times)