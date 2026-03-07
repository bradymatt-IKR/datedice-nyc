import SwiftUI

// MARK: - Sort Mode

private enum HistorySortMode: String, CaseIterable {
    case recent = "Recent"
    case topRated = "Top Rated"
}

struct HistoryView: View {
    @Environment(AppViewModel.self) private var vm
    @State private var sortMode: HistorySortMode = .recent

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackgroundView()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ShimmerTitleView("History", fontSize: 24)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        if vm.history.isEmpty {
                            emptyState
                        } else {
                            // Stats bar + sort toggle
                            HStack(spacing: 12) {
                                StatPill(
                                    count: vm.completedDates.count,
                                    label: "completed",
                                    color: Theme.green
                                )
                                StatPill(
                                    count: vm.upcomingDates.count,
                                    label: "upcoming",
                                    color: Theme.gold
                                )

                                Spacer()

                                // Sort toggle — only visible when there are rated items
                                if vm.completedDates.contains(where: { $0.rating != nil }) {
                                    sortToggle
                                }
                            }
                            .padding(.horizontal, 20)

                            // Content based on sort mode
                            switch sortMode {
                            case .recent:
                                recentView
                            case .topRated:
                                topRatedView
                            }

                            // Date Stats
                            DateStatsView(history: vm.history)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                        }

                        Spacer(minLength: 40)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Sort Toggle

    private var sortToggle: some View {
        HStack(spacing: 0) {
            ForEach(HistorySortMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        sortMode = mode
                    }
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(sortMode == mode ? Theme.gold : Theme.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(sortMode == mode ? Theme.gold.opacity(0.15) : .clear)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Color.white.opacity(0.04))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Theme.cardBorder.opacity(0.5), lineWidth: 1))
    }

    // MARK: - Recent View (default — sectioned by status)

    private var recentView: some View {
        Group {
            // Upcoming section
            if !vm.upcomingDates.isEmpty {
                sectionHeader("Upcoming", color: Theme.gold)
                ForEach(vm.upcomingDates) { item in
                    HistoryRow(
                        item: item,
                        statusBadge: .upcoming,
                        showRating: false,
                        onRate: { rating in
                            vm.markComplete(item.id, rating: rating)
                        },
                        onRemove: {
                            vm.removeEntry(item.id)
                        }
                    )
                }
            }

            // Completed section
            if !vm.completedDates.isEmpty {
                sectionHeader("Completed", color: Theme.green)
                ForEach(vm.completedDates) { item in
                    HistoryRow(
                        item: item,
                        statusBadge: .completed,
                        showRating: true,
                        onRate: nil,
                        onRemove: {
                            vm.removeEntry(item.id)
                        }
                    )
                }
            }

            // Past Rolls section
            let rolledItems = vm.history.filter { $0.status == .rolled }
            if !rolledItems.isEmpty {
                sectionHeader("Past Rolls", color: Theme.textSecondary)
                ForEach(rolledItems) { item in
                    HistoryRow(
                        item: item,
                        statusBadge: nil,
                        showRating: false,
                        onRate: nil,
                        onRemove: nil
                    )
                }
            }
        }
    }

    // MARK: - Top Rated View (flat list sorted by rating)

    private var topRatedView: some View {
        Group {
            let rated = vm.history
                .filter { $0.rating != nil }
                .sorted { ($0.rating ?? 0) > ($1.rating ?? 0) }

            let unrated = vm.history
                .filter { $0.rating == nil && $0.status != .rolled }

            if !rated.isEmpty {
                sectionHeader("Rated", color: Theme.gold)
                ForEach(rated) { item in
                    HistoryRow(
                        item: item,
                        statusBadge: nil,
                        showRating: true,
                        onRate: nil,
                        onRemove: {
                            vm.removeEntry(item.id)
                        }
                    )
                }
            }

            if !unrated.isEmpty {
                sectionHeader("Not Yet Rated", color: Theme.textSecondary)
                ForEach(unrated) { item in
                    HistoryRow(
                        item: item,
                        statusBadge: item.status == .locked ? .upcoming : nil,
                        showRating: false,
                        onRate: item.status == .locked ? { rating in
                            vm.markComplete(item.id, rating: rating)
                        } : nil,
                        onRemove: {
                            vm.removeEntry(item.id)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("\u{1F3B2}")
                .font(.system(size: 48))

            Text("No rolls yet")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Theme.text)

            Text("Roll the dice to start building your history")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
        .padding(.top, 40)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 20)
            .padding(.top, 8)
    }
}

// MARK: - Stat Pill

private struct StatPill: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Status Badge

enum HistoryBadge {
    case upcoming, completed
}

// MARK: - History Row

private struct HistoryRow: View {
    let item: Suggestion
    let statusBadge: HistoryBadge?
    let showRating: Bool
    let onRate: ((Int) -> Void)?
    let onRemove: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Text(item.emoji)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.text)

                        if let badge = statusBadge {
                            badgeView(badge)
                        }
                    }

                    HStack(spacing: 6) {
                        Text(item.area)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)

                        Text("\u{00B7}")
                            .foregroundStyle(Theme.textSecondary)

                        Text(item.lockedAt ?? item.rolledAt, style: .relative)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Spacer()

                // Remove button for locked/completed items
                if let onRemove {
                    Button {
                        onRemove()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.textSecondary.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove \(item.name)")
                }
            }

            // Rating row for locked items — "How was it?"
            if let onRate, item.status == .locked {
                HStack(spacing: 8) {
                    Text("How was it?")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)

                    StarRatingView(rating: nil, interactive: true, onRate: onRate)
                }
                .padding(.leading, 40)
            }

            // Show existing rating for completed items
            if showRating, item.status == .completed, let rating = item.rating {
                StarRatingView(rating: rating, interactive: false)
                    .padding(.leading, 40)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private func badgeView(_ badge: HistoryBadge) -> some View {
        let (text, color): (String, Color) = switch badge {
        case .upcoming: ("Upcoming", Theme.gold)
        case .completed: ("Done", Theme.green)
        }

        return Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

#Preview {
    HistoryView()
        .environment(AppViewModel())
}
