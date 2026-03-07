import SwiftUI

struct DateStatsView: View {
    let history: [Suggestion]
    @State private var isExpanded = false

    private var cuisineCounts: [(String, Int)] {
        var counts: [String: Int] = [:]
        for item in history {
            if let cuisine = item.cuisine, !cuisine.isEmpty {
                counts[cuisine, default: 0] += 1
            }
        }
        return counts.sorted { $0.value > $1.value }.prefix(6).map { ($0.key, $0.value) }
    }

    private var boroughCounts: [(String, Int, Color)] {
        // Build area → borough lookup
        let lookup = buildAreaLookup()
        var counts: [String: Int] = [:]
        for item in history {
            let borough = lookup[item.area] ?? "Manhattan"
            counts[borough, default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }.map { (name, count) in
            (name, count, Theme.boroughColors[name] ?? Theme.textSecondary)
        }
    }

    var body: some View {
        if history.count >= 3 {
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text("\u{1F4CA} Your Date Stats")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.text)
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)

                if isExpanded {
                    VStack(alignment: .leading, spacing: 20) {
                        // Cuisines explored
                        if !cuisineCounts.isEmpty {
                            cuisineSection
                        }

                        // Boroughs covered
                        if !boroughCounts.isEmpty {
                            boroughSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(Theme.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Theme.cardBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - Cuisine Bar Chart

    private var cuisineSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cuisines Explored")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)

            let maxCount = cuisineCounts.first?.1 ?? 1
            ForEach(Array(cuisineCounts.enumerated()), id: \.offset) { index, item in
                HStack(spacing: 8) {
                    Text(item.0)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.text)
                        .frame(width: 80, alignment: .trailing)

                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Theme.gradient)
                            .frame(width: geo.size.width * CGFloat(item.1) / CGFloat(maxCount))
                    }
                    .frame(height: 12)

                    Text("\(item.1)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 20, alignment: .leading)
                }
                .frame(height: 18)
            }
        }
    }

    // MARK: - Borough Breakdown

    private var boroughSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Boroughs Covered")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)

            HStack(spacing: 12) {
                ForEach(Array(boroughCounts.enumerated()), id: \.offset) { _, item in
                    VStack(spacing: 4) {
                        Text("\(item.1)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(item.2)
                        Text(item.0)
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Helpers

    private func buildAreaLookup() -> [String: String] {
        var lookup: [String: String] = [:]
        for group in AppConstants.neighborhoods {
            for hood in group.hoods {
                lookup[hood] = group.borough
            }
        }
        return lookup
    }
}
