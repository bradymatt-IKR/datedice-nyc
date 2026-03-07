import SwiftUI

// MARK: - WindowLightColor

/// The color category for a window light.
private enum WindowLightColor {
    case amber
    case brightAmber
    case coolBlue

    var color: Color {
        switch self {
        case .amber: return Theme.windowAmber
        case .brightAmber: return Theme.windowBrightAmber
        case .coolBlue: return Theme.windowCoolBlue
        }
    }
}

// MARK: - WindowLight

/// A single lit window on the skyline, with position, color, and twinkle timing.
private struct WindowLight {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    let color: WindowLightColor
    let twinkleSpeed: Double
    let twinkleDelay: Double
    let isStatic: Bool
}

// MARK: - Building

/// A rectangle in the skyline silhouette.
private struct Building {
    let x: CGFloat         // normalized 0-1
    let y: CGFloat         // normalized 0-1 (from top of skyline area)
    let width: CGFloat     // normalized 0-1
    let height: CGFloat    // normalized 0-1
    let color: Color
}

// MARK: - SkylineView

/// Renders a NYC skyline silhouette at the bottom of the screen with three building
/// layers and twinkling window lights. The skyline includes recognizable shapes such
/// as the Empire State Building spire and a Chrysler-style stepped crown.
struct SkylineView: View {

    var skyColors: ResolvedSkyColors?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var windows: [WindowLight] = SkylineView.generateWindows()

    /// Fixed skyline height before clamping.
    private static let skylineHeight: CGFloat = 280

    /// Pre-computed building data (deterministic, never changes).
    private static let cachedBuildings: [Building] = allBuildings()

