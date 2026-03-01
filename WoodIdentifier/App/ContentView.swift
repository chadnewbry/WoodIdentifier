import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            CameraView()
                .tabItem {
                    Label("Camera", systemImage: "camera")
                }

            ScanHistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
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
