import SwiftUI
import SwiftData

struct SpeciesDetailView: View {
    @Bindable var species: WoodSpecies
    @State private var showHardnessComparison = false
    @Environment(\.modelContext) private var modelContext
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                badgeRow
                jankaSection
                propertiesGrid
                commonUsesSection

                if subscriptionManager.isProUser {
                    priceRangeSection
                    geographicOriginSection
                    confusedWithSection
                    workingTipsSection
                    sustainabilitySection
                } else {
                    proUpsellBanner
                }

                actionButtons
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: "\(species.name) (\(species.scientificName)) — Janka Hardness: \(species.hardness ?? 0) lbf") {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(isDismissable: true)
        }
        .sheet(isPresented: $showHardnessComparison) {
            HardnessComparisonSheet(species: species)
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 12) {
            if species.images.isEmpty {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: species.colorHex).gradient)
                    .frame(height: 260)
                    .overlay {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.horizontal)
            } else {
                TabView {
                    ForEach(species.images) { img in
                        AsyncImage(url: URL(string: img.url)) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(hex: species.colorHex).gradient)
                            }
                        }
                        .frame(height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 280)
                .padding(.horizontal)
            }

            VStack(spacing: 4) {
                Text(species.name)
                    .font(.title.bold())
                Text(species.scientificName)
                    .font(.subheadline)
                    .italic()
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 4)
        }
        .padding(.top, 8)
    }

    // MARK: - Badges

    private var badgeRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Badge(text: species.category, icon: species.category == "Hardwood" ? "tree.fill" : "leaf.fill", color: species.category == "Hardwood" ? .brown : .green)
                Badge(text: priceTierLabel, icon: "dollarsign.circle.fill", color: .orange)
                Badge(text: species.sustainability, icon: sustainabilityIcon, color: sustainabilityColor)
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 16)
    }

    // MARK: - Janka Hardness

    private var jankaSection: some View {
        SectionContainer(title: "Janka Hardness") {
            VStack(spacing: 12) {
                if let hardness = species.hardness {
                    Text("\(hardness) lbf")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    JankaScaleBar(value: hardness)

                    Button {
                        showHardnessComparison = true
                    } label: {
                        Label("Compare with other species", systemImage: "arrow.left.arrow.right")
                            .font(.subheadline)
                    }
                } else {
                    Text("Not available")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Properties Grid

    private var propertiesGrid: some View {
        SectionContainer(title: "Properties") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                if let density = species.density {
                    PropertyCell(label: "Density", value: String(format: "%.2f g/cm³", density), icon: "scalemass.fill")
                }
                PropertyCell(label: "Grain", value: species.grainPattern.isEmpty ? "—" : species.grainPattern, icon: "line.3.horizontal")
                PropertyCell(label: "Color", value: "", icon: "paintpalette.fill", colorHex: species.colorHex)
                PropertyCell(label: "Workability", value: "", icon: "wrench.and.screwdriver.fill", stars: species.workability)
                PropertyCell(label: "Durability", value: "", icon: "shield.fill", stars: species.durability)
                if let radial = species.shrinkageRadial, let tangential = species.shrinkageTangential {
                    PropertyCell(label: "Shrinkage", value: "R: \(String(format: "%.1f", radial))% T: \(String(format: "%.1f", tangential))%", icon: "arrow.down.right.and.arrow.up.left")
                }
            }
        }
    }

    // MARK: - Common Uses

    private var commonUsesSection: some View {
        SectionContainer(title: "Common Uses") {
            let uses = species.uses.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            if uses.isEmpty {
                Text("—").foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(uses, id: \.self) { use in
                            Text(use)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                    }
                }
            }
        }
    }

    // MARK: - Price Range (Pro)

    private var priceRangeSection: some View {
        SectionContainer(title: "Price Range") {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(priceTierLabel)
                        .font(.title3.bold())
                    Spacer()
                    Text(species.pricing)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                Text("Prices vary by region, grade, and supplier.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Geographic Origin (Pro)

    private var geographicOriginSection: some View {
        SectionContainer(title: "Geographic Origin") {
            let regions = species.region.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            if regions.isEmpty {
                Text("—").foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .frame(height: 120)
                        .overlay {
                            Image(systemName: "map.fill")
                                .font(.title)
                                .foregroundStyle(.secondary)
                        }

                    FlowLayout(spacing: 8) {
                        ForEach(regions, id: \.self) { region in
                            Text(region)
                                .font(.subheadline)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.blue.opacity(0.1), in: Capsule())
                        }
                    }
                }
            }
        }
    }

    // MARK: - Often Confused With (Pro)

    private var confusedWithSection: some View {
        let items = species.confusedWith.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        return Group {
            if !items.isEmpty {
                SectionContainer(title: "Often Confused With…") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(items, id: \.self) { name in
                                VStack(spacing: 6) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 100, height: 80)
                                        .overlay {
                                            Image(systemName: "leaf.fill")
                                                .foregroundStyle(.secondary)
                                        }
                                    Text(name)
                                        .font(.caption)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(width: 100)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Working Tips (Pro)

    private var workingTipsSection: some View {
        let tips = parseWorkingTips(species.workingTips)
        return Group {
            if !tips.isEmpty {
                SectionContainer(title: "Working Tips") {
                    VStack(spacing: 0) {
                        ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                            DisclosureGroup {
                                Text(tip.content)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .padding(.vertical, 8)
                            } label: {
                                Label(tip.title, systemImage: tip.icon)
                                    .font(.subheadline.weight(.medium))
                            }
                            if index < tips.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Sustainability (Pro)

    private var sustainabilitySection: some View {
        SectionContainer(title: "Sustainability") {
            HStack(spacing: 12) {
                Image(systemName: sustainabilityIcon)
                    .font(.title2)
                    .foregroundStyle(sustainabilityColor)
                    .frame(width: 44, height: 44)
                    .background(sustainabilityColor.opacity(0.15), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(species.sustainability)
                        .font(.headline)
                        .foregroundStyle(sustainabilityColor)
                    Text("Based on IUCN Red List / CITES data")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
    }

    // MARK: - Pro Upsell

    private var proUpsellBanner: some View {
        SectionContainer(title: "") {
            VStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.title)
                    .foregroundStyle(.orange)
                Text("Unlock Full Species Details")
                    .font(.headline)
                Text("Price range, working tips, sustainability info, similar species comparison and more.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button {
                    showPaywall = true
                } label: {
                    Text("Upgrade to Pro")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
            .padding(.vertical, 8)
        }
    }


    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 10) {
            if subscriptionManager.isProUser {
                Button {
                    species.savedToCollection.toggle()
                    try? modelContext.save()
                } label: {
                    Label(
                        species.savedToCollection ? "Saved to Collection" : "Save to Collection",
                        systemImage: species.savedToCollection ? "bookmark.fill" : "bookmark"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(species.savedToCollection ? .gray : .blue)
            }

            NavigationLink {
                CameraView()
            } label: {
                Label("Identify This Wood", systemImage: "camera.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
    }

    // MARK: - Helpers

    private var priceTierLabel: String {
        switch species.pricing {
        case "$": return "Budget"
        case "$$": return "Moderate"
        case "$$$": return "Premium"
        case "$$$$": return "Exotic"
        default: return species.pricing
        }
    }

    private var sustainabilityIcon: String {
        switch species.sustainability.lowercased() {
        case "common": return "checkmark.seal.fill"
        case "near-threatened": return "exclamationmark.triangle.fill"
        case "threatened": return "exclamationmark.triangle.fill"
        case "endangered": return "xmark.octagon.fill"
        default: return "leaf.fill"
        }
    }

    private var sustainabilityColor: Color {
        switch species.sustainability.lowercased() {
        case "common": return .green
        case "near-threatened": return .yellow
        case "threatened": return .orange
        case "endangered": return .red
        default: return .green
        }
    }

    private func parseWorkingTips(_ raw: String) -> [(title: String, content: String, icon: String)] {
        guard !raw.isEmpty else { return [] }
        let sections = raw.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        return sections.compactMap { section in
            let parts = section.components(separatedBy: ":")
            guard parts.count >= 2 else { return nil }
            let title = parts[0].trimmingCharacters(in: .whitespaces)
            let content = parts.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
            let icon: String
            switch title.lowercased() {
            case "finishing": icon = "paintbrush.fill"
            case "glue compatibility": icon = "drop.fill"
            case "tool requirements": icon = "wrench.fill"
            default: icon = "info.circle.fill"
            }
            return (title: title, content: content, icon: icon)
        }
    }
}

// MARK: - Supporting Components

struct Badge: View {
    let text: String
    let icon: String
    let color: Color

    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}

struct SectionContainer<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !title.isEmpty {
                Text(title)
                    .font(.title3.bold())
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

struct PropertyCell: View {
    let label: String
    let value: String
    let icon: String
    var colorHex: String? = nil
    var stars: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let stars {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= stars ? "star.fill" : "star")
                            .font(.caption2)
                            .foregroundStyle(i <= stars ? .orange : .gray.opacity(0.3))
                    }
                }
            } else if let hex = colorHex {
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 24, height: 24)
                    .overlay(Circle().strokeBorder(.secondary.opacity(0.3), lineWidth: 1))
            } else {
                Text(value)
                    .font(.subheadline.weight(.medium))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

struct JankaScaleBar: View {
    let value: Int
    private let maxValue: Double = 4000

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [.green, .yellow, .orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 12)

                let fraction = min(Double(value) / maxValue, 1.0)
                let xPos = fraction * geo.size.width
                Circle()
                    .fill(.white)
                    .frame(width: 20, height: 20)
                    .shadow(radius: 2)
                    .offset(x: xPos - 10)
            }
        }
        .frame(height: 20)

        HStack {
            Text("0")
            Spacer()
            Text("4000+ lbf")
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (positions, CGSize(width: maxWidth, height: y + rowHeight))
    }
}

// MARK: - Hardness Comparison Sheet

struct HardnessComparisonSheet: View {
    let species: WoodSpecies
    @Environment(\.dismiss) private var dismiss

    private let referenceWoods: [(name: String, hardness: Int)] = [
        ("Balsa", 100),
        ("Western Red Cedar", 350),
        ("Pine", 690),
        ("Walnut", 1010),
        ("White Oak", 1360),
        ("Hard Maple", 1450),
        ("Hickory", 1820),
        ("Purpleheart", 2520),
        ("Ipe", 3510),
        ("Australian Buloke", 5060),
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedWoods, id: \.name) { wood in
                    HStack {
                        Text(wood.name)
                            .fontWeight(wood.name == species.name ? .bold : .regular)
                        Spacer()
                        Text("\(wood.hardness) lbf")
                            .foregroundStyle(.secondary)
                    }
                    .listRowBackground(wood.name == species.name ? Color.orange.opacity(0.15) : Color.clear)
                }
            }
            .navigationTitle("Hardness Comparison")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var sortedWoods: [(name: String, hardness: Int)] {
        var list = referenceWoods
        if let h = species.hardness, !referenceWoods.contains(where: { $0.name == species.name }) {
            list.append((species.name, h))
        }
        return list.sorted { $0.hardness < $1.hardness }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 0.545; g = 0.271; b = 0.075
        }
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    NavigationStack {
        SpeciesDetailView(species: {
            let s = WoodSpecies(
                name: "White Oak",
                scientificName: "Quercus alba",
                speciesDescription: "A classic American hardwood.",
                category: "Hardwood",
                hardness: 1360,
                density: 0.68,
                grainPattern: "Straight to irregular",
                colorHex: "#C4A35A",
                uses: "Furniture, Flooring, Barrels, Cabinetry, Boatbuilding",
                pricing: "$$$",
                region: "Eastern North America, Central Europe",
                workability: 4,
                durability: 5,
                isFreeSpecies: true,
                workingTips: "Finishing: Takes stain beautifully; oil or lacquer recommended | Glue Compatibility: Good with PVA and epoxy | Tool Requirements: Carbide-tipped blades recommended",
                shrinkageRadial: 5.6,
                shrinkageTangential: 10.5,
                sustainability: "Common",
                confusedWith: "Red Oak, Chestnut, Ash"
            )
            return s
        }())
    }
}
