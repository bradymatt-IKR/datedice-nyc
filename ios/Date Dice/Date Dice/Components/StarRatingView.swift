import SwiftUI

struct StarRatingView: View {
    let currentRating: Int?
    let interactive: Bool
    var onRate: ((Int) -> Void)?

    init(rating: Int? = nil, interactive: Bool = true, onRate: ((Int) -> Void)? = nil) {
        self.currentRating = rating
        self.interactive = interactive
        self.onRate = onRate
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { star in
                if interactive {
                    Button {
                        onRate?(star)
                    } label: {
                        starImage(for: star)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(star) star\(star == 1 ? "" : "s")")
                } else {
                    starImage(for: star)
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityElement(children: interactive ? .contain : .ignore)
        .accessibilityLabel(interactive ? "Rate this date" : ratingLabel)
    }

    private func starImage(for star: Int) -> some View {
        Image(systemName: star <= (currentRating ?? 0) ? "star.fill" : "star")
            .font(.system(size: 16))
            .foregroundStyle(star <= (currentRating ?? 0) ? Theme.gold : Theme.textSecondary.opacity(0.5))
    }

    private var ratingLabel: String {
        if let r = currentRating {
            return "\(r) out of 5 stars"
        }
        return "Not rated"
    }
}

#Preview {
    VStack(spacing: 20) {
        StarRatingView(rating: 4, interactive: false)
        StarRatingView(rating: nil, interactive: true) { rating in
            print("Rated \(rating)")
        }
    }
    .padding()
    .background(Theme.background)
}
