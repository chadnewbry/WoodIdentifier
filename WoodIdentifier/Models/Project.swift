import Foundation

struct Project: Identifiable, Codable {
    let id: UUID
    var name: String
    var notes: String
    var woodTypes: [String]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        notes: String = "",
        woodTypes: [String] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.woodTypes = woodTypes
        self.createdAt = createdAt
    }
}
