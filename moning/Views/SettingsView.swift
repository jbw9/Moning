import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var dataService: SimpleDataService
    @State private var editingPreferences: UserPreferences?
    @State private var showingOnboarding = false
    @State private var hasUnsavedChanges = false
    
    var body: some View {
        NavigationStack {
            Form {
                if let preferences = editingPreferences {
                    CategoryPreferencesSection(preferences: $editingPreferences)
                    AudioSettingsSection(preferences: $editingPreferences)
                    NotificationSettingsSection(preferences: $editingPreferences)
                    DataPrivacySection(preferences: $editingPreferences)
                    ReadingSettingsSection(preferences: $editingPreferences)
                    
                    if hasUnsavedChanges {
                        SaveChangesSection()
                    }
                } else {
                    ProgressView("Loading preferences...")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset") {
                        resetToDefaults()
                    }
                    .disabled(editingPreferences == nil)
                }
            }
            .onAppear {
                loadPreferences()
            }
            .onChange(of: editingPreferences) { _, _ in
                checkForChanges()
            }
        }
    }
    
    private func loadPreferences() {
        if let userPrefs = dataService.userPreferences {
            editingPreferences = userPrefs
        } else {
            // Create default preferences if none exist
            editingPreferences = UserPreferences.default
            savePreferences()
        }
    }
    
    private func savePreferences() {
        guard let preferences = editingPreferences else { return }
        dataService.saveUserPreferences(preferences)
        hasUnsavedChanges = false
    }
    
    private func resetToDefaults() {
        editingPreferences = UserPreferences.default
        savePreferences()
    }
    
    private func checkForChanges() {
        guard let editing = editingPreferences,
              let current = dataService.userPreferences else {
            hasUnsavedChanges = false
            return
        }
        
        hasUnsavedChanges = (
            editing.preferredCategories != current.preferredCategories ||
            editing.audioPlaybackSpeed != current.audioPlaybackSpeed ||
            editing.autoPlayAudio != current.autoPlayAudio ||
            editing.preferredAudioVoice != current.preferredAudioVoice ||
            editing.notificationsEnabled != current.notificationsEnabled ||
            editing.dailyDigestTime != current.dailyDigestTime ||
            editing.readingSpeed != current.readingSpeed ||
            editing.offlineModeEnabled != current.offlineModeEnabled ||
            editing.dataSaverMode != current.dataSaverMode
        )
    }
}

// MARK: - Category Preferences Section

struct CategoryPreferencesSection: View {
    @Binding var preferences: UserPreferences?
    @State private var selectedCategories: Set<CategoryType> = []
    
    var body: some View {
        Section {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(CategoryType.allCases, id: \.self) { category in
                    CategorySelectionCard(
                        category: category,
                        isSelected: selectedCategories.contains(category)
                    ) {
                        toggleCategory(category)
                    }
                }
            }
            .padding(.vertical, 8)
        } header: {
            HStack {
                Image(systemName: "tag.circle")
                Text("News Categories")
            }
        } footer: {
            Text("Select the types of news you want to see. You can change these anytime.")
        }
        .onAppear {
            if let prefs = preferences {
                selectedCategories = Set(prefs.preferredCategories)
            }
        }
    }
    
    private func toggleCategory(_ category: CategoryType) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
        
        // Update preferences
        preferences?.preferredCategories = Array(selectedCategories)
    }
}

