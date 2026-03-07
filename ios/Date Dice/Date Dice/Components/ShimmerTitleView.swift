import SwiftUI

/// Displays a title with a gold gradient shimmer that sweeps
/// continuously across the text. Respects Reduce Motion accessibility settings.
struct ShimmerTitleView: View {

    let title: String
    let fontSize: CGFloat

    @State private var shimmerOffset: CGFloat = -200
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(_ title: String = "Date Dice", fontSize: CGFloat = 32) {
        self.title = title
        self.fontSize = fontSize
    }

    var body: some View {
        Text(title)
            .font(Theme.display(fontSize))
            .foregroundStyle(Theme.gold)
            .overlay {
                if !reduceMotion {
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: "#e8c36a"), location: 0.0),
                            .init(color: Color(hex: "#c97d4a"), location: 0.3),
                            .init(color: Color(hex: "#f5d98a"), location: 0.5),
                            .init(color: Color(hex: "#c97d4a"), location: 0.7),
                            .init(color: Color(hex: "#e8c36a"), location: 1.0),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 400)
                    .offset(x: shimmerOffset)
                    .mask {
                        Text(title)
                            .font(Theme.display(fontSize))
                    }
                }
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(
                    .linear(duration: 6)
                    .repeatForever(autoreverses: false)
                ) {
                    shimmerOffset = 200
                }
            }
    }
}
