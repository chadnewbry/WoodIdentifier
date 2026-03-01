import SwiftUI

struct JankaScaleView: View {
    let species: [WoodSpecies]
    @Environment(\.dismiss) private var dismiss

    private struct HardnessGroup {
        let label: String
        let example: String
        let range: ClosedRange<Int>
        let color: Color
    }

    private let groups: [HardnessGroup] = [
        .init(label: "Very Soft", example: "Balsa", range: 0...300, color: .green),
        .init(label: "Soft", example: "Pine", range: 301...700, color: .mint),
        .init(label: "Medium", example: "Walnut", range: 701...1200, color: .blue),
        .init(label: "Hard", example: "Oak", range: 1201...2000, color: .orange),
        .init(label: "Very Hard", example: "Ipe", range: 2001...5000, color: .red),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Janka Hardness Scale")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    Text("The Janka test measures the force needed to embed a steel ball into wood. Higher = harder.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    ForEach(groups, id: \.label) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Circle()
                                    .fill(group.color)
                                    .frame(width: 12, height: 12)
                                Text("\(group.label) (\(group.example))")
                                    .font(.headline)
                                Spacer()
                                Text("\(group.range.lowerBound)–\(group.range.upperBound) lbf")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            let groupSpecies = species
                                .filter { s in
                                    guard let h = s.hardness else { return false }
                                    return group.range.contains(h)
                                }
                                .sorted { ($0.hardness ?? 0) < ($1.hardness ?? 0) }

                            if groupSpecies.isEmpty {
                                Text("No species in this range")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            } else {
                                LazyVGrid(columns: [.init(.adaptive(minimum: 140))], spacing: 6) {
                                    ForEach(groupSpecies) { sp in
                                        NavigationLink(destination: SpeciesDetailView(species: sp)) {
                                            HStack(spacing: 6) {
                                                Circle()
                                                    .fill(Color(hex: sp.colorHex))
                                                    .frame(width: 20, height: 20)
                                                Text(sp.name)
                                                    .font(.caption)
                                                    .lineLimit(1)
                                                Spacer()
                                                Text("\(sp.hardness ?? 0)")
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(group.color.opacity(0.08))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Visual scale bar
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scale Overview")
                            .font(.headline)
                            .padding(.horizontal)

                        GeometryReader { geo in
                            let maxHardness: CGFloat = 5000
                            ZStack(alignment: .leading) {
                                // Background gradient
                                LinearGradient(
                                    colors: [.green, .mint, .blue, .orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(height: 24)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                                // Species markers
                                ForEach(species.filter { $0.hardness != nil }.prefix(30)) { sp in
                                    let x = CGFloat(sp.hardness!) / maxHardness * geo.size.width
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 6, height: 6)
                                        .shadow(radius: 1)
                                        .offset(x: min(max(x - 3, 0), geo.size.width - 6))
                                }
                            }
                        }
                        .frame(height: 24)
                        .padding(.horizontal)

                        HStack {
                            Text("0 lbf")
                            Spacer()
                            Text("5000 lbf")
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
