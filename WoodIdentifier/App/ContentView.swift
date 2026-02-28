import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            CameraView()
                .tabItem {
                    Label("Camera", systemImage: "camera")
                }

            ResultsView()
                .tabItem {
                    Label("Results", systemImage: "leaf.fill")
                }

            WoodDatabaseView()
                .tabItem {
                    Label("Database", systemImage: "books.vertical")
                }

            ProjectTrackingView()
                .tabItem {
                    Label("Projects", systemImage: "hammer")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
}
