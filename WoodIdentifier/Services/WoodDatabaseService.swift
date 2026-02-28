import Foundation
import SwiftData

// MARK: - JSON Import Model

struct SpeciesJSON: Codable {
    let id: String
    let commonName: String
    let scientificName: String
    let category: String
    let jankaHardness: Int
    let hardnessClass: String
    let density: Double
    let grainPattern: String
    let color: ColorJSON
    let workability: Int
    let durability: Int
    let shrinkage: ShrinkageJSON
    let commonUses: [String]
    let bestFor: [BestForJSON]
    let pricing: PricingJSON
    let origin: String
    let sustainability: String
    let workingTips: [String]
    let similarSpecies: [SimilarJSON]
    let images: ImagesJSON
    let isFreeSpecies: Bool

    struct ColorJSON: Codable {
        let description: String
        let hex: String
    }
    struct ShrinkageJSON: Codable {
        let tangential: Double
        let radial: Double
        let ratio: Double
    }
    struct BestForJSON: Codable {
        let use: String
        let description: String
    }
    struct PricingJSON: Codable {
        let lowPerBoardFoot: Double
        let highPerBoardFoot: Double
        let tier: String
        let currency: String
    }
    struct SimilarJSON: Codable {
        let species: String
        let speciesId: String
        let differences: [String]
    }
    struct ImagesJSON: Codable {
        let grain: String?
        let endGrain: String?
        let board: String?
        let tree: String?
        let finished: String?
    }
}

struct DatabaseJSON: Codable {
    let version: String
    let generatedDate: String
    let totalSpecies: Int
    let freeSpeciesCount: Int
    let species: [SpeciesJSON]
}

// MARK: - Database Loading Service

@MainActor
final class WoodDatabaseService {
    static let shared = WoodDatabaseService()

    private let seedKey = "wood_db_seeded_version"
    private let currentVersion = "1.0.0"

    /// Seeds the database from bundled JSON on first launch or version change.
    func seedIfNeeded(modelContext: ModelContext) {
        let seededVersion = UserDefaults.standard.string(forKey: seedKey)
        guard seededVersion != currentVersion else { return }

        guard let url = Bundle.main.url(forResource: "wood_species_db", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let db = try? JSONDecoder().decode(DatabaseJSON.self, from: data) else {
            print("⚠️ Failed to load wood species database JSON")
            return
        }

        // Clear existing species on version upgrade
        if seededVersion != nil {
            let fetchDescriptor = FetchDescriptor<WoodSpecies>()
            if let existing = try? modelContext.fetch(fetchDescriptor) {
                for species in existing {
                    modelContext.delete(species)
                }
            }
        }

        let encoder = JSONEncoder()

        for s in db.species {
            let similarData = (try? encoder.encode(s.similarSpecies)) ?? Data()
            let bestForData = (try? encoder.encode(s.bestFor)) ?? Data()
            let imagesData = (try? encoder.encode(s.images)) ?? Data()

            let species = WoodSpecies(
                id: s.id,
                commonName: s.commonName,
                scientificName: s.scientificName,
                category: s.category,
                jankaHardness: s.jankaHardness,
                hardnessClass: s.hardnessClass,
                density: s.density,
                grainPattern: s.grainPattern,
                colorDescription: s.color.description,
                colorHex: s.color.hex,
                workability: s.workability,
                durability: s.durability,
                shrinkageTangential: s.shrinkage.tangential,
                shrinkageRadial: s.shrinkage.radial,
                shrinkageRatio: s.shrinkage.ratio,
                commonUses: s.commonUses,
                priceLow: s.pricing.lowPerBoardFoot,
                priceHigh: s.pricing.highPerBoardFoot,
                priceTier: s.pricing.tier,
                origin: s.origin,
                sustainability: s.sustainability,
                workingTips: s.workingTips,
                similarSpeciesJSON: String(data: similarData, encoding: .utf8) ?? "[]",
                bestForJSON: String(data: bestForData, encoding: .utf8) ?? "[]",
                imagesJSON: String(data: imagesData, encoding: .utf8) ?? "{}",
                isFreeSpecies: s.isFreeSpecies
            )
            modelContext.insert(species)
        }

        try? modelContext.save()
        UserDefaults.standard.set(currentVersion, forKey: seedKey)
        print("✅ Seeded \(db.totalSpecies) wood species (v\(currentVersion))")
    }
}
