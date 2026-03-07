import SwiftUI

/// Two 3D dice side by side, matching the web app's paired Dice3D layout.
/// Uses SceneKit for real 3D cube rendering with gold-textured faces.
struct DiceView: View {
    @Binding var isRolling: Bool
    var onRoll: () -> Void

    @State private var value1 = 5
    @State private var value2 = 3
    @State private var liftOffset: CGFloat = 0
    @State private var shadowOpacity: Double = 0.3

    var body: some View {
        VStack(spacing: 4) {
            // Two 3D dice
            HStack(spacing: 4) {
                SceneKitDice(value: value1, rolling: isRolling)
                    .frame(width: 82, height: 82)

                SceneKitDice(value: value2, rolling: isRolling)
                    .frame(width: 82, height: 82)
            }
            .offset(y: liftOffset)

            // Gold shadows underneath each die
            HStack(spacing: 30) {
                diceShadow
                diceShadow
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isRolling else { return }
            Haptics.diceShake()
            onRoll()
        }
        .onChange(of: isRolling) { _, rolling in
            if rolling {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                    liftOffset = -12
                    shadowOpacity = 0.08
                }

                for i in 1...5 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                        if self.isRolling { Haptics.diceTumble() }
                    }
                }
            } else {
                value1 = Int.random(in: 1...6)
                value2 = Int.random(in: 1...6)

                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    liftOffset = 0
                    shadowOpacity = 0.3
                }
                Haptics.diceLand()
            }
        }
    }

    private var diceShadow: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [Theme.gold.opacity(shadowOpacity), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 30
                )
            )
            .frame(width: 56, height: 10)
    }
}
