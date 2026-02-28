import SwiftUI
import SwiftData

struct WoodDatabaseView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var selectedSort: WoodSortOption = .nameAZ
    @State private var showHardwoodOnly = false
    @State private var showSoftwoodOnly = false
    @State private var showFreeOnly = false

    @Query(sort: \WoodSpecies.commonName) private var allSpecies: [WoodSpecies]

    private var filteredSpecies: [WoodSpecies] {
        var results = allSpecies

        if !searchText.isEmpty {
            let q = searchText.lowercased()
            results = results.filter {
                $0.commonName.localizedCaseInsensitiveContains(q) ||
                $0.scientificName.localizedCaseInsensitiveContains(q) ||
                $0.origin.localizedCaseInsensitiveContains(q) ||
                $0.commonUses.contains { $0.localizedCaseInsensitiveContains(q) }
            }
        }

        if showHardwoodOnly { results = results.filter { $0.category == "hardwood" } }
        if showSoftwoodOnly { results = results.filter { $0.category == "softwood" } }
        if showFreeOnly { results = results.filter { $0.isFreeSpecies } }

        switch selectedSort {
        case .nameAZ: results.sort { $0.commonName < $1.commonName }
        case .nameZA: results.sort { $0.commonName > $1.commonName }
        case .hardnessLow: results.sort { $0.jankaHardness < $1.jankaHardness }
        case .hardnessHigh: results.sort { $0.jankaHardness > $1.jankaHardness }
        case .priceLow: results.sort { $0.priceLow < $1.priceLow }
        case .priceHigh: results.sort { $0.priceHigh > $1.priceHigh }
        case .densityLow: results.sort { $0.density < $1.density }
        case .densityHigh: results.sort { $0.density > $1.density }
        }

        return results
    }

    var body: some View {
        NavigationStack {
            Group {
                if allSpecies.isEmpty {
                    ContentUnavailableView(
                        "Loading Database...",
                        systemImage: "arrow.down.circle",
                        description: Text("Wood species are being loaded.")
                    )
                } else {
                    List(filteredSpecies, id: \.id) { species in
                        NavigationLink(value: species.id) {
                            WoodSpeciesRow(species: species)
                        }
                    }
                    .navigationDestination(for: String.self) { speciesId in
                        if let species = allSpecies.first(where: { $0.id == speciesId }) {
                            WoodSpeciesDetailView(species: species)
                        }
                    }
                }
            }
            .navigationTitle("Wood Database")
            .searchable(text: $searchText, prompt: "Search \(allSpecies.count) species")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort", selection: $selectedSort) {
                            ForEach(WoodSortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        Divider()
                        Toggle("Hardwoods Only", isOn: $showHardwoodOnly)
                        Toggle("Softwoods Only", isOn: $showSoftwoodOnly)
                        Toggle("Free Species Only", isOn: $showFreeOnly)
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }
}

// MARK: - Row View

struct WoodSpeciesRow: View {
    let species: WoodSpecies

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: species.colorHex) ?? .brown)
                .frame(width: 40, height: 40)
                .overlay {
                    if !species.isFreeSpecies {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(species.commonName)
                    .font(.headline)
                Text(species.scientificName)
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(species.jankaHardness) lbf")
                    .font(.caption)
                    .fontWeight(.medium)
                Text(species.priceRangeFormatted)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Detail View

struct WoodSpeciesDetailView: View {
    let species: WoodSpecies

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Circle()
                        .fill(Color(hex: species.colorHex) ?? .brown)
                        .frame(width: 60, height: 60)
                    VStack(alignment: .leading) {
                        Text(species.commonName)
                            .font(.title)
                            .fontWeight(.bold)
                        Text(species.scientificName)
                            .font(.subheadline)
                            .italic()
                            .foregroundStyle(.secondary)
                        HStack {
                            Label(species.category.capitalized, systemImage: "leaf")
                            Label(species.origin, systemImage: "globe")
                        }
                        .font(.caption)
                    }
                }

                // Properties Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    PropertyCard(title: "Hardness", value: "\(species.jankaHardness) lbf", subtitle: species.hardnessClass)
                    PropertyCard(title: "Density", value: String(format: "%.0f lbs/ft³", species.density), subtitle: nil)
                    PropertyCard(title: "Workability", value: "\(species.workability)/5", subtitle: nil)
                    PropertyCard(title: "Durability", value: "\(species.durability)/5", subtitle: nil)
                    PropertyCard(title: "Price", value: species.priceRangeFormatted, subtitle: species.priceTier)
                    PropertyCard(title: "Sustainability", value: species.sustainability.capitalized, subtitle: nil)
                }

                // Color & Grain
                Section("Appearance") {
                    LabeledContent("Color", value: species.colorDescription)
                    LabeledContent("Grain", value: species.grainPattern)
                    LabeledContent("Shrinkage T/R", value: String(format: "%.1f%% / %.1f%% (ratio %.2f)", species.shrinkageTangential, species.shrinkageRadial, species.shrinkageRatio))
                }

                // Uses
                Section("Common Uses") {
                    FlowLayout(spacing: 8) {
                        ForEach(species.commonUses, id: \.self) { use in
                            Text(use)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.accentColor.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }

                // Working Tips
                if !species.workingTips.isEmpty {
                    Section("Working Tips") {
                        ForEach(species.workingTips, id: \.self) { tip in
                            Label(tip, systemImage: "wrench.and.screwdriver")
                                .font(.callout)
                        }
                    }
                }

                // Similar Species
                let similar = species.similarSpecies
                if !similar.isEmpty {
                    Section("Similar Species") {
                        ForEach(similar, id: \.speciesId) { sim in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(sim.species)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(sim.differences.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(species.commonName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Helper Views

struct PropertyCard: View {
    let title: String
    let value: String
    let subtitle: String?

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        guard hexSanitized.count == 6,
              let rgb = UInt64(hexSanitized, radix: 16) else { return nil }
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}

struct Section<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content
        }
    }
}

#Preview {
    WoodDatabaseView()
}
