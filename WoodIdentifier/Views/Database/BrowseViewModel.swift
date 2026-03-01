import Foundation
import SwiftData
import SwiftUI

// MARK: - Filter Enums

enum WoodTypeFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case hardwood = "Hardwood"
    case softwood = "Softwood"
    var id: String { rawValue }
}

enum HardnessFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case soft = "Soft"
    case medium = "Medium"
    case hard = "Hard"
    case veryHard = "Very Hard"
    var id: String { rawValue }

    var range: ClosedRange<Int>? {
        switch self {
        case .all: return nil
        case .soft: return 0...500
        case .medium: return 501...1000
        case .hard: return 1001...2000
        case .veryHard: return 2001...10000
        }
    }
}

enum RegionFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case northAmerica = "North America"
    case southAmerica = "South America"
    case europe = "Europe"
    case asia = "Asia"
    case africa = "Africa"
    case oceania = "Oceania"
    var id: String { rawValue }
}

enum PriceFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case budget = "Budget"
    case moderate = "Moderate"
    case premium = "Premium"
    case exotic = "Exotic"
    var id: String { rawValue }

    var pricingMatch: String? {
        switch self {
        case .all: return nil
        case .budget: return "$"
        case .moderate: return "$$"
        case .premium: return "$$$"
        case .exotic: return "$$$$"
        }
    }
}

enum UseFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case furniture = "Furniture"
    case flooring = "Flooring"
    case outdoor = "Outdoor"
    case instruments = "Instruments"
    case carving = "Carving"
    var id: String { rawValue }
}

enum ColorFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case light = "Light"
    case medium = "Medium"
    case dark = "Dark"
    case redToned = "Red-toned"
    var id: String { rawValue }
}

enum SortOption: String, CaseIterable, Identifiable {
    case nameAZ = "Name (A-Z)"
    case hardnessLowHigh = "Hardness (Low-High)"
    case priceLowHigh = "Price (Low-High)"
    case popularity = "Popularity"
    var id: String { rawValue }
}

enum ViewMode: String, CaseIterable {
    case grid
    case list
}

// MARK: - ViewModel

@Observable
final class BrowseViewModel {
    var searchText = ""
    var typeFilter: WoodTypeFilter = .all
    var hardnessFilter: HardnessFilter = .all
    var regionFilter: RegionFilter = .all
    var priceFilter: PriceFilter = .all
    var useFilter: UseFilter = .all
    var colorFilter: ColorFilter = .all
    var sortOption: SortOption = .nameAZ
    var viewMode: ViewMode = .grid
    var isCompareMode = false
    var compareSelections: [WoodSpecies] = []
    var showJankaScale = false
    var showCompareSheet = false
    var recentSearches: [String] = []

    private let recentSearchesKey = "BrowseRecentSearches"

    init() {
        recentSearches = UserDefaults.standard.stringArray(forKey: recentSearchesKey) ?? []
    }

    var hasActiveFilters: Bool {
        typeFilter != .all || hardnessFilter != .all || regionFilter != .all ||
        priceFilter != .all || useFilter != .all || colorFilter != .all
    }

    func clearFilters() {
        typeFilter = .all
        hardnessFilter = .all
        regionFilter = .all
        priceFilter = .all
        useFilter = .all
        colorFilter = .all
    }

    func addRecentSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        recentSearches.removeAll { $0.lowercased() == trimmed.lowercased() }
        recentSearches.insert(trimmed, at: 0)
        if recentSearches.count > 10 { recentSearches = Array(recentSearches.prefix(10)) }
        UserDefaults.standard.set(recentSearches, forKey: recentSearchesKey)
    }

    func clearRecentSearches() {
        recentSearches.removeAll()
        UserDefaults.standard.removeObject(forKey: recentSearchesKey)
    }

    func toggleCompareSelection(_ species: WoodSpecies) {
        if let idx = compareSelections.firstIndex(where: { $0.id == species.id }) {
            compareSelections.remove(at: idx)
        } else if compareSelections.count < 2 {
            compareSelections.append(species)
        }
        if compareSelections.count == 2 {
            showCompareSheet = true
        }
    }

    func filteredAndSorted(_ allSpecies: [WoodSpecies]) -> [WoodSpecies] {
        var results = allSpecies

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            results = results.filter {
                $0.name.lowercased().contains(query) ||
                $0.scientificName.lowercased().contains(query)
            }
        }

        if typeFilter != .all {
            results = results.filter { $0.category.lowercased() == typeFilter.rawValue.lowercased() }
        }

        if let range = hardnessFilter.range {
            results = results.filter { species in
                guard let h = species.hardness else { return false }
                return range.contains(h)
            }
        }

        if regionFilter != .all {
            results = results.filter { $0.region.localizedCaseInsensitiveContains(regionFilter.rawValue) }
        }

        if let match = priceFilter.pricingMatch {
            results = results.filter { $0.pricing == match }
        }

        if useFilter != .all {
            results = results.filter { $0.uses.localizedCaseInsensitiveContains(useFilter.rawValue) }
        }

        if colorFilter != .all {
            results = results.filter { species in
                let hex = species.colorHex.lowercased()
                switch colorFilter {
                case .light: return isLightColor(hex: hex)
                case .medium: return isMediumColor(hex: hex)
                case .dark: return isDarkColor(hex: hex)
                case .redToned: return isRedToned(hex: hex)
                case .all: return true
                }
            }
        }

        switch sortOption {
        case .nameAZ:
            results.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .hardnessLowHigh:
            results.sort { ($0.hardness ?? 0) < ($1.hardness ?? 0) }
        case .priceLowHigh:
            results.sort { $0.pricing.count < $1.pricing.count }
        case .popularity:
            results.sort { ($0.hardness ?? 0) > ($1.hardness ?? 0) }
        }

        return results
    }

    // MARK: - Color Helpers

    private func isLightColor(hex: String) -> Bool {
        let (r, g, b) = rgbFromHex(hex)
        return (r + g + b) / 3 > 180
    }

    private func isMediumColor(hex: String) -> Bool {
        let (r, g, b) = rgbFromHex(hex)
        let avg = (r + g + b) / 3
        return avg > 100 && avg <= 180
    }

    private func isDarkColor(hex: String) -> Bool {
        let (r, g, b) = rgbFromHex(hex)
        return (r + g + b) / 3 <= 100
    }

    private func isRedToned(hex: String) -> Bool {
        let (r, g, b) = rgbFromHex(hex)
        return r > 150 && r > g + 30 && r > b + 30
    }

    private func rgbFromHex(_ hex: String) -> (Int, Int, Int) {
        var h = hex
        if h.hasPrefix("#") { h = String(h.dropFirst()) }
        guard h.count == 6, let val = UInt64(h, radix: 16) else { return (128, 128, 128) }
        return (Int((val >> 16) & 0xFF), Int((val >> 8) & 0xFF), Int(val & 0xFF))
    }
}
