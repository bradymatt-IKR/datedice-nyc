import SwiftUI

// MARK: - Onboarding Step Model

private struct OnboardingStep {
    let subtitle: String
    let title: String
    let description: String
}

private let steps: [OnboardingStep] = [
    OnboardingStep(
        subtitle: "Step 1",
        title: "Set the Scene",
        description: "Pick a vibe, budget, and neighborhood — or tap Dealer's Choice for a total surprise."
    ),
    OnboardingStep(
        subtitle: "Step 2",
        title: "Roll the Dice",
        description: "Tap the dice and AI scours NYC for the perfect spot — with insider tips and booking links."
    ),
    OnboardingStep(
        subtitle: "Step 3",
        title: "Lock It In",
        description: "Lock your date, get reminders, open directions in your favorite map app, and rate it after."
    ),
]

// MARK: - OnboardingView

struct OnboardingView: View {
    var onComplete: () -> Void
    @State private var step = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Same atmospheric background as the rest of the app
            AtmosphericBackgroundView()

            // Slight darkening for contrast against text
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            // Floating gold particles for depth
            if !reduceMotion {
                OnboardingParticlesView()
            }

            VStack(spacing: 0) {
                Spacer()

                // Brand header — dice icon + shimmer title
                VStack(spacing: 8) {
                    DiceFaceIcon()
                        .scaleEffect(0.7)

                    ShimmerTitleView("Date Dice", fontSize: 28)

                    Text("NYC")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                        .tracking(4)
                }
                .padding(.bottom, 40)

                // Animated icons for the current step
                iconsSection
                    .frame(height: 100)
                    .padding(.bottom, 24)

                // Step label + title
                VStack(spacing: 8) {
                    Text(steps[step].subtitle)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.gold.opacity(0.6))
                        .tracking(2)
                        .textCase(.uppercase)

                    Text(steps[step].title)
                        .font(Theme.display(26))
                        .foregroundStyle(Theme.gold)
                }
                .id("title-\(step)")
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                // Description
                Text(steps[step].description)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: 300)
                    .padding(.top, 12)
                    .padding(.bottom, 48)
                    .id("desc-\(step)")
                    .transition(.opacity)

                // Dot indicators
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        Capsule()
                            .fill(i == step ? Theme.gold : Color.white.opacity(0.15))
                            .frame(width: i == step ? 24 : 8, height: 8)
                    }
                }
                .animation(.spring(response: 0.3), value: step)
                .padding(.bottom, 32)

                // Buttons
                HStack(spacing: 16) {
                    Button("Skip") { onComplete() }
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                        .buttonStyle(.plain)

                    Button(step < steps.count - 1 ? "Next" : "Let's Roll!") {
                        advance()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.background)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 12)
                    .background(Theme.gradient)
                    .clipShape(Capsule())
                    .shadow(color: Theme.gold.opacity(0.3), radius: 10, y: 4)
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(.horizontal, 32)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 40, coordinateSpace: .local)
                    .onEnded { value in
                        let threshold: CGFloat = 60
                        if value.translation.width < -threshold, step < steps.count - 1 {
                            advance()
                        } else if value.translation.width > threshold, step > 0 {
                            goBack()
                        }
                    }
            )
        }
    }

    // MARK: - Navigation

    private func advance() {
        if step < steps.count - 1 {
            withAnimation(.easeInOut(duration: 0.35)) {
                step += 1
            }
        } else {
            onComplete()
        }
    }

    private func goBack() {
        withAnimation(.easeInOut(duration: 0.35)) {
            step -= 1
        }
    }

    // MARK: - Icons Section

    @ViewBuilder
    private var iconsSection: some View {
        switch step {
        case 0:
            FilterGlowIcons()
                .id("icons-0")
                .transition(.opacity)
        case 1:
            DiceRockIcon()
                .id("icons-1")
                .transition(.opacity)
        case 2:
            LifecycleIcons()
                .id("icons-2")
                .transition(.opacity)
        default:
            EmptyView()
        }
    }
}

// MARK: - Step 1: Filter Glow Icons

/// Filter icons spring in with staggered scale + gold glow rings.
private struct FilterGlowIcons: View {
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let icons = ["\u{2728}", "\u{1F4B0}", "\u{1F4CD}", "\u{1F37D}\u{FE0F}"]

