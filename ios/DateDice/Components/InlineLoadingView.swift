import SwiftUI

/// Compact loading indicator shown inline below the dice while rolling.
/// Cycles through emojis with a gentle wobble animation.
struct InlineLoadingView: View {
    let message: String
    @State private var emojiIndex = 0
    @State private var wobble = false

    private let emojis = AppConstants.loadingEmoji["default"] ?? ["\u{1F3B2}"]

    var body: some View {
        VStack(spacing: 8) {
            Text(emojis[emojiIndex % emojis.count])
                .font(.system(size: 32))
                .rotationEffect(.degrees(wobble ? 12 : -12))
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: wobble)

            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .onAppear {
            wobble = true
            Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    emojiIndex += 1
                }
            }
        }
    }
}
