import SwiftUI

// MARK: - Discover Categories

private struct DiscoverCategory: Identifiable {
    let id: String
    let label: String
    let emoji: String
}

private let discoverCategories: [DiscoverCategory] = [
    DiscoverCategory(id: "music", label: "Live Music", emoji: "\u{1F3B6}"),
    DiscoverCategory(id: "theater", label: "Theater & Shows", emoji: "\u{1F3AD}"),
    DiscoverCategory(id: "museum", label: "Museums & Art", emoji: "\u{1F3A8}"),
    DiscoverCategory(id: "food", label: "Food & Drink", emoji: "\u{1F377}"),
    DiscoverCategory(id: "comedy", label: "Comedy", emoji: "\u{1F602}"),
    DiscoverCategory(id: "nightlife", label: "Nightlife", emoji: "\u{1F303}"),
    DiscoverCategory(id: "outdoor", label: "Outdoors", emoji: "\u{1F333}"),
    DiscoverCategory(id: "popup", label: "Pop-ups & Markets", emoji: "\u{1F6CD}"),
]

private let timeframes = ["tonight", "this week", "this weekend", "next week"]

// MARK: - DiscoverView

struct DiscoverView: View {
    private let api = APIService()

    @State private var events: [[String: String]] = []
    @State private var loading = false
    @State private var searched = false
    @State private var error: String?
    @State private var selectedTimeframe = "tonight"
    @State private var selectedCategory: String?
    @State private var searchCount = 0
    @State private var shownEventNames: [String] = []
    @State private var safariURL: URL?

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackgroundView()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            ShimmerTitleView("Discover NYC", fontSize: 24)

