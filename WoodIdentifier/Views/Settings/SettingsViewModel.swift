import SwiftUI
import MessageUI

// MARK: - Enums

enum MeasurementSystem: String, CaseIterable {
    case imperial = "Imperial"
    case metric = "Metric"

    var volumeUnit: String {
        switch self {
        case .imperial: return "board feet"
        case .metric: return "m³"
        }
    }

    var densityUnit: String {
        switch self {
        case .imperial: return "lbs/ft³"
        case .metric: return "kg/m³"
        }
    }
}

enum ScanMode: String, CaseIterable {
    case single = "Single Photo"
    case multi = "Multi-Photo"
}

enum SubscriptionPlan: String {
    case free = "Free"
    case proWeekly = "Pro Weekly"
    case proMonthly = "Pro Monthly"
    case proAnnual = "Pro Annual"
}

// MARK: - ViewModel

@MainActor
final class SettingsViewModel: ObservableObject {
    // Subscription
    @Published var currentPlan: SubscriptionPlan = .free
    @Published var showPaywall = false
    @Published var isRestoringPurchases = false

    init() {
        if SubscriptionManager.shared.isProUser {
            currentPlan = .proAnnual
        }
    }

    // Preferences
    @AppStorage("measurementSystem") var measurementSystem: String = MeasurementSystem.imperial.rawValue
    @AppStorage("defaultScanMode") var defaultScanMode: String = ScanMode.single.rawValue
    @AppStorage("woodOfTheDayNotifications") var woodOfTheDayNotifications = true
    @AppStorage("speciesHighlightsNotifications") var speciesHighlightsNotifications = true
    @AppStorage("quickScanWidgetEnabled") var quickScanWidgetEnabled = true
    @AppStorage("speciesOfTheDayWidgetEnabled") var speciesOfTheDayWidgetEnabled = true

    // Feedback
    @Published var showFeedbackForm = false
    @Published var feedbackText = ""
    @Published var feedbackScreenshot: UIImage?
    @Published var showImagePicker = false
    @Published var feedbackSubmitted = false

    var isPro: Bool {
        SubscriptionManager.shared.isProUser
    }

    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "WoodSnap v\(version) (build \(build))"
    }

    var speciesDatabaseVersion: String {
        // TODO: Wire to actual database version tracking
        return "v2024.03"
    }

    var deviceInfo: String {
        let device = UIDevice.current
        let systemVersion = device.systemVersion
        let model = device.model
        return "\(model), iOS \(systemVersion), \(appVersion)"
    }

    func openSubscriptionManagement() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }

    func restorePurchases() {
        isRestoringPurchases = true
        Task {
            await SubscriptionManager.shared.restorePurchases()
            await MainActor.run {
                isRestoringPurchases = false
                // Update plan display
                if SubscriptionManager.shared.isProUser {
                    currentPlan = .proAnnual // Generic pro indicator
                }
            }
        }
    }

    func rateApp() {
        // TODO: Replace with actual App Store ID
        if let url = URL(string: "https://apps.apple.com/app/id000000000?action=write-review") {
            UIApplication.shared.open(url)
        }
    }

    func shareAppURL() -> URL {
        // TODO: Replace with actual App Store URL
        return URL(string: "https://apps.apple.com/app/id000000000")!
    }

    func submitFeedback() {
        // TODO: Send feedback to backend/email
        feedbackText = ""
        feedbackScreenshot = nil
        feedbackSubmitted = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.feedbackSubmitted = false
            self?.showFeedbackForm = false
        }
    }

    func supportEmailURL() -> URL? {
        let subject = "WoodSnap Support"
        let body = "Please describe your issue:\n\n\n---\nDevice Info: \(deviceInfo)"
        var components = URLComponents(string: "mailto:chad.newbry@gmail.com")
        components?.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        return components?.url
    }
}
