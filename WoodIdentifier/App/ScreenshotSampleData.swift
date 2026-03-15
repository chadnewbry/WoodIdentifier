import Foundation
import SwiftData

#if DEBUG
/// Utility that populates the SwiftData store with curated sample content
/// when the app is launched with `--screenshot-mode`.
enum ScreenshotSampleData {
    static var isScreenshotMode: Bool {
        ProcessInfo.processInfo.arguments.contains("--screenshot-mode")
    }

    
    static func populate(container: ModelContainer) {
        let context = ModelContext(container)

        try? context.delete(model: ScanResult.self)
        try? context.delete(model: WoodProject.self)
        try? context.delete(model: CollectionItem.self)
        try? context.delete(model: WoodSpecies.self)
        try? context.delete(model: WoodProperty.self)
        try? context.delete(model: WoodImage.self)

        let walnut = WoodSpecies(
            name: "Black Walnut",
            scientificName: "Juglans nigra",
            speciesDescription: "Prized for its rich dark color and straight grain. One of the most popular North American hardwoods for fine furniture and gunstocks.",
            category: "Hardwood",
            hardness: 1010,
            density: 0.55,
            grainPattern: "Straight to slightly wavy",
            colorHex: "#3B2314",
            uses: "Fine furniture, cabinetry, gunstocks, veneer, turning",
            pricing: "$$$",
            region: "Eastern North America",
            workability: 8,
            durability: 7,
            isFreeSpecies: true,
            workingTips: "Works well with hand and machine tools. Glues and finishes beautifully.",
            sustainability: "Sustainably managed",
            confusedWith: "English Walnut, Claro Walnut",
            savedToCollection: true
        )

        let cherry = WoodSpecies(
            name: "Cherry",
            scientificName: "Prunus serotina",
            speciesDescription: "Known for its warm reddish-brown color that deepens with age. A classic choice for American furniture making.",
            category: "Hardwood",
            hardness: 950,
            density: 0.50,
            grainPattern: "Fine, straight grain with occasional waves",
            colorHex: "#7B3F00",
            uses: "Furniture, cabinetry, millwork, flooring, musical instruments",
            pricing: "$$$",
            region: "Eastern North America",
            workability: 9,
            durability: 5,
            isFreeSpecies: true,
            workingTips: "Exceptionally easy to work. Sands to a glass-smooth finish.",
            sustainability: "Common",
            confusedWith: "Birch (stained), Maple (stained)",
            savedToCollection: true
        )

        let whiteOak = WoodSpecies(
            name: "White Oak",
            scientificName: "Quercus alba",
            speciesDescription: "A versatile and durable hardwood with distinctive ray fleck patterns in quartersawn cuts.",
            category: "Hardwood",
            hardness: 1360,
            density: 0.68,
            grainPattern: "Coarse, prominent rays on quartersawn",
            colorHex: "#C4A35A",
            uses: "Furniture, flooring, barrels, boatbuilding, timber framing",
            pricing: "$$",
            region: "Eastern North America",
            workability: 7,
            durability: 9,
            isFreeSpecies: true,
            workingTips: "Responds well to steam bending. Use sharp tools to avoid tear-out.",
            sustainability: "Abundant",
            confusedWith: "Red Oak, Chestnut Oak",
            savedToCollection: false
        )

        let maple = WoodSpecies(
            name: "Hard Maple",
            scientificName: "Acer saccharum",
            speciesDescription: "Extremely hard and dense with a pale, creamy color. Known for figured varieties like bird's eye and curly maple.",
            category: "Hardwood",
            hardness: 1450,
            density: 0.63,
            grainPattern: "Fine, uniform texture",
            colorHex: "#F5DEB3",
            uses: "Flooring, butcher blocks, bowling alleys, musical instruments, furniture",
            pricing: "$$",
            region: "Northeastern North America",
            workability: 6,
            durability: 6,
            isFreeSpecies: true,
            workingTips: "Pre-drill for screws. Can burn when machining—use sharp blades.",
            sustainability: "Abundant",
            confusedWith: "Soft Maple, Birch",
            savedToCollection: false
        )

        let teak = WoodSpecies(
            name: "Teak",
            scientificName: "Tectona grandis",
            speciesDescription: "The gold standard for outdoor and marine applications. Natural oils provide exceptional weather and rot resistance.",
            category: "Hardwood",
            hardness: 1155,
            density: 0.63,
            grainPattern: "Straight grain, uneven texture",
            colorHex: "#9C7A38",
            uses: "Outdoor furniture, decking, boatbuilding, veneer",
            pricing: "$$$$",
            region: "Southeast Asia",
            workability: 7,
            durability: 10,
            isFreeSpecies: false,
            workingTips: "Natural oils can interfere with gluing. Wipe surfaces with acetone before glue-up.",
            sustainability: "Plantation grown available",
            confusedWith: "Iroko, Afrormosia"
        )

        context.insert(walnut)
        context.insert(cherry)
        context.insert(whiteOak)
        context.insert(maple)
        context.insert(teak)

        let encoder = JSONEncoder()
        let placeholderJPEG = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xD9])

        let walnutMatch = WoodMatch(speciesId: walnut.id.uuidString, commonName: "Black Walnut", scientificName: "Juglans nigra", confidence: 0.94, hardness: 1010, grainPattern: "Straight to slightly wavy", typicalUses: "Fine furniture, cabinetry", similarSpecies: ["English Walnut", "Claro Walnut"])
        let cherryMatch = WoodMatch(speciesId: cherry.id.uuidString, commonName: "Cherry", scientificName: "Prunus serotina", confidence: 0.89, hardness: 950, grainPattern: "Fine, straight grain", typicalUses: "Furniture, cabinetry", similarSpecies: ["Birch", "Maple"])
        let oakMatch = WoodMatch(speciesId: whiteOak.id.uuidString, commonName: "White Oak", scientificName: "Quercus alba", confidence: 0.91, hardness: 1360, grainPattern: "Coarse with prominent rays", typicalUses: "Furniture, flooring, barrels", similarSpecies: ["Red Oak", "Chestnut Oak"])

        if let data = try? encoder.encode([walnutMatch]) {
            context.insert(ScanResult(scanDate: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now, matchesData: data, photoData: placeholderJPEG, locationName: "Brooklyn, NY"))
        }
        if let data = try? encoder.encode([cherryMatch]) {
            context.insert(ScanResult(scanDate: Calendar.current.date(byAdding: .day, value: -3, to: .now) ?? .now, matchesData: data, photoData: placeholderJPEG, locationName: "Portland, OR"))
        }
        if let data = try? encoder.encode([oakMatch]) {
            context.insert(ScanResult(scanDate: Calendar.current.date(byAdding: .hour, value: -6, to: .now) ?? .now, matchesData: data, photoData: placeholderJPEG, locationName: "Austin, TX"))
        }

        context.insert(CollectionItem(speciesName: "Black Walnut", scientificName: "Juglans nigra", notes: "Beautiful piece from the lumber yard on 5th", projectTag: "Dining Table", dateAdded: Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now))
        context.insert(CollectionItem(speciesName: "Cherry", scientificName: "Prunus serotina", notes: "Quartersawn board with amazing figure", projectTag: "Bookshelf", dateAdded: Calendar.current.date(byAdding: .day, value: -14, to: .now) ?? .now))

        let project1 = WoodProject(name: "Dining Table Build", projectDescription: "Live-edge walnut slab dining table with steel hairpin legs", startDate: Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now, notes: "Using two 8ft walnut slabs joined with butterfly keys")
        project1.woodSpecies = [walnut]
        let project2 = WoodProject(name: "Built-in Bookshelves", projectDescription: "Floor-to-ceiling cherry bookshelves for the study", startDate: Calendar.current.date(byAdding: .day, value: -14, to: .now) ?? .now, notes: "Cherry with adjustable shelves and integrated lighting")
        project2.woodSpecies = [cherry]
        context.insert(project1)
        context.insert(project2)

        try? context.save()
    }
}
#endif
