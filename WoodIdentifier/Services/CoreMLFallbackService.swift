import Foundation
import UIKit
import CoreML
import Vision

/// Offline fallback using a basic on-device classifier for top-50 wood species.
/// In production, a real CoreML model (.mlmodelc) would be bundled in the app.
/// This implementation provides the interface and gracefully degrades when no model is available.
final class CoreMLFallbackService {

    // Top-50 common wood species for offline reference
    private static let knownSpecies: [(id: String, common: String, scientific: String)] = [
        ("quercus-alba", "White Oak", "Quercus alba"),
        ("quercus-rubra", "Red Oak", "Quercus rubra"),
        ("juglans-nigra", "Black Walnut", "Juglans nigra"),
        ("prunus-serotina", "Black Cherry", "Prunus serotina"),
        ("acer-saccharum", "Hard Maple", "Acer saccharum"),
        ("acer-rubrum", "Soft Maple", "Acer rubrum"),
        ("fraxinus-americana", "White Ash", "Fraxinus americana"),
        ("liriodendron-tulipifera", "Poplar", "Liriodendron tulipifera"),
        ("pinus-strobus", "Eastern White Pine", "Pinus strobus"),
        ("pinus-ponderosa", "Ponderosa Pine", "Pinus ponderosa"),
        ("pseudotsuga-menziesii", "Douglas Fir", "Pseudotsuga menziesii"),
        ("tsuga-canadensis", "Eastern Hemlock", "Tsuga canadensis"),
        ("thuja-plicata", "Western Red Cedar", "Thuja plicata"),
        ("juniperus-virginiana", "Eastern Red Cedar", "Juniperus virginiana"),
        ("tectona-grandis", "Teak", "Tectona grandis"),
        ("swietenia-macrophylla", "Mahogany", "Swietenia macrophylla"),
        ("dalbergia-nigra", "Brazilian Rosewood", "Dalbergia nigra"),
        ("pterocarpus-soyauxii", "Padauk", "Pterocarpus soyauxii"),
        ("millettia-laurentii", "Wenge", "Millettia laurentii"),
        ("diospyros-ebenum", "Ebony", "Diospyros ebenum"),
        ("guibourtia-ehie", "Bubinga", "Guibourtia ehie"),
        ("chloroxylon-swietenia", "Satinwood", "Chloroxylon swietenia"),
        ("entandrophragma-cylindricum", "Sapele", "Entandrophragma cylindricum"),
        ("khaya-ivorensis", "African Mahogany", "Khaya ivorensis"),
        ("fagus-grandifolia", "American Beech", "Fagus grandifolia"),
        ("betula-alleghaniensis", "Yellow Birch", "Betula alleghaniensis"),
        ("carya-ovata", "Shagbark Hickory", "Carya ovata"),
        ("platanus-occidentalis", "American Sycamore", "Platanus occidentalis"),
        ("ulmus-americana", "American Elm", "Ulmus americana"),
        ("tilia-americana", "Basswood", "Tilia americana"),
        ("taxus-brevifolia", "Pacific Yew", "Taxus brevifolia"),
        ("picea-sitchensis", "Sitka Spruce", "Picea sitchensis"),
        ("sequoia-sempervirens", "Redwood", "Sequoia sempervirens"),
        ("araucaria-angustifolia", "Parana Pine", "Araucaria angustifolia"),
        ("dalbergia-latifolia", "Indian Rosewood", "Dalbergia latifolia"),
        ("shorea-spp", "Meranti", "Shorea spp."),
        ("intsia-bijuga", "Merbau", "Intsia bijuga"),
        ("hevea-brasiliensis", "Rubberwood", "Hevea brasiliensis"),
        ("acacia-melanoxylon", "Blackwood", "Acacia melanoxylon"),
        ("eucalyptus-marginata", "Jarrah", "Eucalyptus marginata"),
        ("corymbia-maculata", "Spotted Gum", "Corymbia maculata"),
        ("nothofagus-cunninghamii", "Myrtle Beech", "Nothofagus cunninghamii"),
        ("castanea-dentata", "American Chestnut", "Castanea dentata"),
        ("robinia-pseudoacacia", "Black Locust", "Robinia pseudoacacia"),
        ("sassafras-albidum", "Sassafras", "Sassafras albidum"),
        ("liquidambar-styraciflua", "Sweetgum", "Liquidambar styraciflua"),
        ("nyssa-sylvatica", "Black Tupelo", "Nyssa sylvatica"),
        ("paulownia-tomentosa", "Paulownia", "Paulownia tomentosa"),
        ("bambusa-vulgaris", "Bamboo", "Bambusa vulgaris"),
        ("olea-europaea", "Olive", "Olea europaea"),
    ]

    /// Attempt identification using CoreML. Falls back to a placeholder result
    /// when no model is bundled (development builds).
    func identify(imageData: Data) async throws -> [WoodMatch] {
        // Try loading a real CoreML model if bundled
        if let model = try? loadModel() {
            return try await classifyWithModel(model, imageData: imageData)
        }

        // Development fallback: return a generic "unknown" result so the UI works
        return [
            WoodMatch(
                speciesId: "unknown-offline",
                commonName: "Unknown (Offline)",
                scientificName: "—",
                confidence: 0.3,
                properties: ["note": "CoreML model not bundled. Results are placeholders."],
                similarSpecies: ["White Oak", "Red Oak", "Hard Maple"]
            )
        ]
    }

    private func loadModel() throws -> VNCoreMLModel? {
        guard let url = Bundle.main.url(forResource: "WoodClassifier", withExtension: "mlmodelc"),
              let compiled = try? MLModel(contentsOf: url) else {
            return nil
        }
        return try VNCoreMLModel(for: compiled)
    }

    private func classifyWithModel(_ model: VNCoreMLModel, imageData: Data) async throws -> [WoodMatch] {
        guard let image = UIImage(data: imageData)?.cgImage else {
            throw WoodIdentificationError.imageProcessingFailed
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error {
                    continuation.resume(throwing: WoodIdentificationError.networkFailure(error))
                    return
                }

                guard let results = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let matches = results.prefix(3).compactMap { obs -> WoodMatch? in
                    let label = obs.identifier
                    let species = Self.knownSpecies.first { $0.id == label }
                    return WoodMatch(
                        speciesId: species?.id ?? label,
                        commonName: species?.common ?? label,
                        scientificName: species?.scientific ?? "Unknown",
                        confidence: Double(obs.confidence)
                    )
                }

                continuation.resume(returning: matches)
            }

            let handler = VNImageRequestHandler(cgImage: image)
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: WoodIdentificationError.imageProcessingFailed)
            }
        }
    }
}
