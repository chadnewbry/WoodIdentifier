import Foundation

/// Stores user corrections when AI identification is wrong.
/// Persisted locally for potential future model improvement.
final class ScanFeedbackStore {
    static let shared = ScanFeedbackStore()

    private let defaults = UserDefaults.standard
    private let key = "scanFeedbackCorrections"

    private init() {}

    /// Record that the user corrected a match to a different species.
    func recordCorrection(
        originalSpeciesId: String,
        correctedSpeciesId: String,
        correctedCommonName: String
    ) {
        var corrections = allCorrections
        corrections.append([
            "originalSpeciesId": originalSpeciesId,
            "correctedSpeciesId": correctedSpeciesId,
            "correctedCommonName": correctedCommonName,
            "date": ISO8601DateFormatter().string(from: Date())
        ])
        defaults.set(corrections, forKey: key)
    }

    /// All stored corrections.
    var allCorrections: [[String: String]] {
        defaults.array(forKey: key) as? [[String: String]] ?? []
    }
}
