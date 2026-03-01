import SwiftUI
import RevenueCatUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    let isDismissable: Bool

    init(isDismissable: Bool = true) {
        self.isDismissable = isDismissable
    }

    var body: some View {
        RevenueCatUI.PaywallView(displayCloseButton: isDismissable)
            .onPurchaseCompleted { customerInfo in
                SubscriptionManager.shared.isProUser = !customerInfo.activeSubscriptions.isEmpty
                dismiss()
            }
            .onRestoreCompleted { customerInfo in
                SubscriptionManager.shared.isProUser = !customerInfo.activeSubscriptions.isEmpty
                dismiss()
            }
    }
}

#Preview {
    PaywallView()
}
