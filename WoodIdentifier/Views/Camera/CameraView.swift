import SwiftUI

struct CameraView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 80))
                    .foregroundStyle(.secondary)

                Text("Take a photo of wood to identify it")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Button(action: {
                    // TODO: Implement camera capture
                }) {
                    Label("Take Photo", systemImage: "camera.fill")
                        .font(.title3)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Identify Wood")
        }
    }
}

#Preview {
    CameraView()
}
