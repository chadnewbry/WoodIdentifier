import AVFoundation
import UIKit
import SwiftUI

/// Manages camera permissions and provides a UIKit camera preview coordinator.
final class CameraManager: NSObject, ObservableObject {
    @Published var permissionGranted = false
    @Published var capturedImage: UIImage?
    @Published var photoGuidance: PhotoGuidance?

    private let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private let imageProcessor = ImageProcessor()
    private var continuation: CheckedContinuation<UIImage, Error>?

    override init() {
        super.init()
        checkPermission()
    }

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async { self?.permissionGranted = granted }
            }
        default:
            permissionGranted = false
        }
    }

    func setupSession() {
        guard permissionGranted else { return }

        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }

        session.addInput(input)

        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        session.commitConfiguration()
    }

    func startSession() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    func stopSession() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
        }
    }

    var captureSession: AVCaptureSession { session }

    /// Capture a photo asynchronously.
    func capturePhoto() async throws -> UIImage {
        try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            let settings = AVCapturePhotoSettings()
            settings.flashMode = .auto
            output.capturePhoto(with: settings, delegate: self)
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            continuation?.resume(throwing: error)
            continuation = nil
            return
        }

        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            continuation?.resume(throwing: WoodIdentificationError.imageProcessingFailed)
            continuation = nil
            return
        }

        // Check photo quality
        let guidance = imageProcessor.analyzeQuality(image)
        DispatchQueue.main.async { self.photoGuidance = guidance }

        capturedImage = image
        continuation?.resume(returning: image)
        continuation = nil
    }
}
