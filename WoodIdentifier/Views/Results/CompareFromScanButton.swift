import SwiftUI
import SwiftData

/// A button that resolves a `WoodMatch` to its `WoodSpecies` in the database
/// and presents the `ComparePickerView` for side-by-side species comparison.
struct CompareFromScanButton: View {
    let match: WoodMatch
    @Query(sort: \WoodSpecies.name) private var allSpecies: [WoodSpecies]
    @State private var showComparePicker = false

    /// Find the matching `WoodSpecies` by common name or scientific name.
    private var resolvedSpecies: WoodSpecies? {
        allSpecies.first { $0.name.lowercased() == match.commonName.lowercased() }
        ?? allSpecies.first { $0.scientificName.lowercased() == match.scientificName.lowercased() }
    }

    var body: some View {
        if let species = resolvedSpecies {
            Button {
                showComparePicker = true
            } label: {
                Label("Compare Species", systemImage: "arrow.left.arrow.right")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.brown)
            }
            .sheet(isPresented: $showComparePicker) {
                ComparePickerView(sourceSpecies: species)
            }
        }
    }
}
