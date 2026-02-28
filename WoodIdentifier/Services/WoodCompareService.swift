import Foundation

/// Side-by-side comparison of two wood species.
struct WoodComparison {
    let speciesA: WoodSpecies
    let speciesB: WoodSpecies

    struct PropertyComparison {
        let label: String
        let valueA: String
        let valueB: String
        /// Positive means A is higher, negative means B is higher, nil means not comparable.
        let advantage: Int?
    }

    var comparisons: [PropertyComparison] {
        [
            PropertyComparison(
                label: "Category",
                valueA: speciesA.category,
                valueB: speciesB.category,
                advantage: nil
            ),
            PropertyComparison(
                label: "Janka Hardness",
                valueA: speciesA.hardness.map { "\($0) lbf" } ?? "N/A",
                valueB: speciesB.hardness.map { "\($0) lbf" } ?? "N/A",
                advantage: compareOptional(speciesA.hardness, speciesB.hardness)
            ),
            PropertyComparison(
                label: "Density",
                valueA: speciesA.density.map { String(format: "%.2f g/cm³", $0) } ?? "N/A",
                valueB: speciesB.density.map { String(format: "%.2f g/cm³", $0) } ?? "N/A",
                advantage: compareOptionalDouble(speciesA.density, speciesB.density)
            ),
            PropertyComparison(
                label: "Grain",
                valueA: speciesA.grainPattern,
                valueB: speciesB.grainPattern,
                advantage: nil
            ),
            PropertyComparison(
                label: "Workability",
                valueA: "\(speciesA.workability)/10",
                valueB: "\(speciesB.workability)/10",
                advantage: speciesA.workability - speciesB.workability
            ),
            PropertyComparison(
                label: "Durability",
                valueA: "\(speciesA.durability)/10",
                valueB: "\(speciesB.durability)/10",
                advantage: speciesA.durability - speciesB.durability
            ),
            PropertyComparison(
                label: "Price",
                valueA: speciesA.pricing,
                valueB: speciesB.pricing,
                advantage: speciesB.pricing.count - speciesA.pricing.count // fewer $ = advantage
            ),
            PropertyComparison(
                label: "Region",
                valueA: speciesA.region,
                valueB: speciesB.region,
                advantage: nil
            ),
            PropertyComparison(
                label: "Sustainability",
                valueA: speciesA.sustainability,
                valueB: speciesB.sustainability,
                advantage: nil
            ),
        ]
    }

    private func compareOptional(_ a: Int?, _ b: Int?) -> Int? {
        guard let a, let b else { return nil }
        return a - b
    }

    private func compareOptionalDouble(_ a: Double?, _ b: Double?) -> Int? {
        guard let a, let b else { return nil }
        if a > b { return 1 }
        if a < b { return -1 }
        return 0
    }
}

/// Service for comparing two wood species.
enum WoodCompareService {
    static func compare(_ a: WoodSpecies, _ b: WoodSpecies) -> WoodComparison {
        WoodComparison(speciesA: a, speciesB: b)
    }
}
