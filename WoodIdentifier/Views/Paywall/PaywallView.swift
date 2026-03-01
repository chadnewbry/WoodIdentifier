import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedProduct: Product?
    let isDismissable: Bool

    init(isDismissable: Bool = true) {
        self.isDismissable = isDismissable
    }

    var body: some View {
        ZStack {
            // Wood grain background
            LinearGradient(
                colors: [
                    Color(red: 0.35, green: 0.22, blue: 0.12),
                    Color(red: 0.25, green: 0.15, blue: 0.08),
                    Color(red: 0.18, green: 0.10, blue: 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Subtle grain texture overlay
            Image(systemName: "line.diagonal")
                .resizable()
                .foregroundStyle(.white.opacity(0.03))
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Close button
                    if isDismissable {
                        HStack {
                            Spacer()
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    } else {
                        Spacer().frame(height: 20)
                    }

                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.yellow)

                        Text("WoodSnap Pro")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)

                        Text("Unlock the full wood identification experience")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }

                    // Feature comparison
                    featureComparison
                        .padding(.horizontal)

                    // Subscription cards
                    VStack(spacing: 12) {
                        ForEach(subscriptionManager.products, id: \.id) { product in
                            subscriptionCard(product)
                        }
                    }
                    .padding(.horizontal)

                    // Error message
                    if let error = subscriptionManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }

                    // Subscribe button
                    Button {
                        if let product = selectedProduct {
                            Task { await subscriptionManager.purchase(product) }
                        }
                    } label: {
                        Group {
                            if subscriptionManager.purchaseInProgress {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Start Free Trial")
                                    .fontWeight(.bold)
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.brown, in: Capsule())
                    }
                    .disabled(selectedProduct == nil || subscriptionManager.purchaseInProgress)
                    .padding(.horizontal, 24)

                    // Restore + legal
                    VStack(spacing: 12) {
                        Button("Restore Purchases") {
                            Task { await subscriptionManager.restorePurchases() }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))

                        HStack(spacing: 16) {
                            Link("Privacy Policy", destination: URL(string: "https://chadnewbry.github.io/WoodIdentifier/privacy")!)
                            Link("Terms of Use", destination: URL(string: "https://chadnewbry.github.io/WoodIdentifier/terms")!)
                        }
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            // Default to annual
            if selectedProduct == nil {
                selectedProduct = subscriptionManager.product(for: .annual)
                    ?? subscriptionManager.products.last
            }
        }
        .onChange(of: subscriptionManager.products) { _, _ in
            if selectedProduct == nil {
                selectedProduct = subscriptionManager.product(for: .annual)
                    ?? subscriptionManager.products.last
            }
        }
        .onChange(of: subscriptionManager.isProUser) { _, isPro in
            if isPro { dismiss() }
        }
    }

    // MARK: - Feature Comparison

    private var featureComparison: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Feature")
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Free")
                    .font(.caption.weight(.semibold))
                    .frame(width: 60)
                Text("Pro")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.yellow)
                    .frame(width: 60)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white.opacity(0.1))

            featureRow("Daily scans", free: "3", pro: "Unlimited")
            featureRow("Scan history", free: "Last 10", pro: "Full")
            featureRow("Species database", free: "50", pro: "200+")
            featureRow("Compare tool", free: "—", pro: "✓")
            featureRow("Price estimates", free: "—", pro: "✓")
            featureRow("Collections", free: "—", pro: "✓")
            featureRow("Working tips", free: "—", pro: "✓")
        }
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }

    private func featureRow(_ name: String, free: String, pro: String) -> some View {
        HStack {
            Text(name)
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(free)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 60)
            Text(pro)
                .font(.caption.weight(.medium))
                .foregroundStyle(.yellow)
                .frame(width: 60)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    // MARK: - Subscription Card

    private func subscriptionCard(_ product: Product) -> some View {
        let isAnnual = product.id == SubscriptionProduct.annual.rawValue
        let isSelected = selectedProduct?.id == product.id

        return Button {
            selectedProduct = product
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(displayName(for: product))
                            .font(.subheadline.weight(.semibold))
                        if isAnnual {
                            Text("Best Value")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.green, in: Capsule())
                        }
                    }
                    Text("Try 3 days free")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .foregroundStyle(.white)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? .white.opacity(0.2) : .white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.yellow : .white.opacity(0.15), lineWidth: isSelected ? 2 : 1)
            )
        }
    }

    private func displayName(for product: Product) -> String {
        switch product.id {
        case SubscriptionProduct.weekly.rawValue: return "Weekly"
        case SubscriptionProduct.monthly.rawValue: return "Monthly"
        case SubscriptionProduct.annual.rawValue: return "Annual"
        default: return product.displayName
        }
    }
}

#Preview {
    PaywallView()
}
