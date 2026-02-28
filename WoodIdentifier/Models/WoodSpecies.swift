import Foundation
import SwiftData

@Model
final class WoodSpecies {
    @Attribute(.unique) var id: String
    var commonName: String
    var scientificName: String
    var category: String
    var jankaHardness: Int
    var hardnessClass: String
    var density: Double
    var grainPattern: String
    var colorDescription: String
    var colorHex: String
    var workability: Int
    var durability: Int
    var shrinkageTangential: Double
    var shrinkageRadial: Double
    var shrinkageRatio: Double
    var commonUses: [String]
    var priceLow: Double
    var priceHigh: Double
    var priceTier: String
    var origin: String
    var sustainability: String
    var workingTips: [String]
    var similarSpeciesJSON: String // Store as JSON string for simplicity
    var bestForJSON: String
    var imagesJSON: String
    var isFreeSpecies: Bool

    @Relationship(deleteRule: .cascade, inverse: \WoodProperty.species)
    var properties: [WoodProperty] = []

    @Relationship(deleteRule: .cascade, inverse: \WoodImage.associatedSpecies)
    var images: [WoodImage] = []

    @Relationship(inverse: \WoodProject.woodSpecies)
    var projects: [WoodProject] = []

    init(
        id: String = "",
        commonName: String = "",
        scientificName: String = "",
        category: String = "hardwood",
        jankaHardness: Int = 0,
        hardnessClass: String = "",
        density: Double = 0,
        grainPattern: String = "",
        colorDescription: String = "",
        colorHex: String = "",
        workability: Int = 3,
        durability: Int = 3,
        shrinkageTangential: Double = 0,
        shrinkageRadial: Double = 0,
        shrinkageRatio: Double = 0,
        commonUses: [String] = [],
        priceLow: Double = 0,
        priceHigh: Double = 0,
        priceTier: String = "",
        origin: String = "",
        sustainability: String = "",
        workingTips: [String] = [],
        similarSpeciesJSON: String = "[]",
        bestForJSON: String = "[]",
        imagesJSON: String = "{}",
        isFreeSpecies: Bool = false
    ) {
        self.id = id
        self.commonName = commonName
        self.scientificName = scientificName
        self.category = category
        self.jankaHardness = jankaHardness
        self.hardnessClass = hardnessClass
        self.density = density
        self.grainPattern = grainPattern
        self.colorDescription = colorDescription
        self.colorHex = colorHex
        self.workability = workability
        self.durability = durability
        self.shrinkageTangential = shrinkageTangential
        self.shrinkageRadial = shrinkageRadial
        self.shrinkageRatio = shrinkageRatio
        self.commonUses = commonUses
        self.priceLow = priceLow
        self.priceHigh = priceHigh
        self.priceTier = priceTier
        self.origin = origin
        self.sustainability = sustainability
        self.workingTips = workingTips
        self.similarSpeciesJSON = similarSpeciesJSON
        self.bestForJSON = bestForJSON
        self.imagesJSON = imagesJSON
        self.isFreeSpecies = isFreeSpecies
    }

    // MARK: - Computed Helpers

    var averagePrice: Double {
        (priceLow + priceHigh) / 2
    }

    var priceRangeFormatted: String {
        "$\(Int(priceLow))–$\(Int(priceHigh))/bf"
    }

    struct SimilarSpecies: Codable {
        let species: String
        let speciesId: String
        let differences: [String]
    }

    var similarSpecies: [SimilarSpecies] {
        guard let data = similarSpeciesJSON.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([SimilarSpecies].self, from: data)) ?? []
    }

    struct BestFor: Codable {
        let use: String
        let description: String
    }

    var bestFor: [BestFor] {
        guard let data = bestForJSON.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([BestFor].self, from: data)) ?? []
    }

    struct ImageURLs: Codable {
        let grain: String?
        let endGrain: String?
        let board: String?
        let tree: String?
        let finished: String?
    }

    var imageURLs: ImageURLs? {
        guard let data = imagesJSON.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(ImageURLs.self, from: data)
    }
}
