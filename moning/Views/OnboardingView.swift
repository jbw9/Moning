import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @EnvironmentObject private var dataService: SimpleDataService
    let onComplete: () -> Void
    
    @State private var selectedCategories: Set<CategoryType> = []
    @State private var currentStep = 0
    @State private var notificationsEnabled = true
    
    private let totalSteps = 3
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress bar
                    OnboardingProgressBar(currentStep: currentStep, totalSteps: totalSteps)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // Content
                    TabView(selection: $currentStep) {
                        WelcomeStep()
                            .tag(0)
                        
                        CategorySelectionStep(selectedCategories: $selectedCategories)
                            .tag(1)
                        
                        NotificationPermissionStep(notificationsEnabled: $notificationsEnabled)
                            .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentStep)
                    
                    // Navigation buttons
                    OnboardingNavigationButtons(
                        currentStep: $currentStep,
                        totalSteps: totalSteps,
                        canContinue: canContinueFromCurrentStep,
                        onComplete: completeOnboarding
                    )
                    .padding()
                }
            }
        }
    }
    
    private var canContinueFromCurrentStep: Bool {
        switch currentStep {
        case 0: return true // Welcome step
        case 1: return !selectedCategories.isEmpty // Category selection
        case 2: return true // Notification permission
        default: return false
        }
    }
    
    private func completeOnboarding() {
        // Create user preferences with selections
        var preferences = UserPreferences.default
        preferences.preferredCategories = Array(selectedCategories)
        preferences.notificationsEnabled = notificationsEnabled
        
        // Save preferences
        dataService.saveUserPreferences(preferences)
        
        // Mark onboarding as completed
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        
        // Call completion handler
        onComplete()
    }
}

// MARK: - Welcome Step

struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // App icon and name
            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Welcome to Moning")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("AI-Powered News")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Feature highlights
            VStack(alignment: .leading, spacing: 16) {
                FeatureHighlight(
                    icon: "newspaper",
                    title: "Smart News Curation",
                    description: "AI-powered summaries from 10+ tech sources"
                )
                
                FeatureHighlight(
                    icon: "speaker.wave.3",
                    title: "Audio Summaries",
                    description: "Listen to your news on the go"
                )
                
                FeatureHighlight(
                    icon: "widget.small",
                    title: "Home Screen Widgets",
                    description: "Stay updated without opening the app"
                )
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

struct FeatureHighlight: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Category Selection Step

struct CategorySelectionStep: View {
    @Binding var selectedCategories: Set<CategoryType>
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "tag.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Choose Your Interests")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Select the topics you want to stay updated on. You can change these anytime in Settings.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Category grid
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(CategoryType.allCases, id: \.self) { category in
                        OnboardingCategoryCard(
                            category: category,
                            isSelected: selectedCategories.contains(category)
                        ) {
                            toggleCategory(category)
                        }
                    }
                }
                .padding()
            }
            
            // Selection count
            if !selectedCategories.isEmpty {
                Text("\(selectedCategories.count) topic\(selectedCategories.count == 1 ? "" : "s") selected")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            // Pre-select AI and Technology as defaults
            selectedCategories = [.artificialIntelligence, .technology]
        }
    }
    
    private func toggleCategory(_ category: CategoryType) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }
}

struct OnboardingCategoryCard: View {
    let category: CategoryType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: category.iconName)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : category.color)
                
                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? category.color : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(category.color, lineWidth: isSelected ? 0 : 2)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Notification Permission Step

struct NotificationPermissionStep: View {
    @Binding var notificationsEnabled: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "bell.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Stay Informed")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Get notified about breaking news and your daily digest")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            VStack(spacing: 24) {
                NotificationBenefit(
                    icon: "newspaper",
                    title: "Daily Digest",
                    description: "Morning summary of the most important news"
                )
                
                NotificationBenefit(
                    icon: "exclamationmark.triangle",
                    title: "Breaking News",
                    description: "Immediate alerts for major developments"
                )
                
                NotificationBenefit(
                    icon: "clock",
                    title: "Perfect Timing",
                    description: "Delivered when you want them, not when we want to send them"
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 16) {
                Button {
                    notificationsEnabled = true
                    requestNotificationPermission()
                } label: {
                    Text("Enable Notifications")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                Button {
                    notificationsEnabled = false
                } label: {
                    Text("Maybe Later")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                notificationsEnabled = granted
            }
        }
    }
}

struct NotificationBenefit: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Supporting Components

struct OnboardingProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Rectangle()
                    .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                    .frame(height: 4)
                    .animation(.easeInOut, value: currentStep)
            }
        }
    }
}

struct OnboardingNavigationButtons: View {
    @Binding var currentStep: Int
    let totalSteps: Int
    let canContinue: Bool
    let onComplete: () -> Void
    
    var body: some View {
        HStack {
            if currentStep > 0 {
                Button("Back") {
                    currentStep -= 1
                }
                .foregroundColor(.blue)
            }
            
            Spacer()
            
            Button {
                if currentStep == totalSteps - 1 {
                    onComplete()
                } else if canContinue {
                    currentStep += 1
                }
            } label: {
                Text(currentStep == totalSteps - 1 ? "Get Started" : "Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(canContinue ? Color.blue : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(!canContinue)
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
        .environmentObject(SimpleDataService())
}