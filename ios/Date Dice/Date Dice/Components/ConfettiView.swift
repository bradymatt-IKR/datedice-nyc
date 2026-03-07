import SwiftUI

struct ConfettiView: View {
    @Binding var isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let colors: [Color] = [
        Theme.gold,
        Theme.accent,
        Theme.rose,
        Color(red: 0.43, green: 0.81, blue: 0.58),  // green
        Color(red: 0.42, green: 0.69, blue: 0.91),  // blue
        Theme.goldBright,
        Color(red: 1.0, green: 0.60, blue: 0.46),   // coral
        Color(red: 1.0, green: 0.85, blue: 0.24),   // yellow
    ]

    @State private var particles: [ConfettiParticle] = []
    @State private var animate = false

    var body: some View {
        if isActive && !reduceMotion {
            GeometryReader { geo in
                ZStack {
                    ForEach(particles) { p in
                        particleView(p)
                            .offset(
                                x: animate ? p.endX : p.startX,
                                y: animate ? p.endY : p.startY
                            )
                            .rotationEffect(.degrees(animate ? p.endRotation : 0))
                            .scaleEffect(animate ? 0.3 : 1.0)
                            .opacity(animate ? 0 : 1)
                            .animation(
                                .easeIn(duration: p.duration)
                                    .delay(p.delay),
                                value: animate
                            )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    particles = Self.generateParticles(width: geo.size.width)
                    // Trigger animation on next frame
                    DispatchQueue.main.async {
                        animate = true
                    }
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .task {
                try? await Task.sleep(for: .seconds(3.5))
                isActive = false
                animate = false
                particles = []
            }
        }
    }

    @ViewBuilder
    private func particleView(_ p: ConfettiParticle) -> some View {
        switch p.shape {
        case .circle:
            Circle()
                .fill(p.color)
                .frame(width: p.size, height: p.size)
        case .rectangle:
            RoundedRectangle(cornerRadius: 2)
                .fill(p.color)
                .frame(width: p.size, height: p.size * 0.6)
        case .star:
            Image(systemName: "star.fill")
                .font(.system(size: p.size * 0.8))
                .foregroundStyle(p.color)
        }
    }

    private static func generateParticles(width screenWidth: CGFloat) -> [ConfettiParticle] {
        return (0..<55).map { i in
            ConfettiParticle(
                id: i,
                color: colors[i % colors.count],
                shape: ConfettiShape.allCases[i % ConfettiShape.allCases.count],
                size: CGFloat.random(in: 6...14),
                startX: CGFloat.random(in: -screenWidth / 2...screenWidth / 2),
                startY: CGFloat.random(in: -80...(-20)),
                endX: CGFloat.random(in: -screenWidth / 2...screenWidth / 2),
                endY: CGFloat.random(in: 400...900),
                endRotation: Double.random(in: 360...1080),
                delay: Double.random(in: 0...0.5),
                duration: Double.random(in: 1.0...3.2)
            )
        }
    }
}

// MARK: - Support Types

enum ConfettiShape: CaseIterable {
    case circle, rectangle, star
}

struct ConfettiParticle: Identifiable {
    let id: Int
    let color: Color
    let shape: ConfettiShape
    let size: CGFloat
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let endRotation: Double
    let delay: Double
    let duration: Double
}
