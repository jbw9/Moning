//
//  ContentView.swift
//  moning
//
//  Created by Jonathan Bernard Widjajakusuma on 8/9/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var audioManager = AudioManager.shared
    
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Image(systemName: "newspaper")
                    Text("Today")
                }
            
            ArchiveView()
                .tabItem {
                    Image(systemName: "archivebox")
                    Text("Archive")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
        }
        .safeAreaInset(edge: .bottom) {
            if audioManager.currentArticle != nil {
                MiniAudioPlayer()
            }
        }
    }
}

#Preview {
    ContentView()
}
