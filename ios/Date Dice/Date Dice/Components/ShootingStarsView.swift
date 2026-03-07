import SwiftUI

// MARK: - Shooting Star Configuration

private struct ShootingStar {
    let startY: CGFloat    // Fractional Y position (0-1)
    let startX: CGFloat    // Fractional X position (0-1)
    let angle: Double      // Degrees
    let duration: Double   // Total cycle duration in seconds
    let delay: Double      // Initial delay in seconds
    let width: CGFloat     // Streak length in points
}

private let shootingStars: [ShootingStar] = [
    ShootingStar(startY: 0.08, startX: 0.12, angle: 32, duration: 14, delay: 3,  width: 120),
    ShootingStar(startY: 0.14, startX: 0.52, angle: 38, duration: 18, delay: 9,  width: 80),
    ShootingStar(startY: 0.05, startX: 0.32, angle: 30, duration: 26, delay: 0,  width: 150),
    ShootingStar(startY: 0.18, startX: 0.72, angle: 42, duration: 30, delay: 16, width: 90),
    ShootingStar(startY: 0.10, startX: 0.85, angle: 35, duration: 22, delay: 6,  width: 110),
    ShootingStar(startY: 0.03, startX: 0.45, angle: 33, duration: 38, delay: 20, width: 100),
]

/// The fraction of each cycle during which the star is visible (streak + fade).
private let visibleFraction: Double = 0.07

// MARK: - ShootingStarsView

struct ShootingStarsView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            EmptyView()
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                Canvas { context, size in
                    let now = timeline.date.timeIntervalSinceReferenceDate

                    for star in shootingStars {
                        drawStar(star, in: &context, size: size, now: now)
                    }
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
        }
    }

    // MARK: - Drawing

    private func drawStar(
        _ star: ShootingStar,
        in context: inout GraphicsContext,
        size: CGSize,
        now: Double
    ) {
        let cycleDuration = star.duration
        let visibleDuration = cycleDuration * visibleFraction

        // Compute elapsed time within the cycle, accounting for initial delay.
        let elapsed = now - star.delay
        guard elapsed >= 0 else { return }
        let phase = elapsed.truncatingRemainder(dividingBy: cycleDuration)

        // The star is only visible during [0, visibleDuration) of each cycle.
        guard phase < visibleDuration else { return }

        let progress = phase / visibleDuration // 0 → 1 over the visible window

        // Fade envelope: fade in 0-20%, full 20-80%, fade out 80-100%.
        let opacity: Double
        if progress < 0.2 {
            opacity = progress / 0.2
        } else if progress > 0.8 {
            opacity = (1.0 - progress) / 0.2
        } else {
            opacity = 1.0
        }

        guard opacity > 0.001 else { return }

        // Use drawLayer for transform isolation per star.
        context.drawLayer { layerContext in
            let startX = star.startX * size.width
            let startY = star.startY * size.height
            let angleRad = star.angle * .pi / 180.0

            // Translate to start position, then rotate.
            let transform = CGAffineTransform(translationX: startX, y: startY)
                .rotated(by: angleRad)
            layerContext.transform = transform

            // The streak travels along the positive X axis after rotation.
            // As progress goes 0→1 the head moves forward; the tail follows.
            let headX = star.width * progress
            let tailX = max(0, headX - star.width)

            // -- Draw the streak gradient line --
            let streakLength = headX - tailX
            guard streakLength > 0.5 else { return }

            let streakRect = CGRect(x: tailX, y: -0.5, width: streakLength, height: 1.0)

            // Gradient stops: tail (transparent) → head (white).
            let gradient = Gradient(stops: [
                .init(color: Color.white.opacity(0),            location: 0.0),
                .init(color: Color(red: 232/255, green: 195/255, blue: 106/255).opacity(0.1), location: 0.15),
                .init(color: Color(red: 245/255, green: 217/255, blue: 138/255).opacity(0.5), location: 0.45),
                .init(color: Color(red: 255/255, green: 253/255, blue: 240/255).opacity(0.85), location: 0.78),
                .init(color: .white, location: 1.0),
            ])

            layerContext.opacity = opacity

            layerContext.fill(
                Path(streakRect),
                with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: tailX, y: 0),
                    endPoint: CGPoint(x: headX, y: 0)
                )
            )

            // -- Draw the head glow --
            let headCenter = CGPoint(x: headX, y: 0)
            let gold = Color(red: 232/255, green: 195/255, blue: 106/255)

            // Outermost glow: gold @ 0.15, radius 14
            layerContext.fill(
                Circle().path(in: CGRect(
                    x: headCenter.x - 14,
                    y: headCenter.y - 14,
                    width: 28,
                    height: 28
                )),
                with: .radialGradient(
                    Gradient(colors: [gold.opacity(0.15), gold.opacity(0)]),
                    center: headCenter,
                    startRadius: 0,
                    endRadius: 14
                )
            )

            // Middle glow: white @ 0.4, radius 7
            layerContext.fill(
                Circle().path(in: CGRect(
                    x: headCenter.x - 7,
                    y: headCenter.y - 7,
                    width: 14,
                    height: 14
                )),
                with: .radialGradient(
                    Gradient(colors: [Color.white.opacity(0.4), Color.white.opacity(0)]),
                    center: headCenter,
                    startRadius: 0,
                    endRadius: 7
                )
            )

            // Core: white @ 0.9, radius 3
            layerContext.fill(
                Circle().path(in: CGRect(
                    x: headCenter.x - 3,
                    y: headCenter.y - 3,
                    width: 6,
                    height: 6
                )),
                with: .color(.white.opacity(0.9))
            )
        }
    }
}
