import Foundation
import SwiftData

@Model
final class WoodProject {
    @Attribute(.unique) var id: UUID
    var name: String
    var projectDescription: String
    var startDate: Date
    var endDate: Date?
    var notes: String
    var woodSpecies: [WoodSpecies] = []

    init(
        id: UUID = UUID(),
        name: String,
        projectDescription: String = "",
        startDate: Date = .now,
        endDate: Date? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.projectDescription = projectDescription
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
    }
}
