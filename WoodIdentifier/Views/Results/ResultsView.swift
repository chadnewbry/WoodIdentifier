import SwiftUI

struct ResultsView: View {
    @State private var recentResults: [IdentificationResult] = []

    var body: some View {
        NavigationStack {
            if recentResults.isEmpty {
                ContentUnavailableView(
                    "No Results Yet",
                    systemImage: "leaf.fill",
                    description: Text("Take a photo of wood to see identification results here.")
                )
            } else {
                List(recentResults.flatMap(\.matches)) { match in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(match.commonName).font(.headline)
                            Spacer()
                            Text("\(Int(match.confidence * 100))%")
                                .foregroundStyle(match.confidence >= 0.7 ? .green : .orange)
                        }
                        Text(match.scientificName)
                            .font(.subheadline).italic()
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Results")
    }
}

#Preview {
    ResultsView()
}
