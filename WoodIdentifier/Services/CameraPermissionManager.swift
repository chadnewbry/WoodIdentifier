import AVFoundation
import Photos
import UIKit

/// Centralises camera and photo-library permission checks and requests.
@MainActor
final class CameraPermissionManager: ObservableObject {
    static let shared = CameraPermissionManager()

    @Published private(set) var cameraStatus: AVAuthorizationStatus = .notDetermined
    @Published private(set) var photoLibraryStatus: PHAuthorizationStatus = .notDetermined

    private init() {
        refresh()
    }

    // MARK: - Convenience booleans

    var isCameraAuthorized: Bool { cameraStatus == .authorized }

    var isPhotoLibraryAuthorized: Bool {
        photoLibraryStatus == .authorized || photoLibraryStatus == .limited
    }

    var isCameraDenied: Bool {
        cameraStatus == .denied || cameraStatus == .restricted
    }

    var isPhotoLibraryDenied: Bool {
        photoLibraryStatus == .denied || photoLibraryStatus == .restricted
    }

    // MARK: - State refresh

    func refresh() {
        cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        photoLibraryStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    // MARK: - Permission requests

    func requestCameraAccess() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        return granted
    }

    @discardableResult
    func requestPhotoLibraryAccess() async -> PHAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        photoLibraryStatus = status
        return status
    }

    // MARK: - Settings redirect

    /// Opens iOS Settings so the user can manually grant access.
    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
