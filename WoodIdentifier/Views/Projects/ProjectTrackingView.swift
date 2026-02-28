import SwiftUI

struct ProjectTrackingView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No Projects",
                systemImage: "hammer",
                description: Text("Track your woodworking projects here. Coming soon.")
            )
            .navigationTitle("Projects")
        }
    }
}

#Preview {
    ProjectTrackingView()
}
