import Foundation
import UIKit

// MARK: - Protocol

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

// MARK: - Implementation

/// Orchestrates cloud and offline wood identification with quota tracking and caching.
final class WoodIdentificationService: WoodIdentificationServiceProtocol {
    static let shared = WoodIdentificationService()

    private let cloudService = CloudVisionService()
    private let fallbackService = CoreMLFallbackService()
    private let imageProcessor = ImageProcessor()
    private let quotaManager = ScanQuotaManager()
    private let networkMonitor = NetworkMonitor.shared
    private let feedbackStore = ScanFeedbackStore.shared

    // Simple in-memory cache keyed by image data hash
    private var cache: [Int: [WoodMatch]] = [:]

    private init() {}

    func identifyFromPhoto(_ image: UIImage) async throws -> IdentificationResult {
        try await identifyFromMultiplePhotos([image])
    }

    func identifyFromMultiplePhotos(_ images: [UIImage]) async throws -> IdentificationResult {
        guard quotaManager.canScan else {
            throw WoodIdentificationError.quotaExceeded
        }

        // Check cache for single image
        if images.count == 1, let img = images.first,
           let data = img.jpegData(compressionQuality: 0.5) {
            let hash = data.hashValue
            if let cached = cache[hash] {
                return IdentificationResult(
                    matches: cached,
                    isOfflineResult: false,
                    scansRemaining: quotaManager.scansRemaining
                )
            }
        }

        // Process images
        let processed = try images.map { img -> Data in
            guard let data = imageProcessor.compressForUpload(img) else {
                throw WoodIdentificationError.imageProcessingFailed
            }
            return data
        }

        let isOffline = !networkMonitor.isConnected
        let matches: [WoodMatch]

        if isOffline {
            // CoreML fallback — only uses first image
            matches = try await fallbackService.identify(imageData: processed[0])
        } else {
            do {
                matches = try await cloudService.identify(imagesData: processed)
            } catch {
                // Fall back to CoreML on network failure
                matches = try await fallbackService.identify(imageData: processed[0])
                quotaManager.recordScan()
                return IdentificationResult(
                    matches: matches,
                    isOfflineResult: true,
                    scansRemaining: quotaManager.scansRemaining
                )
            }
        }

        quotaManager.recordScan()

        // Cache single-image results
        if images.count == 1, let img = images.first,
           let data = img.jpegData(compressionQuality: 0.5) {
            cache[data.hashValue] = matches
        }

        return IdentificationResult(
            matches: matches,
            isOfflineResult: isOffline,
            scansRemaining: quotaManager.scansRemaining
        )
    }
}
