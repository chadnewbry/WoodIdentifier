import SwiftUI

struct WoodDatabaseView: View {
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Wood Database",
                systemImage: "books.vertical",
                description: Text("Browse and search wood species. Coming soon.")
            )
            .navigationTitle("Database")
            .searchable(text: $searchText, prompt: "Search wood species")
        }
    }
}

#Preview {
    WoodDatabaseView()
}
