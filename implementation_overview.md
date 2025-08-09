# AI News Widget Project Plan

## Project Overview

### Goal
Create a mobile widget app that delivers AI-summarized tech/AI news with voice capabilities and interactive chat features, addressing the problem of cluttered email newsletters by providing immediate, accessible news consumption.

### Core Value Proposition
- **Immediate visibility** through mobile widgets (no need to check email)
- **Voice-first experience** for hands-free news consumption
- **Interactive follow-up** via AI chat for deeper understanding
- **Cost-effective** using open-source models and free data sources

### Target Users
- Tech professionals, developers, AI researchers
- Startup founders and tech entrepreneurs
- Anyone wanting to stay current with AI/tech without email overload

## Technical Architecture

### Backend Infrastructure
- **Cloud Platform**: AWS (utilizing $25k credits)
- **AI Model**: OpenAI gpt-oss-120b/20b running on EC2 GPU instances
- **Database**: DynamoDB for article storage, user preferences
- **API Gateway**: AWS API Gateway for mobile app endpoints
- **Storage**: S3 for audio files, summaries, cached content
- **CDN**: CloudFront for fast content delivery

### Mobile Applications
- **iOS App + Widget** (Primary Focus)
- **Native Development**: Xcode and Swift
- **WidgetKit**: For home screen and lock screen widgets
- **SwiftUI**: Modern UI framework for clean, responsive interfaces

### AI Processing Pipeline
1. **Data Collection** → **Content Processing** → **Summarization** → **Distribution**
2. **Voice Synthesis** for audio summaries
3. **Real-time Chat** for user queries

## Implementation Plan

### Phase 1: Data Collection & Processing (Weeks 1-2)
#### Data Sources Setup ✅ **RSS INTEGRATION COMPLETED**
- **RSS Feed Aggregator** ✅ **IMPLEMENTED**
  - ✅ TechCrunch, The Verge, Ars Technica, Wired, Engadget
  - ✅ VentureBeat, MIT Technology Review, 9to5Mac, TechRadar
  - ✅ Company blogs: Google AI (via RSS feeds)
  - 🔄 Research: arXiv CS.AI section (Future Phase)

- **API Integrations**
  - ✅ NewsAPI (1,000 requests/day free tier) - **ACTIVE**
  - 🔄 Reddit API for r/MachineLearning, r/artificial, r/singularity (Future Phase)
  - 🔄 Hacker News API for tech discussions (Future Phase)
  - 🔄 GitHub API for trending AI repositories (Future Phase)
  - 🔄 Twitter/X API (limited free tier) for real-time updates (Future Phase)

**Current Status**: **10 Total Data Sources** (1 API + 9 RSS Feeds) providing 250-300 articles/day

#### Backend Services ✅ **RSS SERVICE IMPLEMENTED**
- **News Aggregation Service** ✅ **Swift/iOS Implementation**
  - ✅ RSS parser with XMLParser (RSSService.swift) supporting RSS 2.0 + Atom formats
  - ✅ Concurrent fetching from 9 RSS sources with proper error handling
  - ✅ Advanced multi-source deduplication with quality-based selection
  - ✅ Intelligent content categorization (AI, startups, tech, mobile, etc.)
  - ✅ Browser-compatible headers prevent feed blocking

- **Content Processing Pipeline** ✅ **ENHANCED PROCESSING**
  - ✅ Article extraction and HTML cleaning from RSS content
  - ✅ Source reliability scoring (0.80-0.95) and article quality selection
  - ✅ Metadata extraction (publish date, source, author, categories)
  - ✅ Automatic sentiment analysis and priority detection
  - ✅ Reading time estimation and tag extraction

### Phase 2: AI Summarization System (Weeks 3-4)
#### Model Deployment
- **AWS EC2 Setup**
  - GPU instances (g5.xlarge for gpt-oss-20b, g5.2xlarge for gpt-oss-120b)
  - Model loading and inference optimization
  - Auto-scaling based on demand
  - Health monitoring and failover

#### Summarization Engine
- **Daily Digest Generation**
  - Industry-specific summaries (AI/ML, startups, hardware, policy)
  - Multi-level summaries (1-sentence, paragraph, detailed)
  - Key takeaways and trending topics identification
  - Sentiment analysis for market impact

- **Real-time Processing**
  - Breaking news detection and prioritization
  - Incremental updates throughout the day
  - User preference-based personalization

#### Voice Integration
- **Text-to-Speech Pipeline**
  - AWS Polly for voice synthesis
  - Multiple voice options and speaking speeds
  - Audio file generation and S3 storage
  - Podcast-style formatting for longer summaries
  - Standard media playback controls

### Phase 3: iOS App Development (Weeks 5-8)
#### Core iOS App (SwiftUI)
- **Authentication & Onboarding**
  - User registration and preference setup
  - Industry/topic selection with SwiftUI forms
  - Notification preferences using UserNotifications framework
  - Audio settings for voice playback

- **Main App Features**
  - **SwiftUI-based interface** with navigation and tab views
  - Daily digest viewing with expandable cards
  - **AVAudioPlayer integration** for summary playback
  - Article source linking with SFSafariViewController
  - Search and filter with Core Data integration
  - Offline reading with local storage

#### Voice Summary Playback (iOS Native)
- **AVFoundation Integration**
  - AVAudioPlayer for high-quality audio playback
  - Background audio with proper AVAudioSession configuration
  - Media controls in Control Center and lock screen
  - AirPods and CarPlay integration with MPRemoteCommandCenter

- **Audio Features**
  - Play/pause, skip between articles
  - 15-30 second skip forward/backward
  - Sleep timer with background task management
  - Audio-only mode for hands-free consumption
  - Siri Shortcuts for voice-activated news playback

