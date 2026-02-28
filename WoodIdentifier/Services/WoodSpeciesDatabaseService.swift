import Foundation
import SwiftData

/// Loads bundled wood species JSON into SwiftData on first launch or version update.
enum WoodSpeciesDatabaseService {
    private static let currentVersion = 1
    private static let versionKey = "WoodSpeciesDatabaseVersion"

    /// Import species from bundled JSON if needed. Call once at app launch.
    @MainActor
    static func importIfNeeded(context: ModelContext) {
        let storedVersion = UserDefaults.standard.integer(forKey: versionKey)
        guard storedVersion < currentVersion else { return }

        guard let url = Bundle.main.url(forResource: "wood_species", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return
        }

        guard let payload = try? JSONDecoder().decode(SpeciesPayload.self, from: data) else {
            return
        }

        // Clear existing species on version update
        if storedVersion > 0 {
            let existing = (try? context.fetch(FetchDescriptor<WoodSpecies>())) ?? []
            existing.forEach { context.delete($0) }
        }

        for entry in payload.species {
            let species = WoodSpecies(
                name: entry.name,
                scientificName: entry.scientificName,
                speciesDescription: entry.speciesDescription,
                category: entry.category,
                hardness: entry.hardness,
                density: entry.density,
                grainPattern: entry.grainPattern,
                colorHex: entry.colorHex,
                uses: entry.uses,
                pricing: entry.pricing,
                imageURL: entry.imageURL,
                region: entry.region,
                workability: entry.workability,
                durability: entry.durability,
                isFreeSpecies: entry.isFreeSpecies,
                workingTips: entry.workingTips,
                shrinkageRadial: entry.shrinkageRadial,
                shrinkageTangential: entry.shrinkageTangential,
                sustainability: entry.sustainability,
                confusedWith: entry.confusedWith,
                databaseVersion: payload.version
            )
            context.insert(species)
        }

        try? context.save()
        UserDefaults.standard.set(currentVersion, forKey: versionKey)
    }
}

// MARK: - JSON Decoding Types

private struct SpeciesPayload: Decodable {
    let version: Int
    let species: [SpeciesEntry]
}

private struct SpeciesEntry: Decodable {
    let name: String
    let scientificName: String
    let speciesDescription: String
    let category: String
    let hardness: Int?
    let density: Double?
    let grainPattern: String
    let colorHex: String
    let uses: String
    let pricing: String
    let imageURL: String
    let region: String
    let workability: Int
    let durability: Int
    let isFreeSpecies: Bool
    let workingTips: String
    let shrinkageRadial: Double?
    let shrinkageTangential: Double?
    let sustainability: String
    let confusedWith: String
    let databaseVersion: Int
}
