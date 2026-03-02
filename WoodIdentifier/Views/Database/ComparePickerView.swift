import SwiftUI
import SwiftData

struct ComparePickerView: View {
    let sourceSpecies: WoodSpecies
    @Query(sort: \WoodSpecies.name) private var allSpecies: [WoodSpecies]
    @State private var searchText = ""
    @State private var selectedSpecies: WoodSpecies?
    @Environment(\.dismiss) private var dismiss

    private var filtered: [WoodSpecies] {
        let others = allSpecies.filter { $0.id != sourceSpecies.id }
        if searchText.isEmpty { return others }
        let q = searchText.lowercased()
        return others.filter {
            $0.name.lowercased().contains(q) ||
            $0.scientificName.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { species in
                Button {
                    selectedSpecies = species
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color(hex: species.colorHex))
                            .frame(width: 36, height: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(species.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            Text(species.scientificName)
                                .font(.caption)
                                .italic()
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let h = species.hardness {
                            Text("\(h) lbf")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Compare \(sourceSpecies.name) with…")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search species")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(item: $selectedSpecies) { target in
                CompareView(speciesA: sourceSpecies, speciesB: target)
            }
        }
    }
}