    var body: some View {
        GeometryReader { geo in
            let height = min(Self.skylineHeight, geo.size.height)

            ZStack(alignment: .bottom) {
                // Seasonal horizon glow (behind buildings)
                seasonalGlow

                // Static building silhouettes
                buildingsCanvas(size: geo.size)
                    .frame(height: height)
                    .mask(fadeGradient)

                // Window lights
                Group {
                    if reduceMotion {
                        staticWindowsCanvas(size: geo.size)
                            .frame(height: height)
                    } else {
                        animatedWindowsCanvas(size: geo.size)
                            .frame(height: height)
                    }
                }
                .opacity(skyColors?.windowOpacity ?? 1.0)
                .animation(.easeInOut(duration: 60), value: skyColors?.windowOpacity)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - Seasonal Glow

    private var seasonalGlow: some View {
        let glow1 = skyColors?.glowColor1 ?? Theme.seasonalGlowColor
        let glow2 = skyColors?.glowColor2 ?? Theme.seasonalGlowColor.opacity(0.5)

        return Rectangle()
            .fill(LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: glow1.opacity(0.15), location: 0.3),
                    .init(color: Color(red: 232/255, green: 195/255, blue: 106/255).opacity(0.08), location: 0.5),
                    .init(color: glow1.opacity(0.6), location: 0.75),
                    .init(color: glow2.opacity(0.22), location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            ))
            .frame(height: 250)
    }

    // MARK: - Fade Gradient Mask

    private var fadeGradient: some View {
        // Matches web: transparent 0% → 0.3 at 35% → opaque at 70%
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: .black.opacity(0.3), location: 0.35),
                .init(color: .black, location: 0.70),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Buildings Canvas (Static)

    private func buildingsCanvas(size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let buildings = Self.cachedBuildings
            for b in buildings {
                let rect = CGRect(
                    x: b.x * canvasSize.width,
                    y: b.y * canvasSize.height,
                    width: b.width * canvasSize.width,
                    height: b.height * canvasSize.height
                )
                context.fill(Path(rect), with: .color(b.color))
            }

            // Empire State spire
            drawEmpireStateSpire(context: context, size: canvasSize)

            // Chrysler crown
            drawChryslerCrown(context: context, size: canvasSize)

            // Water towers
            drawWaterTowers(context: context, size: canvasSize)
        }
    }

    // MARK: - Windows Canvas (Animated)

    private func animatedWindowsCanvas(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, canvasSize in
                let elapsed = timeline.date.timeIntervalSinceReferenceDate

                drawWindows(context: context, size: canvasSize, elapsed: elapsed)
                drawBeacon(context: context, size: canvasSize, elapsed: elapsed, isStatic: false)
            }
        }
    }

    // MARK: - Windows Canvas (Static / Reduce Motion)

    private func staticWindowsCanvas(size: CGSize) -> some View {
        Canvas { context, canvasSize in
            drawWindows(context: context, size: canvasSize, elapsed: nil)
            drawBeacon(context: context, size: canvasSize, elapsed: nil, isStatic: true)
        }
    }

    // MARK: - Draw Windows

    private func drawWindows(context: GraphicsContext, size: CGSize, elapsed: Double?) {
        for win in windows {
            let opacity: Double
            if win.isStatic || elapsed == nil {
                opacity = 0.7
            } else {
                let t = elapsed!
                let phase = ((t - win.twinkleDelay) / win.twinkleSpeed) * 2.0 * .pi
                opacity = 0.3 + 0.7 * ((sin(phase) + 1.0) / 2.0)
            }

            let rect = CGRect(
                x: win.x * size.width - (win.width * size.width) / 2,
                y: win.y * size.height,
                width: win.width * size.width,
                height: win.height * size.height
            )

            context.fill(Path(rect), with: .color(win.color.color.opacity(opacity)))
        }
    }

    // MARK: - Draw Beacon

    /// Empire State beacon: a soft glowing red dot at the top of the spire.
    private func drawBeacon(context: GraphicsContext, size: CGSize, elapsed: Double?, isStatic: Bool) {
        let beaconX: CGFloat = 585.0 / 1440
        let beaconY: CGFloat = 16.0 / 320
        let radius: CGFloat = 2.0

        let opacity: Double
        if isStatic || elapsed == nil {
            opacity = 0.45
        } else {
            // Gentle pulse between 0.3 and 0.6 over 3 seconds
            let phase = (elapsed! / 3.0) * 2.0 * .pi
            opacity = 0.3 + 0.3 * ((sin(phase) + 1.0) / 2.0)
        }

        let cx = beaconX * size.width
        let cy = beaconY * size.height

        // Soft outer glow
        let glowRect = CGRect(
            x: cx - radius * 2.5,
            y: cy - radius * 2.5,
            width: radius * 5,
            height: radius * 5
        )
        context.fill(
            Path(ellipseIn: glowRect),
            with: .color(Theme.skylineBeacon.opacity(opacity * 0.12))
        )

        // Inner beacon
        let beaconRect = CGRect(
            x: cx - radius,
            y: cy - radius,
            width: radius * 2,
            height: radius * 2
        )
        context.fill(
            Path(ellipseIn: beaconRect),
            with: .color(Theme.skylineBeacon.opacity(opacity * 0.5))
        )
    }

    // MARK: - Empire State Spire (from web SVG: x=560-590, y=4-85)

    private func drawEmpireStateSpire(context: GraphicsContext, size: CGSize) {
        let spireColor = Color(red: 25/255, green: 28/255, blue: 58/255, opacity: 0.95)
        // Setbacks: 565,65 w40h30 → 570,45 w30h25 → 577,30 w16h18
        let setbacks: [(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat)] = [
            (565.0/1440, 65.0/320, 40.0/1440, 30.0/320),
            (570.0/1440, 45.0/320, 30.0/1440, 25.0/320),
            (577.0/1440, 30.0/320, 16.0/1440, 18.0/320),
        ]
        for s in setbacks {
            let rect = CGRect(x: s.x * size.width, y: s.y * size.height,
                              width: s.w * size.width, height: s.h * size.height)
            context.fill(Path(rect), with: .color(spireColor))
        }
        // Spire triangle: points 585,14 580,30 590,30
        var spire = Path()
        spire.move(to: CGPoint(x: 585.0/1440 * size.width, y: 14.0/320 * size.height))
        spire.addLine(to: CGPoint(x: 580.0/1440 * size.width, y: 30.0/320 * size.height))
        spire.addLine(to: CGPoint(x: 590.0/1440 * size.width, y: 30.0/320 * size.height))
        spire.closeSubpath()
        context.fill(spire, with: .color(spireColor))
    }

    // MARK: - Chrysler Crown (from web SVG: x=700-730, y=52-110)

    private func drawChryslerCrown(context: GraphicsContext, size: CGSize) {
        let crownColor = Color(red: 30/255, green: 34/255, blue: 68/255, opacity: 0.93)
        // Stepped setbacks
        let steps: [(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat)] = [
            (704.0/1440, 95.0/320, 36.0/1440, 20.0/320),
            (708.0/1440, 82.0/320, 28.0/1440, 18.0/320),
            (712.0/1440, 70.0/320, 20.0/1440, 16.0/320),
        ]
        for s in steps {
            let rect = CGRect(x: s.x * size.width, y: s.y * size.height,
                              width: s.w * size.width, height: s.h * size.height)
            context.fill(Path(rect), with: .color(crownColor))
        }
        // Pinnacle triangle: points 722,52 714,70 730,70
        var pin = Path()
        pin.move(to: CGPoint(x: 722.0/1440 * size.width, y: 52.0/320 * size.height))
        pin.addLine(to: CGPoint(x: 714.0/1440 * size.width, y: 70.0/320 * size.height))
        pin.addLine(to: CGPoint(x: 730.0/1440 * size.width, y: 70.0/320 * size.height))
        pin.closeSubpath()
        context.fill(pin, with: .color(crownColor))
    }

    // MARK: - Water Towers (from web SVG: ellipse + rect at x=162,863)

    private func drawWaterTowers(context: GraphicsContext, size: CGSize) {
        let towers: [(legX: CGFloat, legY: CGFloat, ellX: CGFloat, ellY: CGFloat, color: Color)] = [
            // Tower 1 on building at x=150
            (162.0/1440, 192.0/320, 164.0/1440, 190.0/320,
             Color(red: 30/255, green: 34/255, blue: 68/255, opacity: 0.9)),
            // Tower 2 on building at x=850
            (863.0/1440, 157.0/320, 865.0/1440, 155.0/320,
             Color(red: 28/255, green: 32/255, blue: 65/255, opacity: 0.9)),
        ]

        for t in towers {
            // Leg
            let legRect = CGRect(
                x: t.legX * size.width, y: t.legY * size.height,
                width: 4.0/1440 * size.width, height: 10.0/320 * size.height
            )
            context.fill(Path(legRect), with: .color(t.color))
            // Tank (ellipse)
            let ellRect = CGRect(
                x: (t.ellX - 8.0/1440) * size.width,
                y: (t.ellY - 5.0/320) * size.height,
                width: 16.0/1440 * size.width,
                height: 10.0/320 * size.height
            )
            context.fill(Path(ellipseIn: ellRect), with: .color(t.color))
        }
    }

    // MARK: - Building Data

    /// Generates all three layers of building rectangles.
    /// Coordinates ported directly from web SVG (viewBox 0 0 1440 320).
    private static func allBuildings() -> [Building] {
        // Helper to normalize from SVG coords (1440×320) to 0-1 fractions
        func n(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
            (x / 1440, y / 320, w / 1440, h / 320)
        }

        var buildings: [Building] = []

        // -----------------------------------------------------------
        // Layer 1: Distant buildings (group opacity 0.5 in web SVG)
        // Colors: rgba(36-40, 40-45, 78-85, 0.6-0.7)
        // -----------------------------------------------------------
        let layer1Color1 = Color(red: 40/255, green: 45/255, blue: 85/255).opacity(0.40)
        let layer1Color2 = Color(red: 38/255, green: 42/255, blue: 80/255).opacity(0.38)
        let layer1Color3 = Color(red: 36/255, green: 40/255, blue: 78/255).opacity(0.35)

        let l1: [(CGFloat, CGFloat, CGFloat, CGFloat, Color)] = [
            (0, 200, 100, 120, layer1Color1), (90, 180, 55, 140, layer1Color2),
            (140, 195, 80, 125, layer1Color3), (215, 170, 50, 150, layer1Color1),
            (260, 185, 70, 135, layer1Color2), (340, 175, 45, 145, layer1Color1),
            (380, 190, 90, 130, layer1Color3), (480, 160, 55, 160, layer1Color1),
            (530, 175, 70, 145, layer1Color2), (610, 155, 45, 165, layer1Color1),
            (650, 170, 80, 150, layer1Color3), (740, 165, 55, 155, layer1Color1),
            (790, 180, 70, 140, layer1Color2), (870, 175, 50, 145, layer1Color1),
            (920, 190, 85, 130, layer1Color3), (1010, 170, 60, 150, layer1Color1),
            (1070, 185, 75, 135, layer1Color2), (1150, 175, 50, 145, layer1Color1),
            (1200, 195, 90, 125, layer1Color3), (1295, 180, 60, 140, layer1Color1),
            (1355, 190, 85, 130, layer1Color2),
        ]
        for (x, y, w, h, c) in l1 {
            let coords = n(x, y, w, h)
            buildings.append(Building(x: coords.0, y: coords.1, width: coords.2, height: coords.3, color: c))
        }

        // -----------------------------------------------------------
        // Layer 2: Mid skyline (group opacity 0.8 in web SVG)
        // Colors: rgba(28-32, 32-36, 65-70, 0.85-0.95)
        // -----------------------------------------------------------
        let m1 = Color(red: 30/255, green: 34/255, blue: 68/255).opacity(0.75)
        let m2 = Color(red: 30/255, green: 34/255, blue: 68/255).opacity(0.80)
        let m3 = Color(red: 32/255, green: 36/255, blue: 70/255).opacity(0.80)
        let mt = Color(red: 28/255, green: 32/255, blue: 65/255).opacity(0.80)   // midtown towers
        let mt2 = Color(red: 28/255, green: 32/255, blue: 65/255).opacity(0.82)
        let mt3 = Color(red: 28/255, green: 32/255, blue: 65/255).opacity(0.78)
        let es = Color(red: 25/255, green: 28/255, blue: 58/255).opacity(0.85)   // Empire State
        let ch = Color(red: 30/255, green: 34/255, blue: 68/255).opacity(0.82)   // Chrysler

        let l2: [(CGFloat, CGFloat, CGFloat, CGFloat, Color)] = [
            // Left cluster (Brooklyn/LIC)
            (0, 230, 70, 90, m1), (65, 215, 40, 105, m2), (100, 225, 55, 95, m1),
            (150, 200, 35, 120, m3), (182, 235, 65, 85, m1),
            // Transition mid-rise
            (255, 210, 40, 110, m2), (290, 220, 55, 100, m1),
            (350, 195, 35, 125, m3), (382, 225, 50, 95, m1),
            // Midtown tall towers
            (440, 170, 40, 150, mt), (476, 145, 35, 175, mt2), (508, 155, 45, 165, mt3),
            // Empire State main body
            (560, 85, 50, 235, es),
            // More midtown towers
            (615, 140, 38, 180, mt), (650, 160, 45, 160, mt3),
            // Chrysler main body
            (700, 110, 44, 210, ch),
            // Upper east/west towers
            (755, 175, 40, 145, mt3), (790, 195, 55, 125, m1),
            (850, 165, 35, 155, mt), (882, 185, 48, 135, m1),
            // Modern glass tower
            (938, 130, 38, 190, mt2),
            // Right cluster (UES/Harlem)
            (980, 200, 50, 120, m1), (1025, 215, 40, 105, m1),
            (1060, 190, 55, 130, m1), (1120, 205, 35, 115, m3),
            (1152, 220, 60, 100, m1), (1218, 200, 40, 120, m1),
            (1255, 215, 55, 105, m1), (1315, 225, 45, 95, m1),
            (1358, 210, 38, 110, m2), (1395, 230, 45, 90, m1),
        ]
        for (x, y, w, h, c) in l2 {
            let coords = n(x, y, w, h)
            buildings.append(Building(x: coords.0, y: coords.1, width: coords.2, height: coords.3, color: c))
        }

        // -----------------------------------------------------------
        // Layer 3: Foreground buildings (group opacity 0.95 in web SVG)
        // Colors: rgba(20,22,48, 0.95-0.97)
        // -----------------------------------------------------------
        let fg = Color(red: 20/255, green: 22/255, blue: 48/255).opacity(0.95)
        let fg2 = Color(red: 20/255, green: 22/255, blue: 48/255).opacity(0.97)

        let l3: [(CGFloat, CGFloat, CGFloat, CGFloat, Color)] = [
            (0, 270, 95, 50, fg), (88, 255, 50, 65, fg2), (135, 265, 80, 55, fg),
            (220, 258, 45, 62, fg2), (270, 272, 70, 48, fg), (345, 260, 55, 60, fg2),
            (410, 268, 75, 52, fg), (495, 262, 50, 58, fg2), (550, 275, 65, 45, fg),
            (620, 265, 45, 55, fg2), (670, 270, 80, 50, fg), (758, 263, 50, 57, fg2),
            (815, 275, 60, 45, fg), (880, 260, 55, 60, fg2), (940, 270, 75, 50, fg),
            (1020, 265, 50, 55, fg2), (1075, 272, 65, 48, fg), (1145, 260, 55, 60, fg2),
            (1205, 268, 70, 52, fg), (1280, 272, 50, 48, fg2), (1335, 265, 55, 55, fg),
            (1395, 270, 45, 50, fg2),
        ]
        for (x, y, w, h, c) in l3 {
            let coords = n(x, y, w, h)
            buildings.append(Building(x: coords.0, y: coords.1, width: coords.2, height: coords.3, color: c))
        }

        return buildings
    }

    // MARK: - Window Generation

    /// Generates ~50 window lights distributed across building surfaces.
    /// Uses a seeded RNG so positions remain stable across redraws.
    private static func generateWindows() -> [WindowLight] {
        var rng = SkylineRNG(seed: 314)
        var result: [WindowLight] = []
        result.reserveCapacity(60)

        // Regions matching web SVG building positions (normalized from 1440×320)
        let regions: [(xMin: CGFloat, xMax: CGFloat, yMin: CGFloat, yMax: CGFloat, count: Int)] = [
            // Left cluster (Brooklyn/LIC) — buildings x=0-247
            (0.0/1440, 170.0/1440, 215.0/320, 290.0/320, 6),
            (170.0/1440, 250.0/1440, 235.0/320, 290.0/320, 3),
            // Transition mid-rise — x=255-432
            (255.0/1440, 432.0/1440, 210.0/320, 290.0/320, 5),
            // Midtown towers — x=440-553
            (440.0/1440, 553.0/1440, 160.0/320, 290.0/320, 5),
            // Empire State — x=560-610
            (560.0/1440, 610.0/1440, 100.0/320, 280.0/320, 7),
            // Post-Empire midtown — x=615-695
            (615.0/1440, 695.0/1440, 160.0/320, 290.0/320, 4),
            // Chrysler area — x=700-744
            (700.0/1440, 744.0/1440, 120.0/320, 280.0/320, 4),
            // East side towers — x=755-976
            (755.0/1440, 976.0/1440, 170.0/320, 290.0/320, 6),
            // Right cluster — x=980-1440
            (980.0/1440, 1440.0/1440, 200.0/320, 290.0/320, 6),
            // Foreground layer scatter
            (0.0/1440, 500.0/1440, 258.0/320, 300.0/320, 5),
            (500.0/1440, 1000.0/1440, 262.0/320, 300.0/320, 5),
            (1000.0/1440, 1440.0/1440, 260.0/320, 300.0/320, 4),
        ]

        for region in regions {
            for _ in 0..<region.count {
                let colorRoll = Double.random(in: 0...1, using: &rng)
                let windowColor: WindowLightColor
                if colorRoll < 0.80 {
                    windowColor = .amber
                } else if colorRoll < 0.95 {
                    windowColor = .brightAmber
                } else {
                    windowColor = .coolBlue
                }

                let isStatic = Double.random(in: 0...1, using: &rng) < 0.2

                let win = WindowLight(
                    x: CGFloat.random(in: region.xMin...region.xMax, using: &rng),
                    y: CGFloat.random(in: region.yMin...region.yMax, using: &rng),
                    width: 4.0 / 1440,   // matches web SVG 4px windows
                    height: 5.0 / 320,
                    color: windowColor,
                    twinkleSpeed: Double.random(in: 1.9...6.2, using: &rng),
                    twinkleDelay: Double.random(in: 0...3, using: &rng),
                    isStatic: isStatic
                )
                result.append(win)
            }
        }

        return result
    }
}

// MARK: - SkylineRNG

/// Deterministic xorshift64 random number generator for stable, reproducible layouts.
private struct SkylineRNG: RandomNumberGenerator {
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
