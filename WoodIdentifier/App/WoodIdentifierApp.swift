import SwiftUI
import SwiftData

@main
struct WoodIdentifierApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showProfileSetup = false
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    let modelContainer: ModelContainer

    init() {
        SubscriptionManager.shared.configure()

        let container = try! ModelContainer(for:
            WoodSpecies.self,
            WoodProperty.self,
            WoodProject.self,
            WoodImage.self,
            ScanResult.self
        )
        self.modelContainer = container

        #if DEBUG
        if ScreenshotSampleData.isScreenshotMode {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            UserDefaults.standard.set(true, forKey: "hasCompletedProfileSetup")
            ScreenshotSampleData.populate(container: container)
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .environmentObject(subscriptionManager)
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
    }
}
