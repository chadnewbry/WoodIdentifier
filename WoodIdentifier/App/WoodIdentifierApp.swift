import SwiftUI
import SwiftData

@main
struct WoodIdentifierApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showProfileSetup = false

    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for:
                WoodSpecies.self,
                WoodProperty.self,
                WoodProject.self,
                WoodImage.self,
                ScanResult.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .sheet(isPresented: $showProfileSetup) {
                        UserProfileSetupView(isPresented: $showProfileSetup)
                    }
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .onChange(of: hasCompletedOnboarding) { _, completed in
                        if completed && !UserDefaults.standard.bool(forKey: "hasCompletedProfileSetup") {
                            showProfileSetup = true
                            UserDefaults.standard.set(true, forKey: "hasCompletedProfileSetup")
                        }
                    }
            }
        }
        .modelContainer(modelContainer)
        .task {
            await WoodDatabaseService.shared.seedIfNeeded(
                modelContext: modelContainer.mainContext
            )
        }
    }
}
