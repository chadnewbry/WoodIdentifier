import SwiftUI
import SwiftData

@main
struct WoodIdentifierApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            WoodSpecies.self,
            WoodProperty.self,
            WoodProject.self,
            WoodImage.self
        ])
    }
}
