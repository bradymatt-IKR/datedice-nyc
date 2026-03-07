import SwiftUI

// MARK: - Sky Phase

/// Drives dynamic time-of-day backgrounds using real sunrise/sunset from Open-Meteo.
/// Four phases: night, sunrise, day, sunset — with 80-minute transition windows.

enum SkyPhase: String, CaseIterable {
    case night, sunrise, day, sunset
}

struct SkyPhaseInfo: Equatable {
    let phase: SkyPhase
    let blend: Double      // 0-1 within transition window
    let nextPhase: SkyPhase

    static let nightDefault = SkyPhaseInfo(phase: .night, blend: 0, nextPhase: .sunrise)
}

// MARK: - Seasonal Fallback Sunrise/Sunset (minutes since midnight, NYC)

struct SunTimes: Equatable {
    let sunrise: Int   // minutes since midnight
    let sunset: Int
}

func seasonalFallbackSunTimes() -> SunTimes {
    switch Theme.currentSeason {
    case .spring: return SunTimes(sunrise: 390, sunset: 1140)  // ~6:30am, ~7:00pm
    case .summer: return SunTimes(sunrise: 330, sunset: 1230)  // ~5:30am, ~8:30pm
    case .fall:   return SunTimes(sunrise: 420, sunset: 1080)  // ~7:00am, ~6:00pm
    case .winter: return SunTimes(sunrise: 430, sunset: 1010)  // ~7:10am, ~4:50pm
    }
}

// MARK: - Phase Computation

func computeSkyPhase(sunTimes: SunTimes) -> SkyPhaseInfo {
    let now = Date()
    let cal = Calendar.current
    let currentMin = cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now)
    let T = 40 // half-window in minutes

    let sunriseStart = sunTimes.sunrise - T
    let sunriseEnd   = sunTimes.sunrise + T
    let sunsetStart  = sunTimes.sunset - T
    let sunsetEnd    = sunTimes.sunset + T

    if currentMin >= sunriseStart && currentMin < sunriseEnd {
        let blend = Double(currentMin - sunriseStart) / Double(sunriseEnd - sunriseStart)
        return SkyPhaseInfo(phase: .sunrise, blend: blend, nextPhase: .day)
    }
    if currentMin >= sunriseEnd && currentMin < sunsetStart {
        return SkyPhaseInfo(phase: .day, blend: 0, nextPhase: .sunset)
    }
    if currentMin >= sunsetStart && currentMin < sunsetEnd {
        let blend = Double(currentMin - sunsetStart) / Double(sunsetEnd - sunsetStart)
        return SkyPhaseInfo(phase: .sunset, blend: blend, nextPhase: .night)
    }
    return SkyPhaseInfo(phase: .night, blend: 0, nextPhase: .sunrise)
}

// MARK: - Phase Color Palettes

struct SkyPalette {
    let skyTop: Color
    let skyMid: Color
    let skyHorizon: Color
    let starOpacity: Double
    let shootingStarOpacity: Double
    let windowOpacity: Double
    let glowColor1: Color?
    let glowColor2: Color?

    static let night = SkyPalette(
        skyTop:     Theme.background,
        skyMid:     Theme.background,
        skyHorizon: Theme.background,
        starOpacity: 0.7,
        shootingStarOpacity: 1,
        windowOpacity: 1,
        glowColor1: nil,
        glowColor2: nil
    )

    static let sunrise = SkyPalette(
        skyTop:     Color(red: 20/255, green: 30/255, blue: 56/255).opacity(0.9),
        skyMid:     Color(red: 60/255, green: 50/255, blue: 80/255).opacity(0.7),
        skyHorizon: Color(red: 210/255, green: 130/255, blue: 90/255).opacity(0.5),
        starOpacity: 0,
        shootingStarOpacity: 0,
        windowOpacity: 0.15,
        glowColor1: Color(red: 220/255, green: 140/255, blue: 100/255).opacity(0.35),
        glowColor2: Color(red: 232/255, green: 195/255, blue: 106/255).opacity(0.25)
    )

