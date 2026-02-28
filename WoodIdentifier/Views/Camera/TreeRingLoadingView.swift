import SwiftUI

/// Animated tree-ring loading indicator shown during identification.
struct TreeRingLoadingView: View {
    @State private var ringProgress: CGFloat = 0
    @State private var rotation: Double = 0

    private let ringCount = 5
    private let baseSize: CGFloat = 120

    var body: some View {
        ZStack {
            // Tree rings growing outward
            ForEach(0..<ringCount, id: \.self) { index in
                let delay = Double(index) * 0.15
                let size = baseSize - CGFloat(index) * 20

                Circle()
                    .stroke(
                        Color.brown.opacity(0.3 + Double(ringCount - index) * 0.12),
                        lineWidth: 3
                    )
                    .frame(width: size, height: size)
                    .scaleEffect(ringProgress)
                    .opacity(ringProgress > 0.1 ? 1 : 0)
                    .animation(
                        .easeOut(duration: 0.8).delay(delay).repeatForever(autoreverses: false),
                        value: ringProgress
                    )
            }

            // Center dot
            Circle()
                .fill(Color.brown)
                .frame(width: 8, height: 8)

            // Label
            VStack {
                Spacer().frame(height: 80)
                Text("Identifying...")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: baseSize, height: baseSize + 40)
        .onAppear { ringProgress = 1.0 }
    }
}
