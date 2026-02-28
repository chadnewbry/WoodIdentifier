import Foundation

/// Result from a wood identification scan.
struct WoodMatch: Identifiable, Codable, Hashable {
    let id: UUID
    let speciesId: String
    let commonName: String
    let scientificName: String
    let confidence: Double
    let hardness: Int?
    let grainPattern: String
    let typicalUses: String
    let properties: [String: String]
    let similarSpecies: [String]

    init(
        id: UUID = UUID(),
        speciesId: String,
        commonName: String,
        scientificName: String,
        confidence: Double,
        hardness: Int? = nil,
        grainPattern: String = "",
        typicalUses: String = "",
        properties: [String: String] = [:],
        similarSpecies: [String] = []
    ) {
        self.id = id
        self.speciesId = speciesId
        self.commonName = commonName
        self.scientificName = scientificName
        self.confidence = confidence
        self.hardness = hardness
        self.grainPattern = grainPattern
        self.typicalUses = typicalUses
        self.properties = properties
        self.similarSpecies = similarSpecies
    }
}

/// Metadata returned alongside identification results.
struct IdentificationResult {
    let matches: [WoodMatch]
    let isOfflineResult: Bool
    let scansRemaining: Int
}
