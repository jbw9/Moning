//
//  moningApp.swift
//  moning
//
//  Created by Jonathan Bernard Widjajakusuma on 8/9/25.
//

import SwiftUI

@main
struct moningApp: App {
    let persistenceController = SimplePersistenceController.shared
    @StateObject private var dataService = SimpleDataService()
    
    init() {
        // Configure app launch
        setupAppConfiguration()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(dataService)
                .task {
                    await performInitialSetup()
                }
        }
    }
    
    // MARK: - App Configuration
    private func setupAppConfiguration() {
        #if DEBUG
        print("🚀 Moning AI News App - Debug Build")
        #else
        print("🚀 Moning AI News App - Release Build")
        #endif
    }
    
    // MARK: - Initial Setup
    private func performInitialSetup() async {
        // TODO: Initialize app data and services when Core Data is ready
        print("✅ App initialization completed successfully")
    }
}
