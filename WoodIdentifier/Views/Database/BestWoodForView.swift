import SwiftUI

struct WoodGuide: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let description: String
    let filterKeyword: String
}

private let guides: [WoodGuide] = [
    WoodGuide(title: "Best for Cutting Boards", icon: "knife", description: "Hard, food-safe, tight-grained woods", filterKeyword: "cutting board"),
    WoodGuide(title: "Best for Outdoor Furniture", icon: "sun.max", description: "Rot-resistant, durable species", filterKeyword: "outdoor"),
    WoodGuide(title: "Best for Flooring", icon: "square.grid.3x3", description: "Hard, stable, wear-resistant", filterKeyword: "flooring"),
    WoodGuide(title: "Best for Instruments", icon: "guitars", description: "Resonant tonewoods", filterKeyword: "instrument"),
    WoodGuide(title: "Best for Furniture", icon: "chair.lounge", description: "Workable, beautiful grain", filterKeyword: "furniture"),
    WoodGuide(title: "Best for Carving", icon: "paintbrush.pointed", description: "Soft, fine-grained, easy to shape", filterKeyword: "carving"),
]

struct BestWoodForSection: View {
    let allSpecies: [WoodSpecies]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Best Wood For...")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(guides) { guide in
                        NavigationLink(destination: GuideDetailView(guide: guide, allSpecies: allSpecies)) {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: guide.icon)
                                    .font(.title2)
                                    .foregroundStyle(.accent)
                                Text(guide.title)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                                Text(guide.description)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                            .frame(width: 150, alignment: .leading)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct GuideDetailView: View {
    let guide: WoodGuide
    let allSpecies: [WoodSpecies]

    private var rankedSpecies: [WoodSpecies] {
        allSpecies
            .filter { $0.uses.localizedCaseInsensitiveContains(guide.filterKeyword) }
            .sorted { ($0.hardness ?? 0) > ($1.hardness ?? 0) }
    }

    var body: some View {
        List {
            Section {
                Text(guide.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Recommended Species") {
                ForEach(Array(rankedSpecies.enumerated()), id: \.element.id) { index, species in
                    NavigationLink(destination: SpeciesDetailView(species: species)) {
                        HStack(spacing: 12) {
                            Text("#\(index + 1)")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .frame(width: 36)

                            Circle()
                                .fill(Color(hex: species.colorHex))
                                .frame(width: 36, height: 36)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(species.name)
                                    .font(.headline)
                                if let h = species.hardness {
                                    Text("\(h) lbf Janka")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Text(species.pricing)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(guide.title)
    }
}
