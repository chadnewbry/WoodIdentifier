import SwiftUI
import SwiftData

struct CollectionItemRow: View {
    @Bindable var item: CollectionItem
    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                if let data = item.photoData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.quaternary)
                        .frame(width: 50, height: 50)
                        .overlay {
                            Image(systemName: "leaf.fill")
                                .foregroundStyle(.tertiary)
                        }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.speciesName)
                        .font(.headline)

                    if !item.projectTag.isEmpty {
                        Text(item.projectTag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.15))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                Button {
                    isEditing.toggle()
                } label: {
                    Image(systemName: "pencil.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            if isEditing {
                VStack(spacing: 8) {
                    TextField("Notes", text: $item.notes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)
                    TextField("Project tag", text: $item.projectTag)
                        .textFieldStyle(.roundedBorder)
                    Button("Done") { isEditing = false }
                        .font(.caption)
                }
                .padding(.leading, 62)
            } else if !item.notes.isEmpty {
                Text(item.notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 62)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    Text("Preview")
}
