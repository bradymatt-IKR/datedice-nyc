import SwiftUI
import SafariServices

struct ResultCardView: View {
    let suggestion: Suggestion
    let isFavorite: Bool
    var onFavorite: () -> Void
    var onShare: () -> Void
    @State private var showSafari = false

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

            // Address
            if !suggestion.address.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.rose)

                    Text(suggestion.address)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSecondary)
                }
            }

            // Tip
            if let tip = suggestion.tip, !tip.isEmpty {
                HStack(alignment: .top, spacing: 12) {
                    Text("💡")
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

            // Action Buttons
            HStack(spacing: 12) {
                if let bookingUrl = suggestion.bookingUrl,
                   !bookingUrl.isEmpty,
                   let url = URL(string: bookingUrl) {
                    Button(action: { showSafari = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "safari")
                            Text(suggestion.bookingPlatform ?? "Book")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.background)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Theme.gradient)
                        .clipShape(Capsule())
                    }
                }

                Spacer()

                Button(action: onFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(isFavorite ? Theme.rose : Theme.textSecondary)
                }

                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.textSecondary)
                }
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
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let vc = SFSafariViewController(url: url)
        vc.preferredControlTintColor = UIColor(Theme.gold)
        return vc
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
            emoji: "🍽️",
            tip: "Request a table by the window.",
            bookingUrl: "https://www.resy.com",
            bookingPlatform: "Resy"
        ),
        isFavorite: true,
        onFavorite: {},
        onShare: {}
    )
}
