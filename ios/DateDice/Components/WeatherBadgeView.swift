import SwiftUI

struct WeatherBadgeView: View {
    let weather: WeatherInfo?
    let borough: String?
    let loading: Bool

    var body: some View {
        if loading {
            HStack(spacing: 6) {
                ProgressView().tint(Theme.textSecondary)
                Text("Checking weather...")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Theme.cardBackground)
            .clipShape(Capsule())
        } else if let w = weather {
            HStack(spacing: 6) {
                Text(w.emoji)
                Text("\(Int(w.temperature))°")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.text)
                Text(w.description)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                Text("in \(borough ?? "Brooklyn")")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Theme.cardBackground)
            .clipShape(Capsule())
        }
    }
}
