import SwiftUI
import PhotosUI

struct CameraView: View {
    @State private var showTutorial = !UserDefaults.standard.bool(forKey: "hasSeenFirstScanTutorial")
    @StateObject private var cameraManager = CameraManager()
    @State private var selectedPhotos: [UIImage] = []
    @State private var isIdentifying = false
    @State private var identificationResult: IdentificationResult?
    @State private var errorMessage: String?
    @State private var showPhotoPicker = false
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showResults = false

    private let identificationService = WoodIdentificationService.shared
    private let quotaManager = ScanQuotaManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 16) {
                    // Photo count & guidance
                    if !selectedPhotos.isEmpty {
                        photoStrip
                    }

                    Spacer()

                    if !cameraManager.permissionGranted {
                        permissionDeniedView
                    } else {
                        cameraPlaceholder
                    }

                    if let guidance = cameraManager.photoGuidance {
                        Label(guidance.rawValue, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .padding(.horizontal)
                    }

                    Spacer()

                    // Scan count
                    Text("\(quotaManager.scansRemaining) free scans remaining today")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Action buttons
                    HStack(spacing: 32) {
                        PhotosPicker(selection: $pickerItems, maxSelectionCount: 3, matching: .images) {
                            VStack {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.title2)
                                Text("Library")
                                    .font(.caption2)
                            }
                        }
                        .onChange(of: pickerItems) { _, items in
                            Task { await loadPickerItems(items) }
                        }

                        Button {
                            Task { await captureAndAdd() }
                        } label: {
                            Image(systemName: "camera.circle.fill")
                                .font(.system(size: 72))
                                .foregroundStyle(.brown)
                        }
                        .disabled(!cameraManager.permissionGranted || selectedPhotos.count >= 3)

                        Button {
                            guard !selectedPhotos.isEmpty else { return }
                            Task { await identifyPhotos() }
                        } label: {
                            VStack {
                                Image(systemName: "sparkles")
                                    .font(.title2)
                                Text("Identify")
                                    .font(.caption2)
                            }
                        }
                        .disabled(selectedPhotos.isEmpty || isIdentifying)
                    }
                    .padding(.bottom, 20)
                }

                if isIdentifying {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView("Identifying wood…")
                        .padding(24)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }

                FirstScanTutorialOverlay(isVisible: $showTutorial)
            }
            .navigationTitle("Scan Wood")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !selectedPhotos.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear") {
                            selectedPhotos.removeAll()
                            identificationResult = nil
                            errorMessage = nil
                        }
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: $showResults) {
                if let result = identificationResult {
                    ScanResultsSheet(result: result)
                }
            }
            .onAppear {
                cameraManager.setupSession()
                cameraManager.startSession()
            }
            .onDisappear {
                cameraManager.stopSession()
            }
        }
    }

    // MARK: - Subviews

    private var photoStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(selectedPhotos.enumerated()), id: \.offset) { index, photo in
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(alignment: .topTrailing) {
                            Button {
                                selectedPhotos.remove(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.white, .red)
                            }
                            .offset(x: 4, y: -4)
                        }
                }

                if selectedPhotos.count < 3 {
                    Text("Add up to \(3 - selectedPhotos.count) more")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 60, height: 60)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 70)
    }

    private var cameraPlaceholder: some View {
        VStack {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Camera Preview")
                .font(.headline)
                .padding(.top)

            Text("Take up to 3 photos (grain, end grain, bark)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Camera Access Required")
                .font(.headline)
            Text("Go to Settings → Wood Identifier → Camera to enable access.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Actions

    private func captureAndAdd() async {
        guard selectedPhotos.count < 3 else { return }
        do {
            let image = try await cameraManager.capturePhoto()
            await MainActor.run { selectedPhotos.append(image) }

            if showTutorial {
                await MainActor.run {
                    withAnimation {
                        showTutorial = false
                        UserDefaults.standard.set(true, forKey: "hasSeenFirstScanTutorial")
                    }
                }
            }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }

    private func loadPickerItems(_ items: [PhotosPickerItem]) async {
        var images: [UIImage] = []
        for item in items.prefix(3) {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data) {
                images.append(img)
            }
        }
        await MainActor.run {
            selectedPhotos = images
            pickerItems = []
        }
    }

    private func identifyPhotos() async {
        await MainActor.run { isIdentifying = true }
        do {
            let result = try await identificationService.identifyFromMultiplePhotos(selectedPhotos)
            await MainActor.run {
                identificationResult = result
                isIdentifying = false
                showResults = true
            }
        } catch {
            await MainActor.run {
                isIdentifying = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Scan Results Sheet

struct ScanResultsSheet: View {
    let result: IdentificationResult
    @Environment(\.dismiss) private var dismiss
    @State private var showFeedback = false
    @State private var selectedMatchForFeedback: WoodMatch?

    var body: some View {
        NavigationStack {
            List {
                if result.isOfflineResult {
                    Section {
                        Label("Offline Mode — results may be less accurate", systemImage: "wifi.slash")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                }

                Section("Top Matches") {
                    ForEach(result.matches) { match in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(match.commonName)
                                    .font(.headline)
                                Spacer()
                                Text("\(Int(match.confidence * 100))%")
                                    .font(.headline)
                                    .foregroundStyle(confidenceColor(match.confidence))
                            }

                            Text(match.scientificName)
                                .font(.subheadline)
                                .italic()
                                .foregroundStyle(.secondary)

                            if !match.properties.isEmpty {
                                FlowLayout(spacing: 4) {
                                    ForEach(match.properties.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                        Text("\(key): \(value)")
                                            .font(.caption2)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color(.systemGray5))
                                            .clipShape(Capsule())
                                    }
                                }
                            }

                            if !match.similarSpecies.isEmpty {
                                Text("Similar: \(match.similarSpecies.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    Button("Not right? Suggest correction") {
                        selectedMatchForFeedback = result.matches.first
                        showFeedback = true
                    }
                }

                Section {
                    Text("\(result.scansRemaining) free scans remaining today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showFeedback) {
                FeedbackSheet(originalMatch: selectedMatchForFeedback)
            }
        }
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.7 { return .green }
        if confidence >= 0.4 { return .orange }
        return .red
    }
}

// MARK: - Simple Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = y + rowHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

// MARK: - Feedback Sheet

struct FeedbackSheet: View {
    let originalMatch: WoodMatch?
    @Environment(\.dismiss) private var dismiss
    @State private var correctedName = ""

    var body: some View {
        NavigationStack {
            Form {
                if let match = originalMatch {
                    Section("AI Suggested") {
                        Text(match.commonName)
                    }
                }

                Section("What species is it?") {
                    TextField("Common name (e.g. White Oak)", text: $correctedName)
                }
            }
            .navigationTitle("Suggest Correction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        if let match = originalMatch, !correctedName.isEmpty {
                            ScanFeedbackStore.shared.recordCorrection(
                                originalSpeciesId: match.speciesId,
                                correctedSpeciesId: correctedName.lowercased().replacingOccurrences(of: " ", with: "-"),
                                correctedCommonName: correctedName
                            )
                        }
                        dismiss()
                    }
                    .disabled(correctedName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    CameraView()
}
