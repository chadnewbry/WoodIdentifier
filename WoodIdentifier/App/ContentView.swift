import SwiftUI

enum AppTab: Int {
    case camera, history, database, settings
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .camera

    var body: some View {
        TabView(selection: $selectedTab) {
            CameraView()
                .tabItem {
                    Label("Camera", systemImage: "camera")
                }
                .tag(AppTab.camera)

            ScanHistoryView(switchToCamera: { selectedTab = .camera })
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(AppTab.history)

            WoodDatabaseView()
                .tabItem {
                    Label("Database", systemImage: "books.vertical")
                }
                .tag(AppTab.database)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(AppTab.settings)
        }
    }
}

#Preview {
    ContentView()
}
