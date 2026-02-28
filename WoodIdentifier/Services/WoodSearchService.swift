import Foundation
import SwiftData

// MARK: - Filter & Sort Options

enum WoodSortOption: String, CaseIterable, Identifiable {
    case nameAZ = "Name (A–Z)"
    case nameZA = "Name (Z–A)"
    case hardnessLow = "Hardness (Low → High)"
    case hardnessHigh = "Hardness (High → Low)"
    case priceLow = "Price (Low → High)"
    case priceHigh = "Price (High → Low)"
    case densityLow = "Density (Low → High)"
    case densityHigh = "Density (High → Low)"

    var id: String { rawValue }
}

struct WoodFilter: Equatable {
    var categories: Set<String> = []        // "hardwood", "softwood"
    var hardnessRange: ClosedRange<Int>?    // Janka range
    var densityRange: ClosedRange<Double>?
    var priceTiers: Set<String> = []
    var origins: Set<String> = []
    var sustainability: Set<String> = []
    var uses: Set<String> = []
    var colorHexes: Set<String> = []
    var freeOnly: Bool = false

    var isActive: Bool {
        !categories.isEmpty || hardnessRange != nil || densityRange != nil ||
        !priceTiers.isEmpty || !origins.isEmpty || !sustainability.isEmpty ||
        !uses.isEmpty || !colorHexes.isEmpty || freeOnly
    }
}

// MARK: - Best Wood For queries

struct WoodRecommendation {
    let query: String
    let species: [WoodSpecies]
    let reasoning: String
}

// MARK: - Search Service

