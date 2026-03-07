import SwiftUI

struct DiceView: View {
    @Binding var isRolling: Bool
    var onRoll: () -> Void

    @State private var rotationX = 0.0
    @State private var rotationY = 0.0
    @State private var rotationZ = 0.0
    @State private var scale = 1.0
    @State private var faceValue = 1

    private let dotPositions: [Int: [(Double, Double)]] = [
        1: [(0.5, 0.5)],
        2: [(0.33, 0.33), (0.67, 0.67)],
        3: [(0.33, 0.33), (0.5, 0.5), (0.67, 0.67)],
        4: [(0.33, 0.33), (0.67, 0.33), (0.33, 0.67), (0.67, 0.67)],
        5: [(0.33, 0.33), (0.67, 0.33), (0.5, 0.5), (0.33, 0.67), (0.67, 0.67)],
        6: [(0.33, 0.25), (0.67, 0.25), (0.33, 0.5), (0.67, 0.5), (0.33, 0.75), (0.67, 0.75)],
    ]

    var body: some View {
        Button(action: {
            guard !isRolling else { return }
            animateRoll()
            onRoll()
        }) {
            ZStack {
                // Dice body — dark gradient with gold border and glow
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "1a1a2e"), Color(hex: "16162a")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Theme.gold.opacity(0.4), lineWidth: 2)
                    )
                    .shadow(color: Theme.gold.opacity(0.2), radius: 10)
                    .frame(width: 100, height: 100)

                // Dots
                GeometryReader { geo in
                    ForEach(Array((dotPositions[faceValue] ?? []).enumerated()), id: \.offset) { _, pos in
                        Circle()
                            .fill(Theme.gold)
                            .frame(width: 14, height: 14)
                            .position(
                                x: pos.0 * geo.size.width,
                                y: pos.1 * geo.size.height
                            )
                    }
                }
                .frame(width: 100, height: 100)
            }
            .rotation3DEffect(.degrees(rotationX), axis: (x: 1, y: 0, z: 0))
            .rotation3DEffect(.degrees(rotationY), axis: (x: 0, y: 1, z: 0))
            .rotation3DEffect(.degrees(rotationZ), axis: (x: 0, y: 0, z: 1))
            .scaleEffect(scale)
        }
        .buttonStyle(.plain)
        .disabled(isRolling)
    }

    private func animateRoll() {
        // Phase 1: Quick shake — scale up slightly
        Haptics.diceShake()
        withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) {
            scale = 1.15
        }

        // Phase 2: Tumble — multi-axis rotation with spring physics
        withAnimation(.spring(response: 1.2, dampingFraction: 0.5)) {
            rotationX += Double.random(in: 720...1080)
            rotationY += Double.random(in: 720...1080)
            rotationZ += Double.random(in: -180...180)
        }

        // Haptic ticks during tumble (4 light taps at 0.25s intervals)
        for i in 1...4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.25) {
                Haptics.diceTumble()
            }
        }

        // Phase 3: Land — scale back to normal, randomize face, heavy haptic
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.0
            }
            faceValue = Int.random(in: 1...6)
            Haptics.diceLand()
        }
    }
}
