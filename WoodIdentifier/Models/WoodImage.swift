import Foundation
import SwiftData

@Model
final class WoodImage {
    var id: UUID = UUID()
    var url: String = ""
    var caption: String = ""
    var uploadDate: Date = Date()
    var associatedSpecies: WoodSpecies?

    init(
        id: UUID = UUID(),
        url: String,
        caption: String = "",
        uploadDate: Date = .now
    ) {
        self.id = id
        self.url = url
        self.caption = caption
        self.uploadDate = uploadDate
    }
}
