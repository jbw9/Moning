# Next Development Tasks

## 🔥 IMMEDIATE PRIORITY

### Enhanced Audio System
**Impact**: High - Core differentiator feature  
**Effort**: Medium (2-3 hours)

#### Implementation Tasks:
1. **Background Audio Session**
```swift
// Update AudioManager.swift
- Configure AVAudioSession for background playback
- Handle audio interruptions (calls, other apps)
- Maintain playback state across app lifecycle
```

2. **Control Center Integration**  
```swift
// Add MPRemoteCommandCenter support
- Play/pause, next/previous commands
- Now playing info with article titles
- Lock screen media controls
```

3. **Enhanced Playback Features**
```swift  
- Sleep timer (15/30/60 minutes)
- Skip forward/backward (15/30 seconds)
- Playback speed control (0.5x - 2x)
- Queue management for multiple articles
```

---

## 🎯 HIGH PRIORITY

### Navigation & Article Detail View
**Impact**: Medium-High - Better reading experience  
**Effort**: Medium (2-3 hours)

#### Implementation Tasks:
1. **Article Detail View**
```swift
// Create ArticleDetailView.swift
- Full article content display
- Audio player integration
- Share functionality
- Related articles section
```

2. **Deep Link Handling**
```swift
// Update ContentView.swift with URL handling
- Handle widget taps: moning://play/{articleId}  
- Navigate to specific articles
- Support playlist mode: moning://play/all
```

3. **Search Functionality**
```swift
// Add SearchView.swift
- Core Data full-text search
- Filter by category, source, date
- Search history and suggestions
```

---

## 🟡 MEDIUM PRIORITY

### Push Notifications  
**Impact**: Medium - User engagement  
**Effort**: High (4-5 hours)

```swift
// Implementation approach:
1. Local notifications for daily digest
2. Breaking news alerts (priority articles)
3. Notification categories and actions
4. Do Not Disturb integration
```

### Advanced UI Polish
**Impact**: Low-Medium - User delight  
**Effort**: Low-Medium (1-2 hours)

```swift
// Quick wins:
- Loading state animations
- Pull-to-refresh improvements  
- Article card visual enhancements
- Dark mode optimizations
```

---

## 🔮 FUTURE ENHANCEMENTS

### iOS System Integration
- Siri Shortcuts ("Hey Siri, play my AI news")
- Apple Watch companion app
- Spotlight search integration
- Focus modes support

### Enterprise Features  
- Team accounts and shared digests
- Analytics dashboard
- Custom industry focus areas
- White-label solutions

---

## ⚡ Quick Implementation Guide

### Starting Audio Enhancement Session:
```swift
1. Update moning/Audio/AudioManager.swift
2. Add AVAudioSession background capability  
3. Implement MPRemoteCommandCenter
4. Test with real device (background audio)
5. Add Control Center now playing info
```

### Starting Article Detail Session:  
```swift
1. Create moning/Views/ArticleDetailView.swift
2. Update ContentView navigation stack
3. Handle deep linking in moningApp.swift  
4. Test widget → app navigation flow
5. Add sharing and related articles
```

---

## 📋 Session Checklist

Before starting next session:
- [ ] Choose priority task (Audio System recommended)
- [ ] Read current PROJECT_STATUS.md for context
- [ ] Check build status: `xcodebuild build -project moning.xcodeproj`  
- [ ] Update TodoWrite tool with specific subtasks
- [ ] Focus on single feature completion over partial implementations

**Goal**: Ship production-ready features one at a time.