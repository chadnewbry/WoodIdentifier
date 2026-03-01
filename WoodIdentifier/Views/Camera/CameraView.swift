import SwiftUI
import PhotosUI
import AVFoundation

struct CameraView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showTutorial = !UserDefaults.standard.bool(forKey: "hasSeenFirstScanTutorial")
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var selectedPhotos: [UIImage] = []
    @State private var isIdentifying = false
    @State private var identificationResult: IdentificationResult?
    @State private var errorMessage: String?
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var flashEnabled = false
    @State private var showPaywall = false
    @State private var multiPhotoPromptShown = false

    private let identificationService = WoodIdentificationService.shared
    private let quotaManager = ScanQuotaManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    var body: some View {
        ZStack {
            // MARK: - Full-screen camera preview
            if cameraManager.permissionGranted {
                CameraPreviewView(session: cameraManager.captureSession)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            // Dark gradient at top and bottom for readability
            VStack {
                LinearGradient(colors: [.black.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 120)
                Spacer()
                LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 240)
            }
            .ignoresSafeArea()

            // MARK: - Permission denied overlay
            if !cameraManager.permissionGranted {
                permissionDeniedOverlay
            }

            // MARK: - Main UI overlay
            VStack(spacing: 0) {
                // Top bar: flash toggle, offline badge, scan counter
                topBar
                    .padding(.top, 8)

                // Photo guidance
                if let guidance = cameraManager.photoGuidance {
                    Label(guidance.rawValue, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.yellow, in: Capsule())
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Multi-photo strip
                if !selectedPhotos.isEmpty {
                    multiPhotoStrip
                        .padding(.top, 12)
                }

                // Multi-photo prompt after first capture
                if selectedPhotos.count == 1 && !multiPhotoPromptShown {
                    multiPhotoPrompt
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()

                // Bottom controls
                bottomControls
                    .padding(.bottom, 8)
            }
            .animation(.easeInOut(duration: 0.3), value: selectedPhotos.count)

            // MARK: - Loading overlay
            if isIdentifying {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .transition(.opacity)

                TreeRingLoadingView()
                    .transition(.scale.combined(with: .opacity))
            }

            FirstScanTutorialOverlay(isVisible: $showTutorial)
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(item: $identificationResult) { result in
            ScanResultsSheet(result: result, photos: selectedPhotos)
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(isDismissable: true)
        }
        .onAppear {
            cameraManager.setupSession()
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Flash toggle
            Button {
                flashEnabled.toggle()
                cameraManager.setFlashMode(flashEnabled ? .on : .off)
            } label: {
                Image(systemName: flashEnabled ? "bolt.fill" : "bolt.slash.fill")
                    .font(.title3)
                    .foregroundStyle(flashEnabled ? .yellow : .white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .disabled(!cameraManager.permissionGranted)

            Spacer()

            // Offline badge
            if !networkMonitor.isConnected {
                Label("Offline", systemImage: "wifi.slash")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.orange, in: Capsule())
            }

            Spacer()

            // Scan counter badge
            if !subscriptionManager.isProUser {
                HStack(spacing: 6) {
                    Text("\(quotaManager.scansRemaining) scans left")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                    Button {
                        showPaywall = true
                    } label: {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial, in: Capsule())
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                    Text("Pro")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Multi-Photo Strip

    private var multiPhotoStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(selectedPhotos.enumerated()), id: \.offset) { index, photo in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(.white.opacity(0.5), lineWidth: 1)
                            )

                        Button {
                            withAnimation {
                                let i = index
                                selectedPhotos.remove(at: i)
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .black.opacity(0.6))
                        }
                        .offset(x: 6, y: -6)
                    }
                }

                if selectedPhotos.count < 3 {
                    let labels = ["grain", "end grain", "bark"]
                    let nextLabel = labels[min(selectedPhotos.count, labels.count - 1)]
                    VStack(spacing: 2) {
                        Image(systemName: "plus")
                            .font(.title3)
                        Text(nextLabel)
                            .font(.system(size: 9))
                    }
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 56, height: 56)
                    .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 64)
    }

    // MARK: - Multi-Photo Prompt

    private var multiPhotoPrompt: some View {
        HStack(spacing: 8) {
            Image(systemName: "camera.on.rectangle")
                .foregroundStyle(.white)
            Text("Add more photos for better accuracy")
                .font(.caption.weight(.medium))
                .foregroundStyle(.white)
            Spacer()
            Button {
                withAnimation { multiPhotoPromptShown = true }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.horizontal, 24)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Identify button (visible when photos are captured)
            if !selectedPhotos.isEmpty {
                Button {
                    Task { await identifyPhotos() }
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Identify Wood")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.brown, in: Capsule())
                }
                .disabled(isIdentifying)
                .padding(.horizontal, 40)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Main controls row: library, shutter, clear/placeholder
            HStack(spacing: 0) {
                // Photo library picker
                PhotosPicker(selection: $pickerItems, maxSelectionCount: 3, matching: .images) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .onChange(of: pickerItems) { _, items in
                    Task { await loadPickerItems(items) }
                }

                Spacer()

                // Shutter button
                Button {
                    Task { await captureAndAdd() }
                } label: {
                    ZStack {
                        Circle()
                            .stroke(.white, lineWidth: 4)
                            .frame(width: 72, height: 72)
                        Circle()
                            .fill(.white)
                            .frame(width: 62, height: 62)
                    }
                }
                .disabled(!cameraManager.permissionGranted || selectedPhotos.count >= 3 || isIdentifying)
                .opacity((!cameraManager.permissionGranted || selectedPhotos.count >= 3) ? 0.4 : 1)

                Spacer()

                // Clear button or spacer
                if !selectedPhotos.isEmpty {
                    Button {
                        withAnimation {
                            selectedPhotos.removeAll()
                            identificationResult = nil
                            errorMessage = nil
                            multiPhotoPromptShown = false
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                } else {
                    Color.clear.frame(width: 50, height: 50)
                }
            }
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Permission Denied Overlay

    private var permissionDeniedOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 56))
                .foregroundStyle(.white.opacity(0.6))

            Text("Camera Access Required")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)

            Text("Wood Identifier needs camera access to scan and identify wood species.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                CameraPermissionManager.shared.openSettings()
            } label: {
                Text("Open Settings")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(.brown, in: Capsule())
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Actions

    private func captureAndAdd() async {
        guard selectedPhotos.count < 3 else { return }
        guard quotaManager.canScan else {
            await MainActor.run { showPaywall = true }
            return
        }

        do {
            let image = try await cameraManager.capturePhoto()
            await MainActor.run {
                withAnimation { selectedPhotos.append(image) }
            }

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
            withAnimation { selectedPhotos = images }
            pickerItems = []
        }
    }

    private func identifyPhotos() async {
        guard quotaManager.canScan else {
            showPaywall = true
            return
        }

        await MainActor.run {
            withAnimation { isIdentifying = true }
        }

        do {
            let result = try await identificationService.identifyFromMultiplePhotos(selectedPhotos)
            quotaManager.recordScan()
            let photoData = selectedPhotos.first?.jpegData(compressionQuality: 0.7) ?? Data()
            await MainActor.run {
                withAnimation { isIdentifying = false }
                identificationResult = result
                try? ScanResult.create(from: result, photoData: photoData, in: modelContext)
                ReviewPromptManager.requestReviewIfAppropriate()
            }
        } catch let error as WoodIdentificationError {
            await MainActor.run {
                withAnimation { isIdentifying = false }
                switch error {
                case .quotaExceeded:
                    showPaywall = true
                default:
                    errorMessage = error.localizedDescription
                }
            }
        } catch {
            await MainActor.run {
                withAnimation { isIdentifying = false }
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Scan Results Sheet

struct ScanResultsSheet: View {
    let result: IdentificationResult
    var photos: [UIImage] = []
    @Environment(\.dismiss) private var dismiss
    @State private var showFeedback = false
    @State private var selectedMatchForFeedback: WoodMatch?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Photo thumbnail(s)
                    if !photos.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(photos.enumerated()), id: \.offset) { _, photo in
                                    Image(uiImage: photo)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    if result.isOfflineResult {
                        Label("Offline Mode — results may be less accurate", systemImage: "wifi.slash")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.orange)
                            .padding(.horizontal)
                    }

                    // Matches
                    if result.matches.isEmpty {
                        unidentifiableView
                    } else {
                        ForEach(result.matches) { match in
                            matchCard(match)
                        }
                    }

                    // Actions
                    VStack(spacing: 12) {
                        if !result.matches.isEmpty {
                            Button {
                                selectedMatchForFeedback = result.matches.first
                                showFeedback = true
                            } label: {
                                HStack {
                                    Image(systemName: "hand.thumbsdown")
                                    Text("Not right?")
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }

                            Button {
                                // TODO: Pro-only save to collection
                            } label: {
                                HStack {
                                    Image(systemName: "folder.badge.plus")
                                    Text("Save to Collection")
                                    Image(systemName: "crown.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.yellow)
                                }
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.brown)
                            }
                        }
                    }
                    .padding(.top, 8)

                    // Scans remaining
                    if result.scansRemaining < 4 {
                        Text("\(result.scansRemaining) scans remaining today")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.bottom)
                    }
                }
                .padding(.top, 20)
            }
            .background(Color(.systemGroupedBackground))
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
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func matchCard(_ match: WoodMatch) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                // Grain thumbnail placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.brown.opacity(0.15))
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: "leaf.fill")
                            .foregroundStyle(.brown.opacity(0.4))
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(match.commonName)
                        .font(.headline)
                    Text(match.scientificName)
                        .font(.subheadline)
                        .italic()
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(Int(match.confidence * 100))%")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(confidenceColor(match.confidence))
            }

            // Confidence bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(confidenceColor(match.confidence))
                        .frame(width: geo.size.width * match.confidence)
                }
            }
            .frame(height: 6)

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
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private var unidentifiableView: some View {
        VStack(spacing: 12) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("We couldn't identify this wood.")
                .font(.headline)
            Text("Try a closer shot of the grain.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 32)
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.7 { return .green }
        if confidence >= 0.4 { return .orange }
        return .red
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
