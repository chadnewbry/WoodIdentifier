import Foundation
import SwiftData

/// A saved/favorited species in the user's collection (Pro feature).
@Model
final class CollectionItem {
    @Attribute(.unique) var id: UUID
    var speciesName: String
    var scientificName: String
    var notes: String
    var projectTag: String
    var dateAdded: Date
    /// Compressed JPEG thumbnail of the species.
    var photoData: Data?
    /// Reference to the original scan result, if any.
    var scanResultId: UUID?

    init(
        id: UUID = UUID(),
        speciesName: String,
        scientificName: String = "",
        notes: String = "",
        projectTag: String = "",
        dateAdded: Date = .now,
        photoData: Data? = nil,
        scanResultId: UUID? = nil
    ) {
        self.id = id
        self.speciesName = speciesName
        self.scientificName = scientificName
        self.notes = notes
        self.projectTag = projectTag
        self.dateAdded = dateAdded
        self.photoData = photoData
        self.scanResultId = scanResultId
    }
}
