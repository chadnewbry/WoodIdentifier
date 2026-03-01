import SwiftUI
import SwiftData

struct WoodDatabaseView: View {
    @Query(sort: \WoodSpecies.name) private var allSpecies: [WoodSpecies]
    @State private var viewModel = BrowseViewModel()
    @State private var displayLimit = 50
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall = false

    private var filteredSpecies: [WoodSpecies] {
        viewModel.filteredAndSorted(allSpecies)
    }

    private var freeSpeciesCount: Int { 50 }

    private var woodOfTheDay: WoodSpecies? {
        WoodOfTheDayCard.todaysSpecies(from: allSpecies)
    }

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            if allSpecies.isEmpty {
                ContentUnavailableView(
                    "Wood Database",
                    systemImage: "books.vertical",
                    description: Text("Browse and search wood species. Scan wood to start building your database.")
                )
                .navigationTitle("Database")
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Wood of the Day
                        WoodOfTheDayCard(species: woodOfTheDay)
                            .padding(.top, 8)

                        // Filter chips
                        FilterChipsView(viewModel: viewModel)

                        // Sort & view mode bar
                        sortViewModeBar

                        // Best Wood For guides
                        if !viewModel.hasActiveFilters && viewModel.searchText.isEmpty {
                            BestWoodForSection(allSpecies: allSpecies)
                        }

                        // Results count
                        HStack {
                            Text("\(filteredSpecies.count) species")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)

                        // Species grid/list
                        if viewModel.viewMode == .grid {
                            gridView
                        } else {
                            listView
                        }

                        // Load more button for free tier
                        if displayLimit < filteredSpecies.count {
                            Button {
                                withAnimation { displayLimit += 50 }
                            } label: {
                                Text("Load More")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 24)
                }
                .navigationTitle("Database")
                .searchable(text: $viewModel.searchText, prompt: "Search by name or scientific name")
                .fullScreenCover(isPresented: $showPaywall) {
                    PaywallView(isDismissable: true)
                }
                .onSubmit(of: .search) {
                    viewModel.addRecentSearch(viewModel.searchText)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            viewModel.showJankaScale = true
                        } label: {
                            Image(systemName: "ruler")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            withAnimation {
                                viewModel.isCompareMode.toggle()
                                if !viewModel.isCompareMode {
                                    viewModel.compareSelections.removeAll()
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.left.arrow.right")
                                if viewModel.isCompareMode {
                                    Text("\(viewModel.compareSelections.count)/2")
                                        .font(.caption2)
                                }
                            }
                        }
                        .tint(viewModel.isCompareMode ? .accent : nil)
                    }
                }
                .sheet(isPresented: $viewModel.showJankaScale) {
                    JankaScaleView(species: allSpecies)
                }
                .sheet(isPresented: $viewModel.showCompareSheet, onDismiss: {
                    viewModel.compareSelections.removeAll()
                    viewModel.isCompareMode = false
                }) {
                    if viewModel.compareSelections.count == 2 {
                        CompareView(
                            speciesA: viewModel.compareSelections[0],
                            speciesB: viewModel.compareSelections[1]
                        )
                    }
                }
                .overlay {
                    // Recent searches overlay
                    if !viewModel.recentSearches.isEmpty && viewModel.searchText.isEmpty {
                        recentSearchesOverlay
                    }
                }
            }
        }
    }

    // MARK: - Sort & View Mode

    private var sortViewModeBar: some View {
        HStack {
            Menu {
                ForEach(SortOption.allCases) { option in
                    Button {
                        viewModel.sortOption = option
                    } label: {
                        HStack {
                            Text(option.rawValue)
                            if viewModel.sortOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down")
                    Text(viewModel.sortOption.rawValue)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            Picker("View", selection: $viewModel.viewMode) {
                Image(systemName: "square.grid.2x2").tag(ViewMode.grid)
                Image(systemName: "list.bullet").tag(ViewMode.list)
            }
            .pickerStyle(.segmented)
            .frame(width: 100)
        }
        .padding(.horizontal)
    }

    // MARK: - Grid View

    private var gridView: some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(Array(filteredSpecies.prefix(displayLimit).enumerated()), id: \.element.id) { index, species in
                let isFree = subscriptionManager.isProUser || index < freeSpeciesCount || species.isFreeSpecies
                let isSelected = viewModel.compareSelections.contains(where: { $0.id == species.id })

                if viewModel.isCompareMode {
                    Button {
                        viewModel.toggleCompareSelection(species)
                    } label: {
                        SpeciesGridCard(
                            species: species,
                            isFree: isFree,
                            isSelected: isSelected,
                            isCompareMode: true
                        )
                    }
                    .buttonStyle(.plain)
                } else if isFree {
                    NavigationLink(destination: SpeciesDetailView(species: species)) {
                        SpeciesGridCard(species: species, isFree: true)
                    }
                    .buttonStyle(.plain)
                } else {
                    SpeciesGridCard(species: species, isFree: false)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - List View

    private var listView: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(filteredSpecies.prefix(displayLimit).enumerated()), id: \.element.id) { index, species in
                let isFree = subscriptionManager.isProUser || index < freeSpeciesCount || species.isFreeSpecies
                let isSelected = viewModel.compareSelections.contains(where: { $0.id == species.id })

                if viewModel.isCompareMode {
                    Button {
                        viewModel.toggleCompareSelection(species)
                    } label: {
                        SpeciesListRow(
                            species: species,
                            isFree: isFree,
                            isSelected: isSelected,
                            isCompareMode: true
                        )
                        .padding(.horizontal)
                    }
                    .buttonStyle(.plain)
                } else if isFree {
                    NavigationLink(destination: SpeciesDetailView(species: species)) {
                        SpeciesListRow(species: species, isFree: true)
                            .padding(.horizontal)
                    }
                    .buttonStyle(.plain)
                } else {
                    SpeciesListRow(species: species, isFree: false)
                        .padding(.horizontal)
                }

                Divider().padding(.horizontal)
            }
        }
    }

    // MARK: - Recent Searches

    private var recentSearchesOverlay: some View {
        VStack {
            // This intentionally doesn't block the main content
            // It shows as a subtle section; a full overlay is too aggressive
            EmptyView()
        }
    }
}

#Preview {
    WoodDatabaseView()
}
