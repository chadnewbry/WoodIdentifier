import Foundation

// MARK: - Comparison Result

struct WoodComparison {
    let speciesA: WoodSpecies
    let speciesB: WoodSpecies

    struct PropertyComparison {
        let name: String
        let valueA: String
        let valueB: String
        let winner: Winner?

        enum Winner {
            case a, b, tie
        }
    }

    var comparisons: [PropertyComparison] {
        var result: [PropertyComparison] = []

        result.append(PropertyComparison(
            name: "Category",
            valueA: speciesA.category.capitalized,
            valueB: speciesB.category.capitalized,
            winner: nil
        ))

        result.append(PropertyComparison(
            name: "Janka Hardness",
            valueA: "\(speciesA.jankaHardness) lbf",
            valueB: "\(speciesB.jankaHardness) lbf",
            winner: speciesA.jankaHardness == speciesB.jankaHardness ? .tie :
                    speciesA.jankaHardness > speciesB.jankaHardness ? .a : .b
        ))

        result.append(PropertyComparison(
            name: "Density",
            valueA: String(format: "%.0f lbs/ft³", speciesA.density),
            valueB: String(format: "%.0f lbs/ft³", speciesB.density),
            winner: speciesA.density == speciesB.density ? .tie :
                    speciesA.density > speciesB.density ? .a : .b
        ))

        result.append(PropertyComparison(
            name: "Workability",
            valueA: "\(speciesA.workability)/5",
            valueB: "\(speciesB.workability)/5",
            winner: speciesA.workability == speciesB.workability ? .tie :
                    speciesA.workability > speciesB.workability ? .a : .b
        ))

        result.append(PropertyComparison(
            name: "Durability",
            valueA: "\(speciesA.durability)/5",
            valueB: "\(speciesB.durability)/5",
            winner: speciesA.durability == speciesB.durability ? .tie :
                    speciesA.durability > speciesB.durability ? .a : .b
        ))

        result.append(PropertyComparison(
            name: "Price Range",
            valueA: speciesA.priceRangeFormatted,
            valueB: speciesB.priceRangeFormatted,
            winner: speciesA.averagePrice == speciesB.averagePrice ? .tie :
                    speciesA.averagePrice < speciesB.averagePrice ? .a : .b
        ))

        result.append(PropertyComparison(
            name: "Grain Pattern",
            valueA: speciesA.grainPattern,
            valueB: speciesB.grainPattern,
            winner: nil
        ))

        result.append(PropertyComparison(
            name: "Color",
            valueA: speciesA.colorDescription,
            valueB: speciesB.colorDescription,
            winner: nil
        ))

        result.append(PropertyComparison(
            name: "Origin",
            valueA: speciesA.origin,
            valueB: speciesB.origin,
            winner: nil
        ))

        result.append(PropertyComparison(
            name: "Sustainability",
            valueA: speciesA.sustainability.capitalized,
            valueB: speciesB.sustainability.capitalized,
            winner: nil
        ))

        result.append(PropertyComparison(
            name: "Tangential Shrinkage",
            valueA: String(format: "%.1f%%", speciesA.shrinkageTangential),
            valueB: String(format: "%.1f%%", speciesB.shrinkageTangential),
            winner: speciesA.shrinkageTangential == speciesB.shrinkageTangential ? .tie :
                    speciesA.shrinkageTangential < speciesB.shrinkageTangential ? .a : .b
        ))

        result.append(PropertyComparison(
            name: "Radial Shrinkage",
            valueA: String(format: "%.1f%%", speciesA.shrinkageRadial),
            valueB: String(format: "%.1f%%", speciesB.shrinkageRadial),
            winner: speciesA.shrinkageRadial == speciesB.shrinkageRadial ? .tie :
                    speciesA.shrinkageRadial < speciesB.shrinkageRadial ? .a : .b
        ))

        return result
    }

    var sharedUses: [String] {
        let setA = Set(speciesA.commonUses)
        let setB = Set(speciesB.commonUses)
        return Array(setA.intersection(setB)).sorted()
    }

    var uniqueUsesA: [String] {
        let setB = Set(speciesB.commonUses)
        return speciesA.commonUses.filter { !setB.contains($0) }
    }

    var uniqueUsesB: [String] {
        let setA = Set(speciesA.commonUses)
        return speciesB.commonUses.filter { !setA.contains($0) }
    }

    /// Quick summary of which species is better for what
    var summary: String {
        var advantages: [String] = []
        if speciesA.durability > speciesB.durability {
            advantages.append("\(speciesA.commonName) is more durable")
        } else if speciesB.durability > speciesA.durability {
            advantages.append("\(speciesB.commonName) is more durable")
        }
        if speciesA.workability > speciesB.workability {
            advantages.append("\(speciesA.commonName) is easier to work")
        } else if speciesB.workability > speciesA.workability {
            advantages.append("\(speciesB.commonName) is easier to work")
        }
        if speciesA.averagePrice < speciesB.averagePrice {
            advantages.append("\(speciesA.commonName) is more affordable")
        } else if speciesB.averagePrice < speciesA.averagePrice {
            advantages.append("\(speciesB.commonName) is more affordable")
        }
        return advantages.joined(separator: ". ") + "."
    }
}

// MARK: - Compare Service

final class WoodCompareService {
    func compare(_ a: WoodSpecies, _ b: WoodSpecies) -> WoodComparison {
        WoodComparison(speciesA: a, speciesB: b)
    }
}
