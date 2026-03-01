import SwiftUI

struct WoodOfTheDayCard: View {
    let species: WoodSpecies?

    var body: some View {
        if let species {
            NavigationLink(destination: SpeciesDetailView(species: species)) {
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color(hex: species.colorHex))
                        .frame(width: 56, height: 56)
                        .overlay {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.white.opacity(0.6))
                                .font(.title3)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("🌳 Wood of the Day")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.accent)
                        }
                        Text(species.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(species.scientificName)
                            .font(.caption)
                            .italic()
                            .foregroundStyle(.secondary)
                        if !species.speciesDescription.isEmpty {
                            Text(species.speciesDescription)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: species.colorHex).opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color(hex: species.colorHex).opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
        }
    }

    /// Deterministically pick a species based on the current day.
    static func todaysSpecies(from species: [WoodSpecies]) -> WoodSpecies? {
        guard !species.isEmpty else { return nil }
        let daysSinceEpoch = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        let index = daysSinceEpoch % species.count
        let sorted = species.sorted { $0.name < $1.name }
        return sorted[index]
    }
}
