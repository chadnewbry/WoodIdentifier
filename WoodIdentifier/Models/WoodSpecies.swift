import Foundation
import SwiftData

@Model
final class WoodSpecies {
    @Attribute(.unique) var id: UUID
    var name: String
    var scientificName: String
    var speciesDescription: String
    var category: String
    var hardness: Int?
    var density: Double?
    var grainPattern: String
    var colorHex: String
    var uses: String
    var pricing: String
    var imageURL: String
    var region: String
    var workability: Int
    var durability: Int
    var isFreeSpecies: Bool
    var workingTips: String
    var shrinkageRadial: Double?
    var shrinkageTangential: Double?
    var sustainability: String
    var confusedWith: String
    var savedToCollection: Bool
    var databaseVersion: Int

    @Relationship(deleteRule: .cascade, inverse: \WoodProperty.species)
    var properties: [WoodProperty] = []

    @Relationship(deleteRule: .cascade, inverse: \WoodImage.associatedSpecies)
    var images: [WoodImage] = []

    @Relationship(inverse: \WoodProject.woodSpecies)
    var projects: [WoodProject] = []

    init(
        id: UUID = UUID(),
        name: String,
        scientificName: String,
        speciesDescription: String = "",
        category: String = "Hardwood",
        hardness: Int? = nil,
        density: Double? = nil,
        grainPattern: String = "",
        colorHex: String = "#8B4513",
        uses: String = "",
        pricing: String = "$$",
        imageURL: String = "",
        region: String = "",
        workability: Int = 5,
        durability: Int = 5,
        isFreeSpecies: Bool = false,
        workingTips: String = "",
        shrinkageRadial: Double? = nil,
        shrinkageTangential: Double? = nil,
        sustainability: String = "Common",
        confusedWith: String = "",
        savedToCollection: Bool = false,
        databaseVersion: Int = 1
    ) {
        self.id = id
        self.name = name
        self.scientificName = scientificName
        self.speciesDescription = speciesDescription
        self.category = category
        self.hardness = hardness
        self.density = density
        self.grainPattern = grainPattern
        self.colorHex = colorHex
        self.uses = uses
        self.pricing = pricing
        self.imageURL = imageURL
        self.region = region
        self.workability = workability
        self.durability = durability
        self.isFreeSpecies = isFreeSpecies
        self.workingTips = workingTips
        self.shrinkageRadial = shrinkageRadial
        self.shrinkageTangential = shrinkageTangential
        self.sustainability = sustainability
        self.confusedWith = confusedWith
        self.savedToCollection = savedToCollection
        self.databaseVersion = databaseVersion
    }
}
