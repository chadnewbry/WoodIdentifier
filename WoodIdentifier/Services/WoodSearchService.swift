import Foundation
import SwiftData

/// Full-text search and filtering for wood species.
@MainActor
final class WoodSearchService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Search

    /// Full-text search across name, scientific name, uses, and description.
    func search(query: String, freeOnly: Bool = false) -> [WoodSpecies] {
        let all = fetchAll(freeOnly: freeOnly)
        guard !query.isEmpty else { return all }
        let q = query.lowercased()
        return all.filter {
            $0.name.lowercased().contains(q) ||
            $0.scientificName.lowercased().contains(q) ||
            $0.uses.lowercased().contains(q) ||
            $0.speciesDescription.lowercased().contains(q)
        }
    }

    // MARK: - Filters

    func filter(
        category: String? = nil,
        hardnessRange: ClosedRange<Int>? = nil,
        region: String? = nil,
        priceTier: String? = nil,
        useCase: String? = nil,
        colorHex: String? = nil,
        freeOnly: Bool = false
    ) -> [WoodSpecies] {
        var results = fetchAll(freeOnly: freeOnly)

        if let category {
            results = results.filter { $0.category == category }
        }
        if let hardnessRange {
            results = results.filter {
                guard let h = $0.hardness else { return false }
                return hardnessRange.contains(h)
            }
        }
        if let region {
            let r = region.lowercased()
            results = results.filter { $0.region.lowercased().contains(r) }
        }
        if let priceTier {
            results = results.filter { $0.pricing == priceTier }
        }
        if let useCase {
            let u = useCase.lowercased()
            results = results.filter { $0.uses.lowercased().contains(u) }
        }
        if let colorHex {
            results = results.filter { $0.colorHex == colorHex }
        }

        return results
    }

    // MARK: - Sorts

    enum SortOption {
        case name, hardness, density, price
    }

    func sorted(_ species: [WoodSpecies], by option: SortOption, ascending: Bool = true) -> [WoodSpecies] {
        switch option {
        case .name:
            return species.sorted { ascending ? $0.name < $1.name : $0.name > $1.name }
        case .hardness:
            return species.sorted {
                let a = $0.hardness ?? 0
                let b = $1.hardness ?? 0
                return ascending ? a < b : a > b
            }
        case .density:
            return species.sorted {
                let a = $0.density ?? 0
                let b = $1.density ?? 0
                return ascending ? a < b : a > b
            }
        case .price:
            return species.sorted {
                ascending ? $0.pricing.count < $1.pricing.count : $0.pricing.count > $1.pricing.count
            }
        }
    }

    // MARK: - Best Wood For

    /// Suggests species for a given use case, sorted by relevance (durability + workability).
    func bestWoodFor(useCase: String, freeOnly: Bool = false) -> [WoodSpecies] {
        let u = useCase.lowercased()
        let matching = fetchAll(freeOnly: freeOnly).filter {
            $0.uses.lowercased().contains(u)
        }
        return matching.sorted { ($0.durability + $0.workability) > ($1.durability + $1.workability) }
    }

    // MARK: - Private

    private func fetchAll(freeOnly: Bool) -> [WoodSpecies] {
        let descriptor = FetchDescriptor<WoodSpecies>(sortBy: [SortDescriptor(\.name)])
        let all = (try? context.fetch(descriptor)) ?? []
        if freeOnly {
            return all.filter { $0.isFreeSpecies }
        }
        return all
    }
}
