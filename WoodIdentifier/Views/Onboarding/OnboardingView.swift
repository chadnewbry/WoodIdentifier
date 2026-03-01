import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var showPaywall = false

    var body: some View {
        TabView(selection: $currentPage) {
            OnboardingPageView(
                systemImage: "camera.viewfinder",
                title: "Snap Any Wood",
                description: "Point your camera at any wood surface and instantly identify the species from its grain pattern.",
                accentColor: .brown
            ) {
                withAnimation { currentPage = 1 }
            }
            .tag(0)

            OnboardingPageView(
                systemImage: "sparkles",
                title: "Get Instant ID",
                description: "Our AI analyzes grain patterns, color, and texture to identify wood species with confidence scores and detailed properties.",
                accentColor: Color(red: 0.2, green: 0.5, blue: 0.3)
            ) {
                withAnimation { currentPage = 2 }
            }
            .tag(1)

            OnboardingPageView(
                systemImage: "books.vertical.fill",
                title: "Explore 200+ Species",
                description: "Browse our comprehensive wood database with detailed profiles, filtering by hardness, origin, color, and common uses.",
                accentColor: Color(red: 0.4, green: 0.3, blue: 0.2)
            ) {
                completeOnboarding()
            }
            .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .overlay(alignment: .topTrailing) {
            Button("Skip") {
                completeOnboarding()
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
            .padding()
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(isDismissable: true)
                .onDisappear {
                    finishOnboarding()
                }
        }
    }

    private func completeOnboarding() {
        showPaywall = true
    }

    private func finishOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

struct OnboardingPageView: View {
    let systemImage: String
    let title: String
    let description: String
    let accentColor: Color
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: systemImage)
                .font(.system(size: 80))
                .foregroundStyle(accentColor)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 12) {
                Text(title)
                    .font(.largeTitle.bold())

                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(accentColor)
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
