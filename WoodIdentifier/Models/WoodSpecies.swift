import Foundation
import SwiftData

@Model
final class WoodSpecies {
    @Attribute(.unique) var id: UUID
    var name: String
    var scientificName: String
    var speciesDescription: String
    var hardness: Int?
    var grainPattern: String
    var uses: String
    var pricing: String
    var imageURL: String

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
        hardness: Int? = nil,
        grainPattern: String = "",
        uses: String = "",
        pricing: String = "",
        imageURL: String = ""
    ) {
        self.id = id
        self.name = name
        self.scientificName = scientificName
        self.speciesDescription = speciesDescription
        self.hardness = hardness
        self.grainPattern = grainPattern
        self.uses = uses
        self.pricing = pricing
        self.imageURL = imageURL
    }
}
