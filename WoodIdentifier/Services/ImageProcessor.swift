import UIKit

/// Handles image compression and quality analysis for upload.
final class ImageProcessor {

    /// Target maximum size in bytes (~500 KB).
    private let targetBytes = 500_000

    /// Maximum dimension for upload images.
    private let maxDimension: CGFloat = 1024

    /// Compress and resize an image for API upload. Returns JPEG data ≤ ~500 KB.
    func compressForUpload(_ image: UIImage) -> Data? {
        let resized = resize(image, maxDimension: maxDimension)

        // Binary search for quality that fits under target
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

    /// Analyze image quality and return guidance if photo should be retaken.
    func analyzeQuality(_ image: UIImage) -> PhotoGuidance? {
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height

        // Too small — likely cropped or low res
        if width < 300 || height < 300 {
            return .tooLowResolution
        }

        // Check brightness via average pixel luminance (simplified)
        if let brightness = averageBrightness(cgImage) {
            if brightness < 0.15 {
                return .tooFewLight
            }
            if brightness > 0.9 {
                return .tooMuchLight
            }
        }

        return nil
    }

    // MARK: - Private

    private func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard max(size.width, size.height) > maxDimension else { return image }

        let scale = maxDimension / max(size.width, size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func averageBrightness(_ cgImage: CGImage) -> Double? {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let totalBytes = bytesPerRow * height

        guard totalBytes < 50_000_000, // Don't process huge images
              let context = CGContext(
                data: nil,
                width: min(width, 100), // Sample at low res
                height: min(height, 100),
                bitsPerComponent: 8,
                bytesPerRow: min(width, 100) * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else { return nil }

        let w = min(width, 100)
        let h = min(height, 100)
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

/// Guidance when a photo should be retaken.
enum PhotoGuidance: String {
    case tooFewLight = "Photo is too dark. Try better lighting."
    case tooMuchLight = "Photo is overexposed. Reduce direct light."
    case tooLowResolution = "Photo resolution is too low. Move closer."
    case blurry = "Photo appears blurry. Hold steady and try again."
}
