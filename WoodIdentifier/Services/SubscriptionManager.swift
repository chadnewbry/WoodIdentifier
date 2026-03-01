import Foundation
import RevenueCat

/// Manages RevenueCat subscriptions for WoodSnap Pro.
@MainActor
final class SubscriptionManager: NSObject, ObservableObject, PurchasesDelegate {
    static let shared = SubscriptionManager()

    @Published var isProUser: Bool = false
    @Published private(set) var errorMessage: String?

    private override init() {
        super.init()
    }

    // MARK: - Configure

    func configure() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "test_olzDjvxdNXOUTVYIUYVugaLOtlq")
        Purchases.shared.delegate = self
        Task { await updateSubscriptionStatus() }
    }

    // MARK: - Restore

    func restorePurchases() async {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            isProUser = Self.hasProAccess(customerInfo)
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Status

    func updateSubscriptionStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            isProUser = Self.hasProAccess(customerInfo)
        } catch {
            errorMessage = "Failed to check subscription: \(error.localizedDescription)"
        }
    }

    // MARK: - PurchasesDelegate

    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            isProUser = Self.hasProAccess(customerInfo)
        }
    }

    // MARK: - Helpers

    private static let entitlementID = "WoodIdentifier Pro"

    private static func hasProAccess(_ customerInfo: CustomerInfo) -> Bool {
        if customerInfo.entitlements[entitlementID]?.isActive == true {
            return true
        }
        return !customerInfo.activeSubscriptions.isEmpty
    }
}
