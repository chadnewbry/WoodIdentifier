import SwiftUI
import SwiftData

struct WoodDatabaseView: View {
    @Query(sort: \WoodSpecies.name) private var allSpecies: [WoodSpecies]
    @State private var searchText = ""

    private var filteredSpecies: [WoodSpecies] {
        if searchText.isEmpty { return allSpecies }
        return allSpecies.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.scientificName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            if allSpecies.isEmpty {
                ContentUnavailableView(
                    "Wood Database",
                    systemImage: "books.vertical",
                    description: Text("Browse and search wood species. Scan wood to start building your database.")
                )
                .navigationTitle("Database")
            } else {
                List(filteredSpecies) { species in
                    NavigationLink(destination: SpeciesDetailView(species: species)) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(hex: species.colorHex))
                                .frame(width: 36, height: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(species.name).font(.headline)
                                Text(species.scientificName)
                                    .font(.caption).italic()
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let h = species.hardness {
                                Text("\(h) lbf")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .navigationTitle("Database")
                .searchable(text: $searchText, prompt: "Search wood species")
            }
        }
    }
}

#Preview {
    WoodDatabaseView()
}
