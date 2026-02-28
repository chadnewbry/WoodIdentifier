import Foundation
import SwiftData

@Model
final class WoodProperty {
    @Attribute(.unique) var id: UUID
    var name: String
    var propertyDescription: String
    var value: String
    var species: WoodSpecies?

    init(
        id: UUID = UUID(),
        name: String,
        propertyDescription: String = "",
        value: String = ""
    ) {
        self.id = id
        self.name = name
        self.propertyDescription = propertyDescription
        self.value = value
    }
}
