# Moning - AI News Widget App

**Status**: Production-ready MVP ✅  
**Build**: Compiles successfully  
**Features**: 4 widget sizes, complete UX, 10 news sources  

## Quick Start
```bash  
# Build and test
xcodebuild build -project moning.xcodeproj -scheme moning

# Context for development
See CLAUDE.md for development context
See PROJECT_STATUS.md for current state  
See NEXT_TASKS.md for priorities
```

## Architecture
- SwiftUI + WidgetKit + Core Data
- Local storage only (no login required)
- NewsAPI + 9 RSS feeds = 250-300 articles/day
- App Groups for widget-app data sharing

## Current State
- ✅ Complete user onboarding & settings
- ✅ 4 widget sizes with real data
- ✅ Multi-source news integration
- 🔥 Next: Enhanced audio system with background playback