    static let day = SkyPalette(
        skyTop:     Color(red: 20/255, green: 30/255, blue: 56/255).opacity(0.85),
        skyMid:     Color(red: 42/255, green: 63/255, blue: 107/255).opacity(0.65),
        skyHorizon: Color(red: 120/255, green: 140/255, blue: 170/255).opacity(0.3),
        starOpacity: 0,
        shootingStarOpacity: 0,
        windowOpacity: 0,
        glowColor1: Color(red: 106/255, green: 175/255, blue: 232/255).opacity(0.12),
        glowColor2: Color(red: 140/255, green: 170/255, blue: 210/255).opacity(0.08)
    )

    static let sunset = SkyPalette(
        skyTop:     Color(red: 30/255, green: 25/255, blue: 60/255).opacity(0.9),
        skyMid:     Color(red: 80/255, green: 50/255, blue: 70/255).opacity(0.7),
        skyHorizon: Color(red: 200/255, green: 120/255, blue: 60/255).opacity(0.55),
        starOpacity: 0.3,
        shootingStarOpacity: 0.5,
        windowOpacity: 0.6,
        glowColor1: Color(red: 200/255, green: 120/255, blue: 60/255).opacity(0.4),
        glowColor2: Color(red: 232/255, green: 160/255, blue: 80/255).opacity(0.3)
    )

    static func palette(for phase: SkyPhase) -> SkyPalette {
        switch phase {
        case .night:   return .night
        case .sunrise: return .sunrise
        case .day:     return .day
        case .sunset:  return .sunset
        }
    }
}

// MARK: - Resolved (blended) palette for current phase + blend

struct ResolvedSkyColors: Equatable {
    let skyTop: Color
    let skyMid: Color
    let skyHorizon: Color
    let starOpacity: Double
    let shootingStarOpacity: Double
    let windowOpacity: Double
    let glowColor1: Color
    let glowColor2: Color

    static func resolve(from info: SkyPhaseInfo) -> ResolvedSkyColors {
        let current = SkyPalette.palette(for: info.phase)

        guard info.blend > 0 else {
            return ResolvedSkyColors(
                skyTop: current.skyTop,
                skyMid: current.skyMid,
                skyHorizon: current.skyHorizon,
                starOpacity: current.starOpacity,
                shootingStarOpacity: current.shootingStarOpacity,
                windowOpacity: current.windowOpacity,
                glowColor1: current.glowColor1 ?? Theme.seasonalGlowColor,
                glowColor2: current.glowColor2 ?? Theme.seasonalGlowColor.opacity(0.5)
            )
        }

        let next = SkyPalette.palette(for: info.nextPhase)
        let t = info.blend

        return ResolvedSkyColors(
            skyTop: lerpColor(current.skyTop, next.skyTop, t: t),
            skyMid: lerpColor(current.skyMid, next.skyMid, t: t),
            skyHorizon: lerpColor(current.skyHorizon, next.skyHorizon, t: t),
            starOpacity: lerp(current.starOpacity, next.starOpacity, t: t),
            shootingStarOpacity: lerp(current.shootingStarOpacity, next.shootingStarOpacity, t: t),
            windowOpacity: lerp(current.windowOpacity, next.windowOpacity, t: t),
            glowColor1: lerpColor(
                current.glowColor1 ?? Theme.seasonalGlowColor,
                next.glowColor1 ?? Theme.seasonalGlowColor,
                t: t
            ),
            glowColor2: lerpColor(
                current.glowColor2 ?? Theme.seasonalGlowColor.opacity(0.5),
                next.glowColor2 ?? Theme.seasonalGlowColor.opacity(0.5),
                t: t
            )
        )
    }
}

// MARK: - Helpers

private func lerp(_ a: Double, _ b: Double, t: Double) -> Double {
    a + (b - a) * t
}

private func lerpColor(_ a: Color, _ b: Color, t: Double) -> Color {
    let ac = a.components
    let bc = b.components
    return Color(
        red:   ac.r + (bc.r - ac.r) * t,
        green: ac.g + (bc.g - ac.g) * t,
        blue:  ac.b + (bc.b - ac.b) * t,
        opacity: ac.a + (bc.a - ac.a) * t
    )
}

private extension Color {
    var components: (r: Double, g: Double, b: Double, a: Double) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
    }
}
