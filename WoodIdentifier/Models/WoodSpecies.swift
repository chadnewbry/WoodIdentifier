import Foundation

struct WoodSpecies: Identifiable, Codable {
    let id: UUID
    let commonName: String
    let scientificName: String
    let description: String
    let hardness: Int?
    let color: String
    let grain: String
    let uses: [String]

    init(
        id: UUID = UUID(),
        commonName: String,
        scientificName: String,
        description: String = "",
        hardness: Int? = nil,
        color: String = "",
        grain: String = "",
        uses: [String] = []
    ) {
        self.id = id
        self.commonName = commonName
        self.scientificName = scientificName
        self.description = description
        self.hardness = hardness
        self.color = color
        self.grain = grain
        self.uses = uses
    }
}
