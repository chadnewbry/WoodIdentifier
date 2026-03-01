import SwiftUI

struct SpeciesGridCard: View {
    let species: WoodSpecies
    let isFree: Bool
    var isSelected: Bool = false
    var isCompareMode: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                // Grain color swatch
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: species.colorHex))
                    .frame(height: 120)
                    .overlay {
                        if !isFree {
                            ZStack {
                                Color.black.opacity(0.3)
                                VStack(spacing: 4) {
                                    Image(systemName: "lock.fill")
                                        .font(.title3)
                                    Text("PRO")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                }
                                .foregroundStyle(.white)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                // Janka badge
                if let hardness = species.hardness {
                    Text("\(hardness)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(6)
                }

                // Compare selection indicator
                if isCompareMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? .accent : .white)
                        .font(.title3)
                        .padding(8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(species.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if let hardness = species.hardness {
                    HStack(spacing: 4) {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 8))
                        Text("\(hardness) lbf")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }
}

struct SpeciesListRow: View {
    let species: WoodSpecies
    let isFree: Bool
    var isSelected: Bool = false
    var isCompareMode: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            if isCompareMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .accent : .secondary)
            }

            Circle()
                .fill(Color(hex: species.colorHex))
                .frame(width: 44, height: 44)
                .overlay {
                    if !isFree {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.white)
                    }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(species.name)
                    .font(.headline)
                Text(species.scientificName)
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Label(species.category, systemImage: "leaf")
                    if !species.region.isEmpty {
                        Label(species.region.components(separatedBy: ",").first ?? "", systemImage: "globe")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let hardness = species.hardness {
                    Text("\(hardness) lbf")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(hardnessColor(hardness).opacity(0.15))
                        .foregroundStyle(hardnessColor(hardness))
                        .clipShape(Capsule())
                }
                Text(species.pricing)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func hardnessColor(_ hardness: Int) -> Color {
        switch hardness {
        case 0...500: return .green
        case 501...1000: return .blue
        case 1001...2000: return .orange
        default: return .red
        }
    }
}
