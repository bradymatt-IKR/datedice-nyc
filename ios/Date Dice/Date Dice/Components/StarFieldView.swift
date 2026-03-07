import SwiftUI

// MARK: - Star

/// A single star with position, size, and twinkle parameters.
private struct Star {
    let x: CGFloat
    let y: CGFloat
    let radius: CGFloat
    let baseOpacity: Double
    let twinkleSpeed: Double
    let twinklePhase: Double
    let isGold: Bool
}

// MARK: - StarFieldView

/// Renders 45 twinkling stars in the top 70% of the screen using Canvas for performance.
struct StarFieldView: View {

    @State private var stars: [Star] = StarFieldView.generateStars()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Gold star color matching Theme.windowAmber.
    private static let goldColor = Color(red: 232 / 255, green: 195 / 255, blue: 106 / 255)

    var body: some View {
        if reduceMotion {
            staticCanvas
        } else {
            animatedCanvas
        }
    }

    // MARK: Animated Canvas

    private var animatedCanvas: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                drawStars(context: context, size: size, date: timeline.date)
            }
        }
        .opacity(0.7)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: Static Canvas (Reduce Motion)

    private var staticCanvas: some View {
        Canvas { context, size in
            drawStarsStatic(context: context, size: size)
        }
        .opacity(0.7)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: Drawing

    private func drawStars(context: GraphicsContext, size: CGSize, date: Date) {
        let elapsed = date.timeIntervalSinceReferenceDate

        for star in stars {
            let phase = (elapsed / star.twinkleSpeed) * 2.0 * .pi + star.twinklePhase
            let opacity = star.baseOpacity + (1.0 - star.baseOpacity) * ((sin(phase) + 1.0) / 2.0)

            let posX = star.x * size.width
            let posY = star.y * size.height * 0.7

            let rect = CGRect(
                x: posX - star.radius,
                y: posY - star.radius,
                width: star.radius * 2,
                height: star.radius * 2
            )

            let color: Color = star.isGold
                ? Self.goldColor.opacity(opacity)
                : Color.white.opacity(opacity)

            context.fill(Path(ellipseIn: rect), with: .color(color))
        }
    }

    private func drawStarsStatic(context: GraphicsContext, size: CGSize) {
        let staticOpacity = 0.6

        for star in stars {
            let posX = star.x * size.width
            let posY = star.y * size.height * 0.7

            let rect = CGRect(
                x: posX - star.radius,
                y: posY - star.radius,
                width: star.radius * 2,
                height: star.radius * 2
            )

            let color: Color = star.isGold
                ? Self.goldColor.opacity(staticOpacity)
                : Color.white.opacity(staticOpacity)

            context.fill(Path(ellipseIn: rect), with: .color(color))
        }
    }

    // MARK: Star Generation

    /// Generates 45 stars with a fixed seed so positions are stable across redraws.
    private static func generateStars() -> [Star] {
        var rng = SeededRandomNumberGenerator(seed: 42)
        var result: [Star] = []
        result.reserveCapacity(45)

        for _ in 0..<45 {
            let isGold = Double.random(in: 0...1, using: &rng) < 0.15

            let star = Star(
                x: CGFloat.random(in: 0...1, using: &rng),
                y: CGFloat.random(in: 0...1, using: &rng),
                radius: CGFloat.random(in: 0.7...1.5, using: &rng),
                baseOpacity: isGold
                    ? Double.random(in: 0.3...0.5, using: &rng)
                    : Double.random(in: 0.3...0.7, using: &rng),
                twinkleSpeed: Double.random(in: 3.0...7.0, using: &rng),
                twinklePhase: Double.random(in: 0...(2.0 * .pi), using: &rng),
                isGold: isGold
            )
            result.append(star)
        }

        return result
    }
}

// MARK: - SeededRandomNumberGenerator

/// A simple deterministic RNG based on xorshift64 so star positions remain stable.
private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
