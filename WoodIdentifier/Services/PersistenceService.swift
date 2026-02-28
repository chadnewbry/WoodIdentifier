import Foundation
import SwiftData

/// Provides shared model container configuration and preview helpers.
enum PersistenceService {
    /// All SwiftData model types used in the app.
    static let modelTypes: [any PersistentModel.Type] = [
        WoodSpecies.self,
        WoodProperty.self,
        WoodProject.self,
        WoodImage.self,
        ScanResult.self
    ]

    /// In-memory container for SwiftUI previews and tests.
    @MainActor
    static var previewContainer: ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: WoodSpecies.self,
            WoodProperty.self,
            WoodProject.self,
            WoodImage.self,
            ScanResult.self,
            configurations: config
        )

        // Seed sample data
        let oak = WoodSpecies(
            name: "White Oak",
            scientificName: "Quercus alba",
            speciesDescription: "A strong, durable hardwood prized for furniture and flooring.",
            hardness: 1360,
            grainPattern: "Straight to slightly irregular",
            uses: "Furniture, flooring, barrels, boat building",
            pricing: "$$",
            imageURL: ""
        )
        container.mainContext.insert(oak)

        let hardnessProp = WoodProperty(
            name: "Janka Hardness",
            propertyDescription: "Resistance to denting and wear (lbf)",
            value: "1360"
        )
        hardnessProp.species = oak
        container.mainContext.insert(hardnessProp)

        return container
    }
}