                            Text("Live events, shows & pop-ups")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textSecondary)

                            Text("\u{1F4C5} \(APIService.formatDate(Date()))")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.accent)
                                .padding(.top, 2)
                        }
                        .padding(.horizontal, 20)

                        // Timeframe chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(timeframes, id: \.self) { tf in
                                    Button {
                                        selectedTimeframe = tf
                                    } label: {
                                        Text(tf.capitalized)
                                            .font(.system(size: 12, weight: selectedTimeframe == tf ? .semibold : .regular))
                                            .foregroundStyle(selectedTimeframe == tf ? Theme.gold : Theme.textSecondary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(selectedTimeframe == tf ? Theme.goldDim : Theme.cardBackground)
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule().stroke(
                                                    selectedTimeframe == tf
                                                        ? Theme.gold.opacity(0.3)
                                                        : Theme.cardBorder,
                                                    lineWidth: 1
                                                )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Category chips
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 4) {
                                Text("\u{1F3AF} CATEGORY")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Theme.textSecondary)
                                    .tracking(1)
                                if selectedCategory != nil {
                                    Button("(clear)") {
                                        selectedCategory = nil
                                    }
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.gold)
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(discoverCategories) { cat in
                                        Button {
                                            selectedCategory = selectedCategory == cat.label ? nil : cat.label
                                        } label: {
                                            Text("\(cat.emoji) \(cat.label)")
                                                .font(.system(size: 12, weight: selectedCategory == cat.label ? .semibold : .regular))
                                                .foregroundStyle(selectedCategory == cat.label ? Theme.gold : Theme.textSecondary)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(selectedCategory == cat.label ? Theme.goldDim : Theme.cardBackground)
                                                .clipShape(Capsule())
                                                .overlay(
                                                    Capsule().stroke(
                                                        selectedCategory == cat.label
                                                            ? Theme.gold.opacity(0.3)
                                                            : Theme.cardBorder,
                                                        lineWidth: 1
                                                    )
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }

                        // Search button
                        Button {
                            Task { await searchEvents() }
                        } label: {
                            HStack(spacing: 8) {
                                if loading {
                                    ProgressView()
                                        .tint(Theme.background)
                                } else {
                                    Text("\u{1F50D}")
                                }
                                Text(loading ? "Searching NYC..." : "Find Events")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.gold)
                            .foregroundStyle(Theme.background)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .disabled(loading)
                        .padding(.horizontal, 20)

                        // Loading skeleton
                        if loading {
                            VStack(spacing: 10) {
                                ForEach(0..<6, id: \.self) { i in
                                    skeletonCard
                                        .opacity(0.3 + Double(6 - i) * 0.1)
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Error state
                        if !loading, let error {
                            VStack(spacing: 12) {
                                Text("\u{1F614}")
                                    .font(.system(size: 28))
                                Text(error)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Theme.textSecondary)
                                    .multilineTextAlignment(.center)
                                Button {
                                    Task { await searchEvents() }
                                } label: {
                                    Text("\u{1F504} Retry")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Theme.background)
                                        .padding(.horizontal, 32)
                                        .padding(.vertical, 12)
                                        .background(Theme.gold)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                        }

                        // Empty state
                        if !loading && error == nil && searched && events.isEmpty {
                            Text("No events found \u{2014} try another timeframe!")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                        }

                        // Event cards
                        if !loading && !events.isEmpty {
                            VStack(spacing: 10) {
                                ForEach(Array(events.enumerated()), id: \.offset) { index, ev in
                                    eventCard(ev, index: index)
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 16)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(item: $safariURL) { url in
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - Event Card

    private func eventCard(_ ev: [String: String], index: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(ev["emoji"] ?? "\u{1F389}")
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 4) {
                Text(ev["name"] ?? "")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(ev["desc"] ?? "")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 8) {
                    if let area = ev["area"], !area.isEmpty {
                        Text("\u{1F4CD} \(area)")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.accent)
                    }
                    if let cost = ev["cost"], !cost.isEmpty {
                        Text("\u{1F4B0} \(cost)")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    if let cat = ev["cat"], !cat.isEmpty {
                        Text(cat)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .padding(.top, 2)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 8) {
                let hasUrl = (ev["url"] ?? "").hasPrefix("http")
                Button { openEvent(ev) } label: {
                    Text(hasUrl ? "View \u{2197}" : "Search \u{2197}")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.gold)
                }
                .buttonStyle(.plain)

                Button { shareEvent(ev) } label: {
                    Text("\u{1F4E4}")
                        .font(.system(size: 14))
                        .padding(6)
                        .background(Theme.cardBorder.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Share \(ev["name"] ?? "event")")
            }
        }
        .padding(16)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(Theme.cardBorder, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { openEvent(ev) }
    }

    // MARK: - Skeleton

    private var skeletonCard: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.cardBorder)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4).fill(Theme.cardBorder).frame(width: 180, height: 14)
                RoundedRectangle(cornerRadius: 4).fill(Theme.cardBorder).frame(height: 12)
                RoundedRectangle(cornerRadius: 4).fill(Theme.cardBorder).frame(width: 100, height: 10)
            }

            Spacer()
        }
        .padding(16)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.cardBorder, lineWidth: 1))
    }

    // MARK: - Actions

    private func searchEvents() async {
        loading = true
        searched = true
        error = nil
        events = []

        do {
            let results = try await api.fetchDiscoverEvents(
                timeframe: selectedTimeframe,
                category: selectedCategory,
                searchIndex: searchCount,
                shownNames: shownEventNames
            )
            searchCount += 1
            events = results
            // Track shown names so next search avoids repeats
            let newNames = results.compactMap { $0["name"] }
            shownEventNames = (shownEventNames + newNames).suffix(60).map { $0 }
            if results.isEmpty {
                error = "No results came back. Tap retry."
            }
        } catch is CancellationError {
            error = "Search was cancelled."
        } catch let apiError as APIService.APIError {
            if apiError.statusCode == 429 || apiError.statusCode == 529 {
                self.error = "Server is busy \u{2014} tap retry in a moment."
            } else {
                self.error = "Search failed (status \(apiError.statusCode)). Tap retry."
            }
        } catch {
            let nsError = error as NSError
            if nsError.code == NSURLErrorTimedOut {
                self.error = "Search timed out \u{2014} slow connection? Tap retry."
            } else if nsError.code == NSURLErrorNotConnectedToInternet || nsError.code == NSURLErrorNetworkConnectionLost {
                self.error = "No internet connection. Check your signal and tap retry."
            } else {
                self.error = "Connection failed (\(nsError.code)). Tap retry."
            }
        }

        loading = false
    }

    private func openEvent(_ ev: [String: String]) {
        let urlString = ev["url"] ?? ""
        if urlString.hasPrefix("http"), let url = URL(string: urlString) {
            safariURL = url
        } else {
            // Fall back to Google search
            let query = "\(ev["name"] ?? "") NYC \(ev["area"] ?? "") tickets"
            if let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let url = URL(string: "https://www.google.com/search?q=\(encoded)") {
                safariURL = url
            }
        }
    }

    private func shareEvent(_ ev: [String: String]) {
        let name = ev["name"] ?? ""
        let area = ev["area"] ?? ""
        let cost = ev["cost"] ?? ""
        let desc = ev["desc"] ?? ""
        let urlString = ev["url"] ?? ""
        let hasUrl = urlString.hasPrefix("http")

        let emoji = ev["emoji"] ?? ""
        var lines: [String] = [
            "\(emoji) \(name) \u{2014} \(area)",
        ]
        if !cost.isEmpty { lines.append(cost) }
        lines.append(desc)
        if hasUrl { lines.append(urlString) }

        let text = lines.joined(separator: "\n")

        var items: [Any] = [text]
        if hasUrl, let url = URL(string: urlString) {
            items.append(url)
        }

        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }

        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootVC.view
            popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.maxY - 50, width: 0, height: 0)
        }
        rootVC.present(activityVC, animated: true)
    }
}

// MARK: - URL + Identifiable (for fullScreenCover)

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

// Reuses SafariView from ResultCardView.swift

// MARK: - Preview

#Preview {
    DiscoverView()
}
