import SwiftUI
import SafariServices

struct ResultCardView: View {
    let suggestion: Suggestion
    let isFavorite: Bool
    var isLocked: Bool = false
    var onFavorite: () -> Void
    var onShare: () -> Void
    var onLockIn: (() -> Void)? = nil

    @State private var showSafari = false
    @State private var showMapChooser = false
    @State private var glowPhase = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Text(suggestion.emoji)
                    .font(.system(size: 36))

                VStack(alignment: .leading, spacing: 8) {
                    Text(suggestion.name)
                        .font(Theme.display(22))
                        .foregroundColor(Theme.gold)

                    HStack(spacing: 8) {
                        if !suggestion.area.isEmpty {
                            Text(suggestion.area)
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textSecondary)
                        }

                        if let priceRange = suggestion.priceRange, !priceRange.isEmpty {
                            Text(priceRange)
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textSecondary)
                        }

                        if let cuisine = suggestion.cuisine, !cuisine.isEmpty {
                            Text(cuisine)
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                }

                Spacer()
            }

            // Description
            Text(suggestion.desc)
                .font(.system(size: 15))
                .foregroundColor(Theme.text)
                .lineSpacing(4)

            // Address — tappable to open in map app
            if !suggestion.address.isEmpty {
                Button {
                    let apps = MapChooserService.availableApps()
                    if apps.count == 1 {
                        // Only Apple Maps — open directly
                        MapChooserService.open(apps[0], address: fullAddress)
                    } else {
                        showMapChooser = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.rose)

                        Text(suggestion.address)
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textSecondary)
                            .underline(color: Theme.textSecondary.opacity(0.3))

                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textSecondary.opacity(0.5))
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open \(suggestion.address) in maps")
            }

            // Tip
            if let tip = suggestion.tip, !tip.isEmpty {
                HStack(alignment: .top, spacing: 12) {
                    Text("\u{1F4A1}")
                        .font(.system(size: 16))

                    Text(tip)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.gold)
                        .opacity(0.9)
                        .italic()
                }
                .padding(12)
                .background(Theme.goldDim)
                .cornerRadius(10)
            }

            // Lock It In + Book row
            if let onLockIn {
                HStack(spacing: 10) {
                    if let bookingUrl = suggestion.bookingUrl,
                       !bookingUrl.isEmpty,
                       URL(string: bookingUrl) != nil {
                        Button(action: { showSafari = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "safari")
                                Text(suggestion.bookingPlatform ?? "Book")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Theme.gradient)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    Button(action: isLocked ? {} : onLockIn) {
                        HStack(spacing: 6) {
                            Text(isLocked ? "\u{2713}" : "\u{1F512}")
                                .font(.system(size: 14))
                            Text(isLocked ? "Locked In" : "Lock It In")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isLocked ? Theme.textSecondary : Theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isLocked ? Theme.cardBackground : Theme.gold)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(isLocked ? Theme.cardBorder : .clear, lineWidth: 1)
                        )
                        .opacity(isLocked ? 0.6 : 1)
                    }
                    .buttonStyle(.plain)
                    // Gold glow animation when not yet locked
                    .shadow(
                        color: isLocked || reduceMotion ? .clear : Theme.gold.opacity(glowPhase ? 0.4 : 0.15),
                        radius: glowPhase ? 14 : 8
                    )
                    .shadow(
                        color: isLocked || reduceMotion ? .clear : Theme.gold.opacity(glowPhase ? 0.18 : 0.08),
                        radius: glowPhase ? 36 : 20
                    )
                    .onAppear {
                        guard !reduceMotion else { return }
                        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                            glowPhase = true
                        }
                    }
                }
            }

            // Share + Favorite row
            HStack(spacing: 10) {
                Button(action: onShare) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 12))
                        Text("Share")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.cardBackground)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Theme.cardBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: onFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(isFavorite ? Theme.rose : Theme.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(Theme.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.cardBorder, lineWidth: 1)
        )
        .fullScreenCover(isPresented: $showSafari) {
            if let bookingUrl = suggestion.bookingUrl,
               !bookingUrl.isEmpty,
               let url = URL(string: bookingUrl) {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
        .confirmationDialog("Open in Maps", isPresented: $showMapChooser) {
            ForEach(MapChooserService.availableApps()) { app in
                Button(app.name) {
                    MapChooserService.open(app, address: fullAddress)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Helpers

    private var fullAddress: String {
        let addr = suggestion.address
        if addr.lowercased().contains("new york") || addr.lowercased().contains("ny") {
            return addr
        }
        return "\(addr), New York, NY"
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ vc: SFSafariViewController, context: Context) {}
}

#Preview {
    ResultCardView(
        suggestion: Suggestion(
            name: "Balthazar",
            desc: "A timeless French brasserie in SoHo with classic bistro fare.",
            area: "SoHo",
            address: "80 Spring St, New York, NY 10012",
            cat: "Food & Drink",
            priceRange: "$$",
            cuisine: "French",
            emoji: "\u{1F37D}\u{FE0F}",
            tip: "Request a table by the window.",
            bookingUrl: "https://www.resy.com",
            bookingPlatform: "Resy"
        ),
        isFavorite: true,
        onFavorite: {},
        onShare: {}
    )
}
