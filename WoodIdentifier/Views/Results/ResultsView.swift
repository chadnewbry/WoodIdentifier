import SwiftUI

struct ResultsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No Results Yet",
                systemImage: "leaf.fill",
                description: Text("Take a photo of wood to see identification results here.")
            )
            .navigationTitle("Results")
        }
    }
}

#Preview {
    ResultsView()
}
