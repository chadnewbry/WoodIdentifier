import Foundation
import UIKit

// MARK: - Offline protocol

/// Stub protocol for on-device (offline) wood identification.
/// Implement this with a real CoreML model when one is available.
protocol OfflineIdentificationService {
    func identify(imageData: Data) async throws -> [WoodMatch]
}

// MARK: - Main protocol

/// Protocol for wood identification from photos.
protocol WoodIdentificationServiceProtocol {
    func identifyFromPhoto(_ image: UIImage) async throws -> IdentificationResult
    func identifyFromMultiplePhotos(_ images: [UIImage]) async throws -> IdentificationResult
}

// MARK: - Errors

enum WoodIdentificationError: LocalizedError {
    case quotaExceeded
    case networkFailure(Error)
    case apiRateLimited
    case malformedResponse
    case imageProcessingFailed
    case cameraPermissionDenied

    var errorDescription: String? {
        switch self {
        case .quotaExceeded: return "Daily free scan limit reached (3/day)."
        case .networkFailure(let error): return "Network error: \(error.localizedDescription)"
        case .apiRateLimited: return "API rate limit reached. Please try again later."
        case .malformedResponse: return "Could not parse identification results."
        case .imageProcessingFailed: return "Failed to process image for upload."
        case .cameraPermissionDenied: return "Camera access is required to scan wood."
        }
    }
}

// MARK: - NSCache wrapper

private final class CachedMatches {
    let matches: [WoodMatch]
    init(_ matches: [WoodMatch]) { self.matches = matches }
}

// MARK: - Implementation

/// Orchestrates cloud and offline wood identification with quota tracking and caching.
final class WoodIdentificationService: WoodIdentificationServiceProtocol {
    static let shared = WoodIdentificationService()

    private let cloudService = CloudVisionService()
    private let fallbackService: OfflineIdentificationService = CoreMLFallbackService()
    private let imageProcessor = ImageProcessor()
    private let quotaManager = ScanQuotaManager.shared
    private let networkMonitor = NetworkMonitor.shared

    /// In-memory result cache keyed by SHA-256 hex of compressed image data.
    private let cache = NSCache<NSString, CachedMatches>()

    private init() {
        cache.countLimit = 50
    }

    func identifyFromPhoto(_ image: UIImage) async throws -> IdentificationResult {
        try await identifyFromMultiplePhotos([image])
    }

    func identifyFromMultiplePhotos(_ images: [UIImage]) async throws -> IdentificationResult {
        guard quotaManager.canScan else {
            throw WoodIdentificationError.quotaExceeded
        }

        // Compress images for upload
        let processed: [Data] = try images.map { img in
            guard let data = imageProcessor.compressForUpload(img) else {
                throw WoodIdentificationError.imageProcessingFailed
            }
            return data
        }

        // Check cache (single-image only)
        if processed.count == 1 {
            let key = imageProcessor.hashImage(data: processed[0]) as NSString
            if let cached = cache.object(forKey: key) {
                return IdentificationResult(
                    matches: cached.matches,
                    isOfflineResult: false,
                    scansRemaining: quotaManager.scansRemaining
                )
            }
        }

        let isOffline = !networkMonitor.isConnected
        let matches: [WoodMatch]
        let usedOffline: Bool

        if isOffline {
            matches = try await fallbackService.identify(imageData: processed[0])
            usedOffline = true
        } else {
            do {
                matches = try await cloudService.identify(imagesData: processed)
                usedOffline = false
            } catch {
                // Attempt offline fallback on network failure
                let fallback = try? await fallbackService.identify(imageData: processed[0])
                if let fallback, !fallback.isEmpty {
                    quotaManager.recordScan()
                    return IdentificationResult(
                        matches: fallback,
                        isOfflineResult: true,
                        scansRemaining: quotaManager.scansRemaining
                    )
                }
                throw error
            }
        }

        quotaManager.recordScan()

        // Cache single-image cloud results
        if processed.count == 1 && !usedOffline {
            let key = imageProcessor.hashImage(data: processed[0]) as NSString
            cache.setObject(CachedMatches(matches), forKey: key)
        }

        return IdentificationResult(
            matches: matches,
            isOfflineResult: usedOffline,
            scansRemaining: quotaManager.scansRemaining
        )
    }
}
