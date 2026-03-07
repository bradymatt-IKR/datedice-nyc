import SwiftUI

struct LoadingOverlay: View {
    let message: String
    @State private var emojiIndex = 0
    @State private var rotation = 0.0

    private let emojis = AppConstants.loadingEmoji["default"] ?? ["🎲"]

    var body: some View {
        VStack(spacing: 20) {
            Text(emojis[emojiIndex % emojis.count])
                .font(.system(size: 48))
                .rotationEffect(.degrees(rotation))
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: rotation)

            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.opacity(0.9))
        .onAppear {
            rotation = 15
            Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
                emojiIndex += 1
            }
        }
    }
}
