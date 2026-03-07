import SwiftUI

/// Two dice side by side, matching the web app's paired Dice3D layout.
/// Animation is driven by the isRolling binding so it stays in sync with the API call.
struct DiceView: View {
    @Binding var isRolling: Bool
    var onRoll: () -> Void

    @State private var faceValue1 = 5
    @State private var faceValue2 = 3
    @State private var spin1 = 0.0
    @State private var spin2 = 0.0
    @State private var liftY: CGFloat = 0
    @State private var diceScale = 1.0
    @State private var cycleTimer: Timer?

    var body: some View {
        Button(action: {
            guard !isRolling else { return }
            Haptics.diceShake()
            onRoll()
        }) {
            HStack(spacing: 2) {
                singleDie(value: faceValue1, spin: spin1)
                singleDie(value: faceValue2, spin: spin2)
            }
            .scaleEffect(diceScale)
            .offset(y: liftY)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!isRolling)
        .onChange(of: isRolling) { _, rolling in
            if rolling {
                startRolling()
            } else {
                land()
            }
        }
    }

    private func singleDie(value: Int, spin: Double) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.99, blue: 0.92),
                            Color(red: 0.95, green: 0.90, blue: 0.76),
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 190/255, green: 148/255, blue: 58/255).opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: Theme.gold.opacity(0.25), radius: 6)
                .frame(width: 76, height: 76)

            GeometryReader { geo in
                ForEach(Array((dotPositions[value] ?? []).enumerated()), id: \.offset) { _, pos in
                    Circle()
                        .fill(Color(red: 27/255, green: 20/255, blue: 8/255))
                        .frame(width: 11, height: 11)
                        .position(
                            x: pos.0 * geo.size.width,
                            y: pos.1 * geo.size.height
                        )
                }
            }
            .frame(width: 76, height: 76)
        }
        .rotationEffect(.degrees(spin))
    }

    private let dotPositions: [Int: [(Double, Double)]] = [
        1: [(0.5, 0.5)],
        2: [(0.33, 0.33), (0.67, 0.67)],
        3: [(0.33, 0.33), (0.5, 0.5), (0.67, 0.67)],
        4: [(0.33, 0.33), (0.67, 0.33), (0.33, 0.67), (0.67, 0.67)],
        5: [(0.33, 0.33), (0.67, 0.33), (0.5, 0.5), (0.33, 0.67), (0.67, 0.67)],
        6: [(0.33, 0.25), (0.67, 0.25), (0.33, 0.5), (0.67, 0.5), (0.33, 0.75), (0.67, 0.75)],
    ]

    // MARK: - State-driven animations

    private func startRolling() {
        // Lift + scale
        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
            diceScale = 1.08
            liftY = -6
        }

        // Spin both dice
        withAnimation(.spring(response: 1.0, dampingFraction: 0.45)) {
            spin1 += Double.random(in: 540...900)
            spin2 += Double.random(in: 540...900)
        }

        // Cycle face values while rolling
        cycleTimer?.invalidate()
        cycleTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { _ in
            guard self.isRolling else {
                self.cycleTimer?.invalidate()
                self.cycleTimer = nil
                return
            }
            self.faceValue1 = Int.random(in: 1...6)
            self.faceValue2 = Int.random(in: 1...6)
        }

        // Haptic ticks
        for i in 1...5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                if self.isRolling { Haptics.diceTumble() }
            }
        }
    }

    private func land() {
        cycleTimer?.invalidate()
        cycleTimer = nil

        // Final face values
        faceValue1 = Int.random(in: 1...6)
        faceValue2 = Int.random(in: 1...6)

        // Drop back down
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            diceScale = 1.0
            liftY = 0
        }
        Haptics.diceLand()
    }
}