    var body: some View {
        HStack(spacing: 20) {
            ForEach(Array(icons.enumerated()), id: \.offset) { index, icon in
                ZStack {
                    // Gold glow ring behind each icon
                    if !reduceMotion {
                        Circle()
                            .fill(Theme.gold.opacity(appeared ? 0.12 : 0))
                            .frame(width: 56, height: 56)
                            .scaleEffect(appeared ? 1.2 : 0.6)
                            .animation(
                                .easeOut(duration: 0.5)
                                    .delay(Double(index) * 0.1),
                                value: appeared
                            )
                    }

                    Text(icon)
                        .font(.system(size: 36))
                        .scaleEffect(appeared || reduceMotion ? 1.0 : 0.3)
                        .opacity(appeared || reduceMotion ? 1 : 0)
                        .animation(
                            .spring(response: 0.45, dampingFraction: 0.6)
                                .delay(Double(index) * 0.1),
                            value: appeared
                        )
                }
            }
        }
        .onAppear { appeared = true }
    }
}

// MARK: - Step 2: Dice Rock Icon

/// The dice rocks back and forth with a pulsing gold glow behind it.
private struct DiceRockIcon: View {
    @State private var rocking = false
    @State private var glowing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Pulsing glow
            if !reduceMotion {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.gold.opacity(glowing ? 0.25 : 0.08), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: glowing
                    )
            }

            Text("\u{1F3B2}")
                .font(.system(size: 64))
                .rotationEffect(.degrees(reduceMotion ? 0 : (rocking ? 12 : -12)))
                .animation(
                    reduceMotion ? nil :
                        .easeInOut(duration: 0.7)
                        .repeatForever(autoreverses: true),
                    value: rocking
                )
        }
        .onAppear {
            rocking = true
            glowing = true
        }
    }
}

// MARK: - Step 3: Lifecycle Icons

/// Lock, Bell, Star appear in staggered sequence to show the date lifecycle.
private struct LifecycleIcons: View {
    @State private var showLock = false
    @State private var showBell = false
    @State private var showStar = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let items: [(emoji: String, label: String, color: Color)] = [
        ("\u{1F512}", "Lock it in", Theme.gold),
        ("\u{1F514}", "Get reminded", Theme.accent),
        ("\u{2B50}", "Rate it", Theme.goldBright),
    ]

    var body: some View {
        HStack(spacing: 16) {
            lifecycleItem(items[0], visible: showLock)

            arrowConnector(visible: showBell)

            lifecycleItem(items[1], visible: showBell)

            arrowConnector(visible: showStar)

            lifecycleItem(items[2], visible: showStar)
        }
        .onAppear {
            let baseDelay: Double = reduceMotion ? 0 : 0.2
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65).delay(baseDelay)) {
                showLock = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65).delay(baseDelay + 0.3)) {
                showBell = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65).delay(baseDelay + 0.6)) {
                showStar = true
            }
        }
    }

    private func lifecycleItem(_ item: (emoji: String, label: String, color: Color), visible: Bool) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(item.color.opacity(visible ? 0.12 : 0))
                    .frame(width: 48, height: 48)

                Text(item.emoji)
                    .font(.system(size: 28))
            }

            Text(item.label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
        }
        .scaleEffect(visible ? 1.0 : 0.4)
        .opacity(visible ? 1 : 0)
    }

    private func arrowConnector(visible: Bool) -> some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(Theme.textSecondary.opacity(0.4))
            .opacity(visible ? 1 : 0)
            .offset(y: -8)
    }
}

// MARK: - Floating Particles

/// Subtle drifting gold dots in the background for depth.
private struct OnboardingParticlesView: View {
    @State private var animate = false

    private struct Dot: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let brightness: Double
        let duration: Double
        let delay: Double
    }

    private let dots: [Dot] = (0..<20).map { i in
        Dot(
            id: i,
            x: CGFloat.random(in: 0...1),
            y: CGFloat.random(in: 0...1),
            size: CGFloat.random(in: 2...4),
            brightness: Double.random(in: 0.08...0.25),
            duration: Double.random(in: 3...6),
            delay: Double.random(in: 0...2)
        )
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(dots) { d in
                Circle()
                    .fill(Theme.gold)
                    .frame(width: d.size, height: d.size)
                    .opacity(animate ? d.brightness : d.brightness * 0.3)
                    .position(
                        x: d.x * geo.size.width,
                        y: animate
                            ? d.y * geo.size.height - 30
                            : d.y * geo.size.height + 30
                    )
                    .animation(
                        .easeInOut(duration: d.duration)
                            .repeatForever(autoreverses: true)
                            .delay(d.delay),
                        value: animate
                    )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { animate = true }
    }
}

#Preview {
    OnboardingView {}
}