@MainActor
final class WoodSearchService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Text Search

    func search(
        query: String,
        filter: WoodFilter = WoodFilter(),
        sort: WoodSortOption = .nameAZ,
        limit: Int? = nil
    ) -> [WoodSpecies] {
        var descriptor = FetchDescriptor<WoodSpecies>()

        // SwiftData predicate building
        var predicates: [Predicate<WoodSpecies>] = []

        if !query.isEmpty {
            let q = query.lowercased()
            predicates.append(#Predicate<WoodSpecies> {
                $0.commonName.localizedStandardContains(q) ||
                $0.scientificName.localizedStandardContains(q) ||
                $0.origin.localizedStandardContains(q) ||
                $0.colorDescription.localizedStandardContains(q) ||
                $0.grainPattern.localizedStandardContains(q)
            })
        }

        if filter.freeOnly {
            predicates.append(#Predicate<WoodSpecies> { $0.isFreeSpecies == true })
        }

        if !filter.categories.isEmpty {
            let cats = filter.categories
            predicates.append(#Predicate<WoodSpecies> { cats.contains($0.category) })
        }

        if let range = filter.hardnessRange {
            let lo = range.lowerBound
            let hi = range.upperBound
            predicates.append(#Predicate<WoodSpecies> {
                $0.jankaHardness >= lo && $0.jankaHardness <= hi
            })
        }

        // Combine predicates
        if let combined = predicates.first {
            var result = combined
            for p in predicates.dropFirst() {
                let prev = result
                let next = p
                result = #Predicate<WoodSpecies> {
                    prev.evaluate($0) && next.evaluate($0)
                }
            }
            descriptor.predicate = result
        }

        // Sort
        switch sort {
        case .nameAZ:
            descriptor.sortBy = [SortDescriptor(\.commonName)]
        case .nameZA:
            descriptor.sortBy = [SortDescriptor(\.commonName, order: .reverse)]
        case .hardnessLow:
            descriptor.sortBy = [SortDescriptor(\.jankaHardness)]
        case .hardnessHigh:
            descriptor.sortBy = [SortDescriptor(\.jankaHardness, order: .reverse)]
        case .priceLow:
            descriptor.sortBy = [SortDescriptor(\.priceLow)]
        case .priceHigh:
            descriptor.sortBy = [SortDescriptor(\.priceHigh, order: .reverse)]
        case .densityLow:
            descriptor.sortBy = [SortDescriptor(\.density)]
        case .densityHigh:
            descriptor.sortBy = [SortDescriptor(\.density, order: .reverse)]
        }

        if let limit {
            descriptor.fetchLimit = limit
        }

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Best Wood For

    func bestWoodFor(_ query: String) -> WoodRecommendation {
        let q = query.lowercased()

        // Keyword-based matching
        struct Criteria {
            var minDurability: Int = 0
            var minWorkability: Int = 0
            var maxPrice: Double = 999
            var categories: Set<String> = []
            var requiredUses: [String] = []
            var reasoning: String = ""
        }

        var c = Criteria()

        if q.contains("outdoor") || q.contains("deck") || q.contains("patio") || q.contains("garden") {
            c.minDurability = 4
            c.reasoning = "Outdoor use requires high durability and rot resistance."
            c.requiredUses = ["decking", "outdoor furniture", "outdoor construction", "fence posts"]
        } else if q.contains("furniture") || q.contains("table") || q.contains("chair") || q.contains("cabinet") {
            c.minWorkability = 3
            c.reasoning = "Furniture demands good workability and attractive appearance."
            c.requiredUses = ["furniture", "cabinets"]
        } else if q.contains("floor") {
            c.reasoning = "Flooring needs hardness for wear resistance."
            c.requiredUses = ["flooring"]
        } else if q.contains("carv") || q.contains("sculpt") {
            c.minWorkability = 4
            c.reasoning = "Carving requires soft, easily worked wood with fine grain."
            c.requiredUses = ["carving"]
        } else if q.contains("guitar") || q.contains("violin") || q.contains("instrument") || q.contains("music") {
            c.reasoning = "Musical instruments need specific tonal and resonance qualities."
            c.requiredUses = ["musical instruments"]
        } else if q.contains("cut") && q.contains("board") {
            c.reasoning = "Cutting boards need food-safe, hard, tight-grained wood."
            c.requiredUses = ["cutting boards"]
        } else if q.contains("boat") || q.contains("marine") {
            c.minDurability = 3
            c.reasoning = "Marine use requires excellent rot and water resistance."
            c.requiredUses = ["boat building", "marine construction"]
        } else if q.contains("turn") || q.contains("lathe") {
            c.reasoning = "Turning works best with dense, fine-grained species."
            c.requiredUses = ["turning"]
        } else if q.contains("cheap") || q.contains("budget") || q.contains("affordable") {
            c.maxPrice = 5.0
            c.reasoning = "Budget-friendly options that still perform well."
        } else {
            c.reasoning = "General-purpose recommendations based on your query."
        }

        let all = search(query: "")
        var results = all.filter { sp in
            if sp.durability < c.minDurability { return false }
            if sp.workability < c.minWorkability { return false }
            if sp.averagePrice > c.maxPrice { return false }
            if !c.categories.isEmpty && !c.categories.contains(sp.category) { return false }
            if !c.requiredUses.isEmpty {
                return sp.commonUses.contains { use in c.requiredUses.contains(use) }
            }
            return true
        }

        // Sort by best match (durability + workability + inverse price)
        results.sort { a, b in
            let scoreA = Double(a.durability + a.workability) - (a.averagePrice / 20.0)
            let scoreB = Double(b.durability + b.workability) - (b.averagePrice / 20.0)
            return scoreA > scoreB
        }

        return WoodRecommendation(
            query: query,
            species: Array(results.prefix(10)),
            reasoning: c.reasoning
        )
    }

    // MARK: - Available Filter Options

    func availableOrigins() -> [String] {
        let all = search(query: "")
        return Array(Set(all.map(\.origin))).sorted()
    }

    func availableUses() -> [String] {
        let all = search(query: "")
        return Array(Set(all.flatMap(\.commonUses))).sorted()
    }
}
