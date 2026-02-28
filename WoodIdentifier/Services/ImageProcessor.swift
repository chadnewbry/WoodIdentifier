import UIKit
import CryptoKit

// MARK: - Quality types

/// Detailed result of an image quality check.
struct ImageQualityResult {
    let isAcceptable: Bool
    let guidance: PhotoGuidance?
}

/// Guidance when a photo should be retaken.
enum PhotoGuidance: String {
    case tooFewLight = "Photo is too dark. Try better lighting."
    case tooMuchLight = "Photo is overexposed. Reduce direct light."
    case tooLowResolution = "Photo resolution is too low. Move closer."
    case blurry = "Photo appears blurry. Hold steady and try again."
}

// MARK: - ImageProcessor

/// Handles image resizing, compression, hashing, and quality analysis for upload.
final class ImageProcessor {

    /// Target maximum size in bytes (~500 KB).
    private let targetBytes = 500_000

    // MARK: - Public API

    /// Resize an image so its longest side does not exceed `maxDimension`.
    func resizeForUpload(image: UIImage, maxDimension: CGFloat = 1024) -> UIImage {
        let size = image.size
        guard max(size.width, size.height) > maxDimension else { return image }
        let scale = maxDimension / max(size.width, size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    /// Resize to max 1024px and compress to JPEG at the given quality.
    func compressForUpload(image: UIImage, quality: CGFloat = 0.7) -> Data? {
        let resized = resizeForUpload(image: image)
        return resized.jpegData(compressionQuality: quality)
    }

    /// Compress with binary-search quality to stay under ~500 KB.
    func compressForUpload(_ image: UIImage) -> Data? {
        let resized = resizeForUpload(image: image)
        var lo: CGFloat = 0.1
        var hi: CGFloat = 0.9
        var best: Data?
        for _ in 0..<6 {
            let mid = (lo + hi) / 2
            guard let data = resized.jpegData(compressionQuality: mid) else { return nil }
            if data.count <= targetBytes {
                best = data
                lo = mid
            } else {
                hi = mid
            }
        }
        return best ?? resized.jpegData(compressionQuality: 0.5)
    }

    /// SHA-256 hex string of image data — used as cache key.
    func hashImage(data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// Check image quality and return an actionable result.
    func validateImageQuality(image: UIImage) -> ImageQualityResult {
        guard let cgImage = image.cgImage else {
            return ImageQualityResult(isAcceptable: false, guidance: .tooLowResolution)
        }

        if cgImage.width < 300 || cgImage.height < 300 {
            return ImageQualityResult(isAcceptable: false, guidance: .tooLowResolution)
        }

        if let brightness = averageBrightness(cgImage) {
            if brightness < 0.15 {
                return ImageQualityResult(isAcceptable: false, guidance: .tooFewLight)
            }
            if brightness > 0.9 {
                return ImageQualityResult(isAcceptable: false, guidance: .tooMuchLight)
            }
        }

        return ImageQualityResult(isAcceptable: true, guidance: nil)
    }

    /// Legacy helper — returns guidance only (nil = acceptable).
    func analyzeQuality(_ image: UIImage) -> PhotoGuidance? {
        validateImageQuality(image: image).guidance
    }

    // MARK: - Private

    private func averageBrightness(_ cgImage: CGImage) -> Double? {
        let width = cgImage.width
        let height = cgImage.height
        let totalBytes = width * height * 4
        guard totalBytes < 50_000_000 else { return nil }

        let w = min(width, 100)
        let h = min(height, 100)
        guard let context = CGContext(
            data: nil,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: w * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
        guard let data = context.data else { return nil }
        let ptr = data.bindMemory(to: UInt8.self, capacity: w * h * 4)

        var totalLuminance: Double = 0
        let pixelCount = w * h
        for i in 0..<pixelCount {
            let offset = i * 4
            let r = Double(ptr[offset])
            let g = Double(ptr[offset + 1])
            let b = Double(ptr[offset + 2])
            totalLuminance += (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
        }
        return totalLuminance / Double(pixelCount)
    }
}
