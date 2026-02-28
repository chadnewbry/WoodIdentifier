import SwiftUI

struct CameraView: View {
    @State private var showTutorial = !UserDefaults.standard.bool(forKey: "hasSeenFirstScanTutorial")

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    Spacer()

                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)

                    Text("Camera Preview")
                        .font(.headline)
                        .padding(.top)

                    Text("Point at wood to identify species")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        // Simulate a scan
                        if showTutorial {
                            withAnimation {
                                showTutorial = false
                                UserDefaults.standard.set(true, forKey: "hasSeenFirstScanTutorial")
                            }
                        }
                    } label: {
                        Image(systemName: "camera.circle.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(.brown)
                    }
                    .padding(.bottom, 20)
                }

                FirstScanTutorialOverlay(isVisible: $showTutorial)
            }
            .navigationTitle("Scan Wood")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    CameraView()
}
