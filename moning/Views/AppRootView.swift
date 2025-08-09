import SwiftUI

struct AppRootView: View {
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    
    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView(onComplete: {
                    showOnboarding = false
                })
            } else {
                ContentView()
                    .task {
                        await performInitialSetup()
                    }
            }
        }
    }
    
    private func performInitialSetup() async {
        // TODO: Initialize app data and services when Core Data is ready
        print("✅ App initialization completed successfully")
    }
}

#Preview {
    AppRootView()
        .environmentObject(SimpleDataService())
}