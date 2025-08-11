import SwiftUI

struct WeeklyRecapGenerationView: View {
    @EnvironmentObject private var dataService: SimpleDataService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedWeekStartDate = Calendar.current.startOfDay(for: Date().addingTimeInterval(-7*24*60*60))
    @State private var isGenerating = false
    @State private var generationStatus: RecapGenerationStatus = .pending
    @State private var generatedRecap: WeeklyRecap?
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "newspaper.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Generate Weekly Recap")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Create an AI-powered analysis of the week's most important tech developments")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Week Selection
                    WeekSelectionView(selectedDate: $selectedWeekStartDate)
                    
                    // Generation Status
                    if isGenerating {
                        GenerationProgressView(status: generationStatus)
                    } else if let recap = generatedRecap {
                        GenerationSuccessView(recap: recap, dismiss: dismiss)
                    } else if let error = errorMessage {
                        GenerationErrorView(error: error, retry: generateRecap)
                    } else {
                        // Generation Options
                        GenerationOptionsView(
                            selectedDate: selectedWeekStartDate,
                            generateAction: generateRecap
                        )
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("New Recap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func generateRecap() {
        isGenerating = true
        generationStatus = .analyzing
        errorMessage = nil
        
        Task {
            do {
                // Simulate status updates
                await MainActor.run {
                    generationStatus = .analyzing
                }
                
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                await MainActor.run {
                    generationStatus = .generating
                }
                
                // Actually generate the recap  
                let recap = try await NewsService.shared.generateWeeklyRecap(for: selectedWeekStartDate)
                
                await MainActor.run {
                    generationStatus = .completed
                    generatedRecap = recap
                    dataService.saveWeeklyRecap(recap)
                    isGenerating = false
                }
                
            } catch {
                await MainActor.run {
                    generationStatus = .failed
                    errorMessage = error.localizedDescription
                    isGenerating = false
                }
            }
        }
    }
}

// MARK: - Week Selection View
struct WeekSelectionView: View {
    @Binding var selectedDate: Date
    
    private var weekOptions: [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []
        
        // Generate last 8 weeks
        for i in 0..<8 {
            if let date = calendar.date(byAdding: .weekOfYear, value: -i, to: Date()) {
                let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
                dates.append(weekStart)
            }
        }
        
        return dates
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Week")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(weekOptions, id: \.self) { date in
                        WeekCard(
                            date: date,
                            isSelected: Calendar.current.isDate(date, equalTo: selectedDate, toGranularity: .weekOfYear)
                        )
                        .onTapGesture {
                            selectedDate = date
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct WeekCard: View {
    let date: Date
    let isSelected: Bool
    
    private var weekRange: String {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let startString = formatter.string(from: weekInterval.start)
        let endString = formatter.string(from: weekInterval.end.addingTimeInterval(-1))
        
        return "\(startString) - \(endString)"
    }
    
    private var isCurrentWeek: Bool {
        Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(weekRange)
                .font(.subheadline)
                .fontWeight(.medium)
            
            if isCurrentWeek {
                Text("This Week")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 120)
        .background(isSelected ? Color.blue : Color(.systemGray6))
        .foregroundColor(isSelected ? .white : .primary)
        .cornerRadius(10)
    }
}

// MARK: - Generation Options View
struct GenerationOptionsView: View {
    let selectedDate: Date
    let generateAction: () -> Void
    @EnvironmentObject private var dataService: SimpleDataService
    
    private var weekSummary: String {
        let calendar = Calendar.current
        let isCurrentWeek = calendar.isDate(selectedDate, equalTo: Date(), toGranularity: .weekOfYear)
        
        if isCurrentWeek {
            return "Generate a recap for this week's tech developments"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "Generate a recap for the week of \(formatter.string(from: selectedDate))"
        }
    }
    
    private var existingRecap: WeeklyRecap? {
        dataService.getWeeklyRecap(for: selectedDate)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Week Summary
            VStack(spacing: 8) {
                Text("📊 Analysis Preview")
                    .font(.headline)
                
                Text(weekSummary)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .cornerRadius(12)
            
            // Existing Recap Warning
            if let recap = existingRecap {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        
                        Text("Recap Already Exists")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                    
                    Text("A recap for this week already exists. Generating a new one will replace the existing recap.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    NavigationLink(destination: WeeklyRecapView(recap: recap)) {
                        Text("View Existing Recap")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Generation Features
            VStack(alignment: .leading, spacing: 12) {
                Text("🤖 What's Included")
                    .font(.headline)
                
                FeatureRow(icon: "brain.head.profile", title: "AI-Powered Analysis", description: "Deep analysis using OpenAI GPT-OSS-20B")
                FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Industry Trends", description: "Key themes and patterns in tech news")
                FeatureRow(icon: "flame.fill", title: "Biggest Stories", description: "Most significant developments of the week")
                FeatureRow(icon: "crystal.ball", title: "Forward Looking", description: "What to watch for next week")
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .cornerRadius(12)
            
            // Generate Button
            Button(action: generateAction) {
                HStack {
                    Image(systemName: "sparkles")
                    Text(existingRecap != nil ? "Regenerate Recap" : "Generate Recap")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Generation Progress View
struct GenerationProgressView: View {
    let status: RecapGenerationStatus
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.blue)
            
            VStack(spacing: 8) {
                Text(status.displayName)
                    .font(.headline)
                    .foregroundColor(status.color)
                
                Text(statusDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .background(Color(.systemGroupedBackground))
        .cornerRadius(16)
    }
    
    private var statusDescription: String {
        switch status {
        case .analyzing:
            return "Fetching and analyzing articles from multiple tech sources..."
        case .generating:
            return "Using AI to generate insights and structure the weekly recap..."
        default:
            return "Processing..."
        }
    }
}

// MARK: - Success View
struct GenerationSuccessView: View {
    let recap: WeeklyRecap
    let dismiss: DismissAction
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            VStack(spacing: 8) {
                Text("Recap Generated!")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Successfully analyzed \(recap.statistics.totalArticles) articles and created your weekly recap.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                NavigationLink(destination: WeeklyRecapView(recap: recap)) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("View Recap")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                Button("Done") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding(40)
        .background(Color(.systemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - Error View
struct GenerationErrorView: View {
    let error: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            VStack(spacing: 8) {
                Text("Generation Failed")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(error)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: retry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .padding(40)
        .background(Color(.systemGroupedBackground))
        .cornerRadius(16)
    }
}

#Preview {
    WeeklyRecapGenerationView()
        .environmentObject(SimpleDataService())
}