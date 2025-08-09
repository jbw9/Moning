import SwiftUI

struct ArchiveView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Archive")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Previous articles will appear here")
                    .foregroundColor(.secondary)
                    .padding()
            }
            .navigationTitle("Archive")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}