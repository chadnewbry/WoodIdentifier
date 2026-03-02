import SwiftUI

struct ComparePromoBanner: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Compare Woods")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("Select two species to compare hardness, workability, and more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.blue.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}

#Preview {
    ComparePromoBanner(onTap: {})
}
