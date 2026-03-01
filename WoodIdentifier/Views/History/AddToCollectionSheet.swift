import SwiftUI
import SwiftData

struct AddToCollectionSheet: View {
    let scan: ScanResult
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var notes = ""
    @State private var projectTag = ""

    var body: some View {
        NavigationStack {
            Form {
                if let match = scan.topMatch {
                    Section {
                        HStack {
                            if let uiImage = UIImage(data: scan.photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            VStack(alignment: .leading) {
                                Text(match.commonName).font(.headline)
                                Text(match.scientificName).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Notes") {
                    TextField("e.g., bought at Home Depot $4.50/bf", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Project Tag") {
                    TextField("e.g., Kitchen Table", text: $projectTag)
                }
            }
            .navigationTitle("Add to Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                }
            }
        }
    }

    private func save() {
        guard let match = scan.topMatch else { return }
        let item = CollectionItem(
            speciesName: match.commonName,
            scientificName: match.scientificName,
            notes: notes,
            projectTag: projectTag,
            photoData: scan.photoData,
            scanResultId: scan.id
        )
        modelContext.insert(item)
        try? modelContext.save()
    }
}

#Preview {
    Text("Preview")
}
