import SwiftUI
import SwiftData

/// Sheet showing full details of a past scan, similar to species detail but with the original photo.
struct ScanDetailSheet: View {
    let scan: ScanResult
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showAddToCollection = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Original scan photo
                    if let uiImage = UIImage(data: scan.photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                    }

                    if let match = scan.topMatch {
                        VStack(spacing: 8) {
                            Text(match.commonName)
                                .font(.title.bold())
                            Text(match.scientificName)
                                .font(.subheadline)
                                .italic()
                                .foregroundStyle(.secondary)
                            ConfidenceBadge(confidence: match.confidence)
                        }

                        // Properties
                        GroupBox("Details") {
                            VStack(alignment: .leading, spacing: 8) {
                                DetailRow(label: "Grain Pattern", value: match.grainPattern)
                                DetailRow(label: "Typical Uses", value: match.typicalUses)
                                if let hardness = match.hardness {
                                    DetailRow(label: "Janka Hardness", value: "\(hardness) lbf")
                                }
                            }
                        }
                        .padding(.horizontal)

                        if !match.similarSpecies.isEmpty {
                            GroupBox("Similar Species") {
                                FlowLayout(spacing: 8) {
                                    ForEach(match.similarSpecies, id: \.self) { species in
                                        Text(species)
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(.quaternary)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Metadata
                    GroupBox("Scan Info") {
                        VStack(alignment: .leading, spacing: 8) {
                            DetailRow(label: "Date", value: scan.scanDate.formatted(date: .long, time: .shortened))
                            if let loc = scan.locationName {
                                DetailRow(label: "Location", value: loc)
                            }
                            DetailRow(label: "Mode", value: scan.isOfflineResult ? "Offline" : "Online")
                        }
                    }
                    .padding(.horizontal)

                    if subscriptionManager.isProUser {
                        Button {
                            showAddToCollection = true
                        } label: {
                            Label("Save to Collection", systemImage: "bookmark.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showAddToCollection) {
                AddToCollectionSheet(scan: scan)
            }
        }
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        if !value.isEmpty {
            HStack(alignment: .top) {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 120, alignment: .leading)
                Text(value)
                    .font(.subheadline)
            }
        }
    }
}

#Preview {
    Text("Preview")
}
