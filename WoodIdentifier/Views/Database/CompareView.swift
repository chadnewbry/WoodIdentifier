import SwiftUI

struct CompareView: View {
    let speciesA: WoodSpecies
    let speciesB: WoodSpecies
    @Environment(\.dismiss) private var dismiss

    private var comparison: WoodComparison {
        WoodCompareService.compare(speciesA, speciesB)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with both species
                    HStack(spacing: 16) {
                        speciesHeader(speciesA)
                        Text("vs")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        speciesHeader(speciesB)
                    }
                    .padding()

                    Divider()

                    // Comparison rows
                    ForEach(comparison.comparisons, id: \.label) { prop in
                        ComparisonRow(prop: prop, nameA: speciesA.name, nameB: speciesB.name)
                    }
                    .padding(.horizontal)

                    // Visual bars for numeric properties
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Visual Comparison")
                            .font(.headline)
                            .padding(.horizontal)

                        ComparisonBar(
                            label: "Hardness",
                            valueA: Double(speciesA.hardness ?? 0),
                            valueB: Double(speciesB.hardness ?? 0),
                            maxValue: 4000,
                            nameA: speciesA.name,
                            nameB: speciesB.name
                        )

                        ComparisonBar(
                            label: "Workability",
                            valueA: Double(speciesA.workability),
                            valueB: Double(speciesB.workability),
                            maxValue: 10,
                            nameA: speciesA.name,
                            nameB: speciesB.name
                        )

                        ComparisonBar(
                            label: "Durability",
                            valueA: Double(speciesA.durability),
                            valueB: Double(speciesB.durability),
                            maxValue: 10,
                            nameA: speciesA.name,
                            nameB: speciesB.name
                        )

                        if let dA = speciesA.density, let dB = speciesB.density {
                            ComparisonBar(
                                label: "Density",
                                valueA: dA,
                                valueB: dB,
                                maxValue: 1.5,
                                nameA: speciesA.name,
                                nameB: speciesB.name
                            )
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Compare")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func speciesHeader(_ species: WoodSpecies) -> some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color(hex: species.colorHex))
                .frame(width: 60, height: 60)
            Text(species.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            Text(species.scientificName)
                .font(.caption2)
                .italic()
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ComparisonRow: View {
    let prop: WoodComparison.PropertyComparison
    let nameA: String
    let nameB: String

    var body: some View {
        VStack(spacing: 6) {
            Text(prop.label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Text(prop.valueA)
                    .font(.subheadline)
                    .fontWeight(winnerIsA ? .bold : .regular)
                    .foregroundStyle(winnerIsA ? .green : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let adv = prop.advantage {
                    Image(systemName: adv > 0 ? "arrow.left" : adv < 0 ? "arrow.right" : "equal")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(prop.valueB)
                    .font(.subheadline)
                    .fontWeight(winnerIsB ? .bold : .regular)
                    .foregroundStyle(winnerIsB ? .green : .primary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Divider()
        }
    }

    private var winnerIsA: Bool { (prop.advantage ?? 0) > 0 }
    private var winnerIsB: Bool { (prop.advantage ?? 0) < 0 }
}

struct ComparisonBar: View {
    let label: String
    let valueA: Double
    let valueB: Double
    let maxValue: Double
    let nameA: String
    let nameB: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal)

            HStack(spacing: 8) {
                Text(nameA.prefix(8))
                    .font(.caption2)
                    .frame(width: 55, alignment: .trailing)

                GeometryReader { geo in
                    let widthA = max(geo.size.width * CGFloat(valueA / maxValue), 4)
                    let widthB = max(geo.size.width * CGFloat(valueB / maxValue), 4)

                    VStack(spacing: 4) {
                        HStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(valueA >= valueB ? Color.accentColor : Color.accentColor.opacity(0.4))
                                .frame(width: widthA, height: 16)
                            Spacer(minLength: 0)
                        }
                        HStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(valueB >= valueA ? Color.orange : Color.orange.opacity(0.4))
                                .frame(width: widthB, height: 16)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .frame(height: 36)

                Text(nameB.prefix(8))
                    .font(.caption2)
                    .frame(width: 55, alignment: .leading)
            }
            .padding(.horizontal)
        }
    }
}
