import SwiftUI

// MARK: - Wood Theme Colors

extension Color {
    static let woodBrown = Color(red: 0.55, green: 0.35, blue: 0.17)
    static let woodTan = Color(red: 0.82, green: 0.69, blue: 0.51)
    static let woodDark = Color(red: 0.36, green: 0.22, blue: 0.10)
}

// MARK: - Settings View

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            List {
                subscriptionSection
                preferencesSection
                notificationsSection
                scanSection
                widgetsSection
                supportSection
                legalSection
                aboutSection
            }
            .navigationTitle("Settings")
            .fullScreenCover(isPresented: $viewModel.showPaywall) {
                PaywallView(isDismissable: true)
            }
            .sheet(isPresented: $viewModel.showFeedbackForm) {
                FeedbackFormView(viewModel: viewModel)
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [viewModel.shareAppURL()])
            }
        }
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        Section {
            HStack {
                Label("Current Plan", systemImage: "crown.fill")
                    .foregroundStyle(viewModel.isPro ? .yellow : .secondary)
                Spacer()
                Text(viewModel.currentPlan.rawValue)
                    .foregroundStyle(.secondary)
            }

            if !viewModel.isPro {
                Button {
                    viewModel.showPaywall = true
                } label: {
                    HStack {
                        Label("Upgrade to Pro", systemImage: "star.fill")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(.woodBrown)
            }

            Button("Manage Subscription") {
                viewModel.openSubscriptionManagement()
            }

            Button {
                viewModel.restorePurchases()
            } label: {
                HStack {
                    Text("Restore Purchases")
                    if viewModel.isRestoringPurchases {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(viewModel.isRestoringPurchases)
        } header: {
            Text("Subscription")
                .foregroundStyle(Color.woodBrown)
        }
    }

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        Section {
            Picker("Measurement Units", selection: $viewModel.measurementSystem) {
                ForEach(MeasurementSystem.allCases, id: \.rawValue) { system in
                    VStack(alignment: .leading) {
                        Text(system.rawValue)
                    }
                    .tag(system.rawValue)
                }
            }

            HStack {
                Text("Volume")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(MeasurementSystem(rawValue: viewModel.measurementSystem)?.volumeUnit ?? "")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)

            HStack {
                Text("Density")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(MeasurementSystem(rawValue: viewModel.measurementSystem)?.densityUnit ?? "")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        } header: {
            Text("Preferences")
                .foregroundStyle(Color.woodBrown)
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        Section {
            Toggle(isOn: $viewModel.woodOfTheDayNotifications) {
                VStack(alignment: .leading) {
                    Text("Wood of the Day")
                    Text("Daily push with a featured species")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.woodBrown)

            Toggle(isOn: $viewModel.speciesHighlightsNotifications) {
                VStack(alignment: .leading) {
                    Text("Species Highlights")
                    Text("Weekly digest of notable species")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.woodBrown)
        } header: {
            Text("Notifications")
                .foregroundStyle(Color.woodBrown)
        }
    }

    // MARK: - Scan Section

    private var scanSection: some View {
        Section {
            Picker("Default Scan Mode", selection: $viewModel.defaultScanMode) {
                ForEach(ScanMode.allCases, id: \.rawValue) { mode in
                    Text(mode.rawValue).tag(mode.rawValue)
                }
            }
        } header: {
            Text("Scanning")
                .foregroundStyle(Color.woodBrown)
        }
    }

    // MARK: - Widgets Section

    private var widgetsSection: some View {
        Section {
            Toggle(isOn: $viewModel.quickScanWidgetEnabled) {
                VStack(alignment: .leading) {
                    Text("Quick-Scan Shortcut")
                    Text("Home screen widget to launch scanner")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.woodBrown)

            Toggle(isOn: $viewModel.speciesOfTheDayWidgetEnabled) {
                VStack(alignment: .leading) {
                    Text("Species of the Day")
                    Text("Widget showing daily featured species")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.woodBrown)
        } header: {
            Text("Widgets")
                .foregroundStyle(Color.woodBrown)
        }
    }

    // MARK: - Support Section

    private var supportSection: some View {
        Section {
            if let emailURL = viewModel.supportEmailURL() {
                Link(destination: emailURL) {
                    Label("Customer Support", systemImage: "envelope")
                }
            }

            Button {
                viewModel.showFeedbackForm = true
            } label: {
                Label("Send Feedback", systemImage: "text.bubble")
            }

            Button {
                viewModel.rateApp()
            } label: {
                Label("Rate WoodSnap", systemImage: "star")
            }

            Button {
                showShareSheet = true
            } label: {
                Label("Share WoodSnap", systemImage: "square.and.arrow.up")
            }
        } header: {
            Text("Support")
                .foregroundStyle(Color.woodBrown)
        }
    }

    // MARK: - Legal Section

    private var legalSection: some View {
        Section {
            // TODO: Replace with actual URLs once website is deployed
            Link(destination: URL(string: "https://chadnewbry.github.io/WoodIdentifier/privacy")!) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }

            Link(destination: URL(string: "https://chadnewbry.github.io/WoodIdentifier/terms")!) {
                Label("Terms of Use", systemImage: "doc.text")
            }
        } header: {
            Text("Legal")
                .foregroundStyle(Color.woodBrown)
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: viewModel.appVersion)
            LabeledContent("Species Database", value: viewModel.speciesDatabaseVersion)

            NavigationLink {
                CreditsView()
            } label: {
                Label("Credits & Acknowledgments", systemImage: "heart")
            }
        } header: {
            Text("About")
                .foregroundStyle(Color.woodBrown)
        }
    }
}


// MARK: - Feedback Form

struct FeedbackFormView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Your Feedback") {
                    TextEditor(text: $viewModel.feedbackText)
                        .frame(minHeight: 120)
                }

                Section {
                    if let screenshot = viewModel.feedbackScreenshot {
                        Image(uiImage: screenshot)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Button("Remove Screenshot", role: .destructive) {
                            viewModel.feedbackScreenshot = nil
                        }
                    }

                    Button {
                        viewModel.showImagePicker = true
                    } label: {
                        Label(
                            viewModel.feedbackScreenshot == nil ? "Attach Screenshot" : "Change Screenshot",
                            systemImage: "camera"
                        )
                    }
                } header: {
                    Text("Screenshot (Optional)")
                }

                if viewModel.feedbackSubmitted {
                    Section {
                        Label("Thank you for your feedback!", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        viewModel.submitFeedback()
                    }
                    .disabled(viewModel.feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $viewModel.showImagePicker) {
                ImagePicker(image: $viewModel.feedbackScreenshot)
            }
        }
    }
}

// MARK: - Credits View

struct CreditsView: View {
    var body: some View {
        List {
            Section("Development") {
                Text("Built by Chad Newbry LLC")
            }

            Section("Wood Science") {
                Text("Species data sourced from publicly available forestry databases and expert contributions.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Open Source") {
                Text("WoodSnap uses open source libraries. See our GitHub for details.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Special Thanks") {
                Text("To the woodworking community for inspiration, feedback, and passion for the craft. 🪵")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Credits")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
