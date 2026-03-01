import SwiftUI
import SwiftData

struct ScanHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScanResult.scanDate, order: .reverse) private var allScans: [ScanResult]
    @Query(sort: \CollectionItem.dateAdded, order: .reverse) private var collectionItems: [CollectionItem]

    @State private var selectedTab: HistoryTab = .history
    @State private var searchText = ""
    @State private var isPro = false // TODO: wire to RevenueCat
    @State private var showUpgradePrompt = false
    @State private var selectedScan: ScanResult?

    enum HistoryTab: String, CaseIterable {
        case history = "History"
        case collection = "Collection"
    }

    private var filteredScans: [ScanResult] {
        let scans = searchText.isEmpty ? allScans : allScans.filter {
            $0.topMatch?.commonName.localizedCaseInsensitiveContains(searchText) == true
        }
        return isPro ? scans : Array(scans.prefix(10))
    }

    private var recentScans: [ScanResult] {
        Array(allScans.prefix(5))
    }

    private var uniqueSpeciesCount: Int {
        Set(allScans.compactMap { $0.topMatch?.commonName }).count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                statsBanner
                tabPicker
                
                switch selectedTab {
                case .history:
                    historyContent
                case .collection:
                    collectionContent
                }
            }
            .navigationTitle("My Scans")
            .searchable(text: $searchText, prompt: "Search species or date")
            .sheet(item: $selectedScan) { scan in
                ScanDetailSheet(scan: scan)
            }
        }
    }

    // MARK: - Stats Banner

    private var statsBanner: some View {
        HStack(spacing: 20) {
            StatPill(value: "\(allScans.count)", label: "Scans")
            StatPill(value: "\(uniqueSpeciesCount)", label: "Species")
            if isPro {
                StatPill(value: "\(collectionItems.count)", label: "Saved")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private var tabPicker: some View {
        Picker("Tab", selection: $selectedTab) {
            ForEach(HistoryTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - History

    @ViewBuilder
    private var historyContent: some View {
        if allScans.isEmpty {
            ContentUnavailableView {
                Label("No Scans Yet", systemImage: "camera.viewfinder")
            } description: {
                Text("Scan your first wood! 📸")
            } actions: {
                // Camera shortcut could go here
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Recent carousel
                    if !recentScans.isEmpty {
                        recentCarousel
                    }

                    // Full list
                    ForEach(Array(filteredScans.enumerated()), id: \.element.id) { index, scan in
                        if !isPro && index == 10 {
                            upgradePromptRow
                        } else {
                            ScanHistoryRow(scan: scan)
                                .onTapGesture { selectedScan = scan }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        modelContext.delete(scan)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
        }
    }

    private var recentCarousel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(recentScans) { scan in
                        RecentScanCard(scan: scan)
                            .onTapGesture { selectedScan = scan }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
    }

    private var upgradePromptRow: some View {
        VStack(spacing: 12) {
            Divider()
            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Text("Upgrade for Full History")
                    .font(.headline)
                Text("Free accounts see the last 10 scans. Go Pro for unlimited history and collection features.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Upgrade to Pro") {
                    showUpgradePrompt = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
            .padding()
        }
    }

    // MARK: - Collection

    @ViewBuilder
    private var collectionContent: some View {
        if !isPro {
            ContentUnavailableView {
                Label("Pro Feature", systemImage: "star.fill")
            } description: {
                Text("Upgrade to Pro to save species to your collection with notes and project tags.")
            } actions: {
                Button("Upgrade to Pro") {
                    showUpgradePrompt = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
        } else if collectionItems.isEmpty {
            ContentUnavailableView {
                Label("No Collection Items", systemImage: "bookmark")
            } description: {
                Text("Save species to your collection from any scan result to keep notes and organize by project.")
            }
        } else {
            List {
                ForEach(collectionItems) { item in
                    CollectionItemRow(item: item)
                }
                .onDelete { offsets in
                    for i in offsets {
                        modelContext.delete(collectionItems[i])
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}

// MARK: - Stat Pill

private struct StatPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Scan History Row

struct ScanHistoryRow: View {
    let scan: ScanResult

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let uiImage = UIImage(data: scan.photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.quaternary)
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.tertiary)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                if let match = scan.topMatch {
                    Text(match.commonName)
                        .font(.headline)
                    HStack(spacing: 6) {
                        ConfidenceBadge(confidence: match.confidence)
                        if let loc = scan.locationName {
                            Text("· \(loc)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("Unknown")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                Text(scan.scanDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Confidence Badge

struct ConfidenceBadge: View {
    let confidence: Double

    var body: some View {
        Text("\(Int(confidence * 100))%")
            .font(.caption.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(confidence >= 0.7 ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
            .foregroundStyle(confidence >= 0.7 ? .green : .orange)
            .clipShape(Capsule())
    }
}

// MARK: - Recent Scan Card

struct RecentScanCard: View {
    let scan: ScanResult

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let uiImage = UIImage(data: scan.photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 140, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.quaternary)
                    .frame(width: 140, height: 100)
            }

            if let match = scan.topMatch {
                Text(match.commonName)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                ConfidenceBadge(confidence: match.confidence)
            }

            Text(scan.scanDate.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 140)
    }
}

// MARK: - Preview

#Preview {
    ScanHistoryView()
        .modelContainer(PersistenceService.previewContainer)
}
