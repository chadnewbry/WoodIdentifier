import SwiftUI

struct FilterChipsView: View {
    @Bindable var viewModel: BrowseViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChipMenu(title: "Type", selection: $viewModel.typeFilter, options: WoodTypeFilter.allCases)
                FilterChipMenu(title: "Hardness", selection: $viewModel.hardnessFilter, options: HardnessFilter.allCases)
                FilterChipMenu(title: "Region", selection: $viewModel.regionFilter, options: RegionFilter.allCases)
                FilterChipMenu(title: "Price", selection: $viewModel.priceFilter, options: PriceFilter.allCases)
                FilterChipMenu(title: "Use", selection: $viewModel.useFilter, options: UseFilter.allCases)
                FilterChipMenu(title: "Color", selection: $viewModel.colorFilter, options: ColorFilter.allCases)

                if viewModel.hasActiveFilters {
                    Button {
                        withAnimation { viewModel.clearFilters() }
                    } label: {
                        Label("Clear", systemImage: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct FilterChipMenu<T: RawRepresentable & CaseIterable & Identifiable & Hashable>: View where T.RawValue == String {
    let title: String
    @Binding var selection: T
    let options: [T]

    private var isActive: Bool {
        selection.rawValue != "All"
    }

    var body: some View {
        Menu {
            ForEach(options) { option in
                Button {
                    withAnimation { selection = option }
                } label: {
                    HStack {
                        Text(option.rawValue)
                        if selection.rawValue == option.rawValue {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(isActive ? selection.rawValue : title)
                    .font(.caption)
                    .fontWeight(isActive ? .semibold : .regular)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isActive ? Color.accentColor.opacity(0.15) : Color(.systemGray6))
            .foregroundStyle(isActive ? .accent : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isActive ? Color.accentColor.opacity(0.3) : .clear, lineWidth: 1)
            )
        }
    }
}
