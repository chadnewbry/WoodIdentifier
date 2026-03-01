import SwiftUI

struct ProjectTrackingView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            if subscriptionManager.isProUser {
                ContentUnavailableView(
                    "No Projects",
                    systemImage: "hammer",
                    description: Text("Track your woodworking projects here. Coming soon.")
                )
                .navigationTitle("Projects")
            } else {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Pro Feature")
                        .font(.title2.bold())
                    Text("Project tracking and collection features require WoodSnap Pro.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Button {
                        showPaywall = true
                    } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                            Text("Upgrade to Pro")
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(.brown, in: Capsule())
                    }
                    Spacer()
                }
                .navigationTitle("Projects")
                .fullScreenCover(isPresented: $showPaywall) {
                    PaywallView(isDismissable: true)
                }
            }
        }
    }
}

#Preview {
    ProjectTrackingView()
}
