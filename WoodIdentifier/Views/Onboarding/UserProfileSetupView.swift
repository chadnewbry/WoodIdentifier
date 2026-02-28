import SwiftUI

enum WoodInterest: String, CaseIterable, Identifiable {
    case woodworker = "Woodworker"
    case furnitureBuyer = "Furniture Buyer"
    case hobbyist = "Hobbyist"
    case natureLover = "Nature Lover"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .woodworker: return "hammer.fill"
        case .furnitureBuyer: return "chair.lounge.fill"
        case .hobbyist: return "paintbrush.fill"
        case .natureLover: return "leaf.fill"
        }
    }
}

struct UserProfileSetupView: View {
    @Binding var isPresented: Bool
    @State private var selectedInterests: Set<WoodInterest> = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("What brings you here?")
                    .font(.title2.bold())
                    .padding(.top)

                Text("Select your interests to personalize your experience")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(WoodInterest.allCases) { interest in
                        InterestButton(
                            interest: interest,
                            isSelected: selectedInterests.contains(interest)
                        ) {
                            if selectedInterests.contains(interest) {
                                selectedInterests.remove(interest)
                            } else {
                                selectedInterests.insert(interest)
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()

                Button {
                    saveInterests()
                    isPresented = false
                } label: {
                    Text(selectedInterests.isEmpty ? "Skip" : "Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.brown)
                .padding(.horizontal, 40)
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") {
                        isPresented = false
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func saveInterests() {
        let values = selectedInterests.map(\.rawValue)
        UserDefaults.standard.set(values, forKey: "userInterests")
    }
}

private struct InterestButton: View {
    let interest: WoodInterest
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: interest.systemImage)
                    .font(.title2)
                Text(interest.rawValue)
                    .font(.subheadline.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(isSelected ? Color.brown.opacity(0.15) : Color(.systemGray6))
            .foregroundStyle(isSelected ? .brown : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.brown : .clear, lineWidth: 2)
            )
        }
    }
}

#Preview {
    UserProfileSetupView(isPresented: .constant(true))
}
