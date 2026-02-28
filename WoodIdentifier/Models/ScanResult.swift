import Foundation
import SwiftData

/// Persisted record of a completed wood identification scan.
@Model
final class ScanResult {
    @Attribute(.unique) var id: UUID
    var scanDate: Date
    /// JSON-encoded [WoodMatch].
    var matchesData: Data
    /// Compressed JPEG of the scanned photo.
    var photoData: Data
    var isOfflineResult: Bool
    /// Species name entered by the user when correcting an identification.
    var userCorrectedSpecies: String?
    var freeScansRemaining: Int

    init(
        id: UUID = UUID(),
        scanDate: Date = .now,
        matchesData: Data,
        photoData: Data,
        isOfflineResult: Bool = false,
        userCorrectedSpecies: String? = nil,
        freeScansRemaining: Int = 0
    ) {
        self.id = id
        self.scanDate = scanDate
        self.matchesData = matchesData
        self.photoData = photoData
        self.isOfflineResult = isOfflineResult
        self.userCorrectedSpecies = userCorrectedSpecies
        self.freeScansRemaining = freeScansRemaining
    }

    /// Decoded matches (convenience accessor).
    var matches: [WoodMatch] {
        (try? JSONDecoder().decode([WoodMatch].self, from: matchesData)) ?? []
    }

    /// Top match, if any.
    var topMatch: WoodMatch? { matches.first }
}

extension ScanResult {
    /// Convenience factory: encode matches and insert into context.
    @discardableResult
    static func create(
        from result: IdentificationResult,
        photoData: Data,
        in context: ModelContext
    ) throws -> ScanResult {
        let matchesData = try JSONEncoder().encode(result.matches)
        let scanResult = ScanResult(
            matchesData: matchesData,
            photoData: photoData,
            isOfflineResult: result.isOfflineResult,
            freeScansRemaining: result.scansRemaining
        )
        context.insert(scanResult)
        try context.save()
        return scanResult
    }
}
