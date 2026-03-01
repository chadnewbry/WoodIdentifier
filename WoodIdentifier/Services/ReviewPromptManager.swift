import StoreKit
import Foundation

/// Prompts for App Store review after 3rd successful scan, once per app version.
@MainActor
enum ReviewPromptManager {
    private static let reviewedVersionKey = "lastReviewPromptVersion"

    static func requestReviewIfAppropriate() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let lastVersion = UserDefaults.standard.string(forKey: reviewedVersionKey)

        guard lastVersion != currentVersion else { return }
        guard ScanQuotaManager.shared.totalScans >= 3 else { return }

        UserDefaults.standard.set(currentVersion, forKey: reviewedVersionKey)

        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}
