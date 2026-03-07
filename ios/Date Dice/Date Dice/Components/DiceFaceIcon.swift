import SwiftUI

/// Two overlapping gold dice faces shown above the "Date Dice" title,
/// matching the web app's paired dice SVG header icon.
/// Left die: 3-face tilted -12°, right die: 5-face tilted +8°.
struct DiceFaceIcon: View {

    private let dieSize: CGFloat = 36
    private let dotSize: CGFloat = 5
    private let cornerRadius: CGFloat = 8

    private let faceGradient = LinearGradient(
        colors: [
            Color(red: 232/255, green: 195/255, blue: 106/255),
            Color(red: 201/255, green: 125/255, blue: 74/255),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private let dotColor = Color.white.opacity(0.9)

    // Dot patterns as fractions of die size
    private let threeDots: [(CGFloat, CGFloat)] = [
        (0.30, 0.30),
        (0.50, 0.50),
        (0.70, 0.70),
    ]

    private let fiveDots: [(CGFloat, CGFloat)] = [
        (0.30, 0.30), (0.70, 0.30),
        (0.50, 0.50),
        (0.30, 0.70), (0.70, 0.70),
    ]

    var body: some View {
        ZStack {
            // Left die — 3-face, tilted -12°
            singleDie(dots: threeDots)
                .rotationEffect(.degrees(-12))
                .offset(x: -14, y: 2)
                .opacity(0.9)

            // Right die — 5-face, tilted +8°
            singleDie(dots: fiveDots)
                .rotationEffect(.degrees(8))
                .offset(x: 14, y: -2)
        }
        .frame(width: 80, height: 52)
        .shadow(color: Theme.gold.opacity(0.35), radius: 8)
    }

    private func singleDie(dots: [(CGFloat, CGFloat)]) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(faceGradient)
                .frame(width: dieSize, height: dieSize)

            ForEach(Array(dots.enumerated()), id: \.offset) { _, pos in
                Circle()
                    .fill(dotColor)
                    .frame(width: dotSize, height: dotSize)
                    .position(x: pos.0 * dieSize, y: pos.1 * dieSize)
            }
            .frame(width: dieSize, height: dieSize)
        }
    }
}