struct CategorySelectionCard: View {
    let category: CategoryType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : category.color)
                
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? category.color : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(category.color, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Audio Settings Section

struct AudioSettingsSection: View {
    @Binding var preferences: UserPreferences?
    
    var body: some View {
        Section {
            // Playback Speed
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "speedometer")
                    Text("Playback Speed")
                    Spacer()
                    Text("\(preferences?.audioPlaybackSpeed ?? 1.0, specifier: "%.1f")x")
                        .foregroundColor(.secondary)
                }
                
                Slider(
                    value: Binding(
                        get: { preferences?.audioPlaybackSpeed ?? 1.0 },
                        set: { preferences?.audioPlaybackSpeed = $0 }
                    ),
                    in: 0.5...2.0,
                    step: 0.1
                )
            }
            
            // Auto-play Audio
            HStack {
                Image(systemName: "play.circle")
                Text("Auto-play Audio")
                Spacer()
                Toggle("", isOn: Binding(
                    get: { preferences?.autoPlayAudio ?? false },
                    set: { preferences?.autoPlayAudio = $0 }
                ))
            }
            
            // Preferred Voice
            HStack {
                Image(systemName: "speaker.wave.2")
                Text("Voice")
                Spacer()
                Menu {
                    Button("System Default") {
                        preferences?.preferredAudioVoice = "system"
                    }
                    Button("Alex") {
                        preferences?.preferredAudioVoice = "alex"
                    }
                    Button("Samantha") {
                        preferences?.preferredAudioVoice = "samantha"
                    }
                } label: {
                    Text(voiceDisplayName(preferences?.preferredAudioVoice ?? "system"))
                        .foregroundColor(.secondary)
                }
            }
            
        } header: {
            HStack {
                Image(systemName: "speaker.wave.3")
                Text("Audio Settings")
            }
        }
    }
    
    private func voiceDisplayName(_ voice: String) -> String {
        switch voice {
        case "alex": return "Alex"
        case "samantha": return "Samantha"
        default: return "System Default"
        }
    }
}

// MARK: - Notification Settings Section

struct NotificationSettingsSection: View {
    @Binding var preferences: UserPreferences?
    
    var body: some View {
        Section {
            HStack {
                Image(systemName: "bell")
                Text("Enable Notifications")
                Spacer()
                Toggle("", isOn: Binding(
                    get: { preferences?.notificationsEnabled ?? true },
                    set: { preferences?.notificationsEnabled = $0 }
                ))
            }
            
            if preferences?.notificationsEnabled == true {
                HStack {
                    Image(systemName: "clock")
                    Text("Daily Digest Time")
                    Spacer()
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { preferences?.dailyDigestTime ?? Date() },
                            set: { preferences?.dailyDigestTime = $0 }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                }
            }
            
        } header: {
            HStack {
                Image(systemName: "bell.circle")
                Text("Notifications")
            }
        }
    }
}

// MARK: - Data & Privacy Section

struct DataPrivacySection: View {
    @Binding var preferences: UserPreferences?
    
    var body: some View {
        Section {
            HStack {
                Image(systemName: "icloud.and.arrow.down")
                Text("Offline Reading")
                Spacer()
                Toggle("", isOn: Binding(
                    get: { preferences?.offlineModeEnabled ?? false },
                    set: { preferences?.offlineModeEnabled = $0 }
                ))
            }
            
            HStack {
                Image(systemName: "wifi.slash")
                Text("Data Saver Mode")
                Spacer()
                Toggle("", isOn: Binding(
                    get: { preferences?.dataSaverMode ?? false },
                    set: { preferences?.dataSaverMode = $0 }
                ))
            }
            
        } header: {
            HStack {
                Image(systemName: "shield")
                Text("Data & Privacy")
            }
        } footer: {
            Text("Data saver mode reduces image quality and disables auto-refresh to save bandwidth.")
        }
    }
}

// MARK: - Reading Settings Section

struct ReadingSettingsSection: View {
    @Binding var preferences: UserPreferences?
    
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "text.alignleft")
                    Text("Reading Speed")
                    Spacer()
                    Text("\(preferences?.readingSpeed ?? 250) WPM")
                        .foregroundColor(.secondary)
                }
                
                Slider(
                    value: Binding(
                        get: { Double(preferences?.readingSpeed ?? 250) },
                        set: { preferences?.readingSpeed = Int($0) }
                    ),
                    in: 150...400,
                    step: 25
                )
            }
            
        } header: {
            HStack {
                Image(systemName: "book")
                Text("Reading")
            }
        } footer: {
            Text("This affects estimated reading times and audio pacing.")
        }
    }
}

// MARK: - Save Changes Section

struct SaveChangesSection: View {
    @EnvironmentObject private var dataService: SimpleDataService
    @State private var isSaving = false
    
    var body: some View {
        Section {
            Button {
                Task {
                    await saveChanges()
                }
            } label: {
                HStack {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle")
                    }
                    Text(isSaving ? "Saving..." : "Save Changes")
                }
                .foregroundColor(.blue)
            }
            .disabled(isSaving)
        }
    }
    
    @MainActor
    private func saveChanges() async {
        isSaving = true
        // Add a small delay for better UX
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        isSaving = false
    }
}