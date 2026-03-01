import Foundation
import StoreKit

/// Product identifiers for WoodSnap Pro subscriptions.
enum SubscriptionProduct: String, CaseIterable {
    case weekly = "com.chadnewbry.woodidentifier.pro.weekly"
    case monthly = "com.chadnewbry.woodidentifier.pro.monthly"
    case annual = "com.chadnewbry.woodidentifier.pro.annual"

    var sortOrder: Int {
        switch self {
        case .weekly: return 0
        case .monthly: return 1
        case .annual: return 2
        }
    }
}

/// Manages StoreKit 2 subscriptions for WoodSnap Pro.
@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published private(set) var products: [Product] = []
    @Published private(set) var isProUser: Bool = false
    @Published private(set) var purchaseInProgress: Bool = false
    @Published private(set) var errorMessage: String?

    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let ids = SubscriptionProduct.allCases.map(\.rawValue)
            let storeProducts = try await Product.products(for: ids)
            products = storeProducts.sorted { a, b in
                let orderA = SubscriptionProduct(rawValue: a.id)?.sortOrder ?? 99
                let orderB = SubscriptionProduct(rawValue: b.id)?.sortOrder ?? 99
                return orderA < orderB
            }
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async {
        purchaseInProgress = true
        errorMessage = nil

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updateSubscriptionStatus()
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
        }

        purchaseInProgress = false
    }

    // MARK: - Restore

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Status

    func updateSubscriptionStatus() async {
        var hasActiveSubscription = false

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if transaction.productType == .autoRenewable,
                   transaction.revocationDate == nil {
                    hasActiveSubscription = true
                    break
                }
            }
        }

        isProUser = hasActiveSubscription
    }

    // MARK: - Helpers

    func product(for id: SubscriptionProduct) -> Product? {
        products.first { $0.id == id.rawValue }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified(_, let error):
            throw error
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if let transaction = try? result.payloadValue {
                    await transaction.finish()
                    await self?.updateSubscriptionStatus()
                }
            }
        }
    }
}
