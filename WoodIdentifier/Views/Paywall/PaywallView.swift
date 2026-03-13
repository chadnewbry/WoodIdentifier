import SwiftUI
import RevenueCatUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    let isDismissable: Bool

    init(isDismissable: Bool = true) {
        self.isDismissable = isDismissable
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RevenueCatUI.PaywallView(displayCloseButton: false)
                .onPurchaseCompleted { customerInfo in
                    SubscriptionManager.shared.isProUser = !customerInfo.activeSubscriptions.isEmpty
                    dismiss()
                }
                .onRestoreCompleted { customerInfo in
                    SubscriptionManager.shared.isProUser = !customerInfo.activeSubscriptions.isEmpty
                    dismiss()
                }

            if isDismissable {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.5))
                }
                .padding(.top, 8)
                .padding(.trailing, 16)
                .accessibilityIdentifier("paywallDismissButton")
                .accessibilityLabel("Close")
            }
        }
    }
}

#Preview {
    PaywallView()
}
