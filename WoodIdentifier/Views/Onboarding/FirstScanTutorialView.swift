import SwiftUI

struct FirstScanTutorialOverlay: View {
    @Binding var isVisible: Bool
    @State private var animationOffset: CGFloat = 0

    var body: some View {
        if isVisible {
            ZStack {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    Image(systemName: "viewfinder")
                        .font(.system(size: 60))
                        .foregroundStyle(.white)
                        .offset(y: animationOffset)
                        .animation(
                            .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                            value: animationOffset
                        )

                    Text("Get Close to the Grain")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    Text("Position your camera 6–12 inches from the wood surface for the best results")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Spacer()

                    Button {
                        withAnimation {
                            isVisible = false
                            UserDefaults.standard.set(true, forKey: "hasSeenFirstScanTutorial")
                        }
                    } label: {
                        Text("Got It")
                            .font(.headline)
                            .foregroundStyle(.brown)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
            .onAppear {
                animationOffset = -10
            }
            .transition(.opacity)
        }
    }
}

#Preview {
    FirstScanTutorialOverlay(isVisible: .constant(true))
}
