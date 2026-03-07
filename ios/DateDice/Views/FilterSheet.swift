import SwiftUI

// MARK: - FlowLayout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
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
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}

// MARK: - FilterSheet

struct FilterSheet: View {
    @Environment(AppViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss

    @State private var showCuisines = false
    @State private var showActivities = false
    @State private var showNeighborhoods = false

    var body: some View {
        @Bindable var vm = vm

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // 1. Category — single-select
                    filterSection(
                        "\u{1F3AF} What Type",
                        options: AppConstants.categories,
                        selected: vm.filters.category
                    ) { option in
                        vm.filters.category = vm.filters.category == option ? nil : option
                    }

                    // 2. Time of Day — single-select
                    filterSection(
                        "\u{1F550} When",
                        options: AppConstants.timesOfDay,
                        selected: vm.filters.timeOfDay
                    ) { option in
                        vm.filters.timeOfDay = vm.filters.timeOfDay == option ? nil : option
                    }

                    // 3. Vibe — multi-select
                    multiSection(
                        "\u{2728} Vibe",
                        options: AppConstants.vibes,
                        selected: vm.filters.vibe
                    ) { option in
                        if let index = vm.filters.vibe.firstIndex(of: option) {
                            vm.filters.vibe.remove(at: index)
                        } else {
                            vm.filters.vibe.append(option)
                        }
                    }

                    // 4. Budget — single-select
                    filterSection(
                        "\u{1F4B0} Budget",
                        options: AppConstants.budgets,
                        selected: vm.filters.budget
                    ) { option in
                        vm.filters.budget = vm.filters.budget == option ? nil : option
                    }

                    // 5. Duration — single-select
                    filterSection(
                        "\u{23F3} How Long",
                        options: AppConstants.durations,
                        selected: vm.filters.duration
                    ) { option in
                        vm.filters.duration = vm.filters.duration == option ? nil : option
                    }

                    // 6. Cuisine — expandable multi-select
                    expandableMultiSection(
                        "\u{1F37D} Cuisine",
                        options: AppConstants.cuisines,
                        selected: vm.filters.cuisine,
                        isExpanded: $showCuisines
                    ) { option in
                        if let index = vm.filters.cuisine.firstIndex(of: option) {
                            vm.filters.cuisine.remove(at: index)
                        } else {
                            vm.filters.cuisine.append(option)
                        }
                    }

                    // 7. Activity Type — expandable single-select
                    expandableSection(
                        "\u{1F3AD} Activity Type",
                        options: AppConstants.activityTypes,
                        selected: vm.filters.activityType,
                        isExpanded: $showActivities
                    ) { option in
                        vm.filters.activityType = vm.filters.activityType == option ? nil : option
                    }

                    // 8. Neighborhood — expandable, grouped by borough
                    neighborhoodSection()

                    // Roll the Dice button
                    Button {
                        dismiss()
                        Task {
                            await vm.roll()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text("\u{1F3B2}")
                            Text("Roll the Dice")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.gold)
                        .foregroundStyle(Theme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .scrollIndicators(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") {
                        vm.filters.clear()
                    }
                    .foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.gold)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.background)
    }

    // MARK: - Section Title

    private func sectionTitle(_ title: String, count: Int = 0) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1.5)
            if count > 0 {
                Text("\u{00B7} \(count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.gold)
            }
        }
    }

    // MARK: - Single-Select Section

    private func filterSection(
        _ title: String,
        options: [String],
        selected: String?,
        action: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(title)
            FlowLayout(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    ChipView(
                        label: option,
                        active: selected == option,
                        action: { action(option) }
                    )
                }
            }
        }
    }

    // MARK: - Multi-Select Section

    private func multiSection(
        _ title: String,
        options: [String],
        selected: [String],
        action: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(title, count: selected.count)
            FlowLayout(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    ChipView(
                        label: option,
                        active: selected.contains(option),
                        action: { action(option) }
                    )
                }
            }
        }
    }

    // MARK: - Expandable Single-Select Section

    private func expandableSection(
        _ title: String,
        options: [String],
        selected: String?,
        isExpanded: Binding<Bool>,
        action: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.wrappedValue.toggle()
                }
            } label: {
                HStack {
                    sectionTitle(title)
                    Spacer()
                    if let selected {
                        Text(selected)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Theme.gold)
                    }
                    Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded.wrappedValue {
                FlowLayout(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        ChipView(
                            label: option,
                            active: selected == option,
                            small: true,
                            action: { action(option) }
                        )
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Expandable Multi-Select Section

    private func expandableMultiSection(
        _ title: String,
        options: [String],
        selected: [String],
        isExpanded: Binding<Bool>,
        action: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.wrappedValue.toggle()
                }
            } label: {
                HStack {
                    sectionTitle(title, count: selected.count)
                    Spacer()
                    if !selected.isEmpty {
                        Text(selected.count == 1 ? selected[0] : "\(selected.count) selected")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Theme.gold)
                    }
                    Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded.wrappedValue {
                FlowLayout(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        ChipView(
                            label: option,
                            active: selected.contains(option),
                            small: true,
                            action: { action(option) }
                        )
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Neighborhood Section

    private func neighborhoodSection() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showNeighborhoods.toggle()
                }
            } label: {
                HStack {
                    sectionTitle("\u{1F3D8} Neighborhood", count: vm.filters.neighborhood.count)
                    Spacer()

                    // Near Me chip floats next to section header
                    ChipView(
                        label: "\u{1F4CD} Near Me",
                        active: vm.nearMeActive,
                        small: true,
                        action: {
                            Task { await vm.activateNearMe() }
                        }
                    )

                    if !vm.filters.neighborhood.isEmpty {
                        Text("\(vm.filters.neighborhood.count) selected")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Theme.gold)
                            .padding(.leading, 4)
                    }

                    Image(systemName: showNeighborhoods ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .buttonStyle(.plain)

            if showNeighborhoods {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(AppConstants.neighborhoods, id: \.borough) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group.borough)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(
                                    Theme.boroughColors[group.borough] ?? Theme.textSecondary
                                )
                                .textCase(.uppercase)
                                .tracking(1)

                            FlowLayout(spacing: 8) {
                                ForEach(group.hoods, id: \.self) { hood in
                                    ChipView(
                                        label: hood,
                                        active: vm.filters.neighborhood.contains(hood),
                                        small: true,
                                        action: {
                                            if let index = vm.filters.neighborhood.firstIndex(of: hood) {
                                                vm.filters.neighborhood.remove(at: index)
                                            } else {
                                                vm.filters.neighborhood.append(hood)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            FilterSheet()
                .environment(AppViewModel())
        }
}