#### iOS Widget Development (WidgetKit)
- **Small Widget**: Key headline + audio play button
- **Medium Widget**: 3-4 top stories with summary preview
- **Large Widget**: Detailed daily digest with audio controls
- **Lock Screen Widgets** (iOS 16+): Quick headlines and audio controls
- **Deep linking** to main app and specific articles using URL schemes

#### iOS-Specific Features
- **Siri Integration**
  - "Hey Siri, play my AI news" shortcuts
  - Custom intents for specific industry updates
  - Voice control for basic app functions

- **Apple Watch Companion**
  - Basic news headlines and summaries
  - Audio playback controls on watch
  - Handoff between iPhone and Watch

- **iOS System Integration**
  - Share Sheet for article sharing
  - Spotlight search for article content
  - Today View widget for quick access
  - Focus modes integration for work/personal news

### Phase 4: Advanced Features & Optimization (Weeks 9-12)
#### Personalization Engine
- **Machine Learning Pipeline**
  - User behavior tracking (reading time, skipped articles)
  - Preference learning and recommendation system
  - A/B testing for summary formats
  - Engagement optimization

#### Future AI Features (Post-MVP)
- **Interactive Chat**
  - Text-based follow-up questions about articles
  - Industry trend explanations and deep dives
  - Company/technology research assistance

- **Advanced Voice Chat** (Future Release)
  - Real-time conversational AI with interruption capabilities
  - Voice activity detection and streaming responses
  - Natural conversation flow with context retention
  - Perplexity-style voice interaction

- **Multi-Modal Capabilities**
  - Image analysis for charts, graphs, product images
  - Video summarization for product demos, keynotes
  - PDF processing for research papers and reports

#### Enterprise Features
- **Team Accounts**
  - Shared digests for organizations
  - Custom industry focus areas
  - Analytics dashboard for team engagement
  - White-label options for larger clients

## Technical Implementation Details

### Data Collection Architecture
```
RSS Feeds → Parser Service → Content Cleaner → Deduplicator → Database
    ↓
API Sources → Rate Limiter → Content Normalizer → Categorizer → Queue
    ↓
Social Media → Filter Service → Sentiment Analyzer → Relevance Scorer → Storage
```

### Real-time Voice Chat Architecture
*[Moved to Future Implementation - Phase 5+]*

### Basic Audio Processing Flow
```
Raw Articles → Content Extraction → Summarization Model → Quality Check → Storage
     ↓
Daily Summaries → Text-to-Speech → Audio File Generation → S3 Storage
     ↓
Widget/App Request → Audio Delivery → Media Player → User Consumption
```

### iOS App Architecture
```
WidgetKit Extension ← Shared App Group ← Core Data Store
     ↓                        ↓
SwiftUI Main App ← URL Schemes ← Deep Linking
     ↓                        ↓
AVFoundation Audio ← AWS API ← Backend Services
     ↓
Control Center/CarPlay Integration
```

## Deployment & Infrastructure

### AWS Services Utilization
- **EC2**: GPU instances for AI model hosting
- **Lambda**: Serverless functions for API endpoints
- **DynamoDB**: User data, article metadata, preferences
- **S3**: Audio files, cached summaries, static assets
- **CloudFront**: CDN for fast global content delivery
- **API Gateway**: RESTful API management
- **CloudWatch**: Monitoring and logging
- **SNS**: Push notifications
- **EventBridge**: Scheduled jobs and event processing

### Development Tools
- **Xcode**: Primary IDE for iOS development
- **Swift**: Native iOS programming language
- **SwiftUI**: Modern declarative UI framework
- **Core Data**: Local data persistence
- **WidgetKit**: Home screen widget development
- **Version Control**: Git with GitHub/GitLab
- **CI/CD**: Xcode Cloud or GitHub Actions for iOS
- **TestFlight**: Beta distribution and testing

### Security & Privacy
- **Data Encryption**: In-transit and at-rest
- **API Security**: JWT tokens, rate limiting
- **User Privacy**: Minimal data collection, GDPR compliance
- **Content Moderation**: Automated filtering for inappropriate content

## Launch Strategy

### MVP Features (Weeks 1-8)
- **Core news aggregation and AI summarization**
- **Mobile widgets with daily summaries**
- **Audio playback of summaries** (text-to-speech)
- **Basic mobile app** with reading interface
- **Standard media controls** for audio consumption

### Post-MVP Iterations
- **Week 9-12**: Advanced personalization and iOS-specific optimizations
- **Month 4**: Text-based chat for follow-up questions about articles
- **Month 5-6**: Apple Watch app and enhanced Siri integration
- **Month 7+**: Interactive voice chat and potential Android expansion

### Post-MVP Iterations
- **Week 9-12**: Advanced personalization and enterprise features
- **Month 4**: Voice chat interface and smart speaker integration
- **Month 5-6**: Multi-modal capabilities and predictive analysis
- **Month 7+**: B2B features and white-label solutions

### Success Metrics
- **User Engagement**: Daily active users, time spent in app
- **Content Quality**: User ratings, reading completion rates
- **Technical Performance**: API response times, model accuracy
- **Business Metrics**: User acquisition cost, retention rates

## Risk Mitigation

### Technical Risks
- **Model Performance**: A/B testing, fallback to API models
- **Scaling Issues**: Auto-scaling, load balancing, caching strategies
- **API Rate Limits**: Multiple data sources, graceful degradation

### Business Risks
- **Competition**: Focus on unique voice + widget combination
- **User Adoption**: Strong onboarding, clear value proposition
- **Cost Management**: Monitor AWS usage, optimize model efficiency

### Data Risks
- **Source Reliability**: Multiple redundant sources, quality scoring
- **Content Accuracy**: Human review for critical news, disclaimer text
- **Legal Compliance**: Fair use policies, proper attribution
