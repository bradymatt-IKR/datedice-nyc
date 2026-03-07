import SwiftUI

// MARK: - Theme

/// Central design-token store mirroring the web app's P color palette.
enum Theme {

    // MARK: Colors

    /// Primary background — #0c0c18
    static let background = Color(hex: "#0c0c18")

    /// Card surface — white at 4 % opacity
    static let cardBackground = Color.white.opacity(0.04)

    /// Card border — white at 8 % opacity
    static let cardBorder = Color.white.opacity(0.08)

    /// Gold accent — #e8c36a
    static let gold = Color(hex: "#e8c36a")

    /// Dimmed gold — gold at 15 % opacity
    static let goldDim = Color(hex: "#e8c36a").opacity(0.15)

    /// Bright gold — #f5d98a
    static let goldBright = Color(hex: "#f5d98a")

    /// Primary text — #f0ece2
    static let text = Color(hex: "#f0ece2")

    /// Secondary text — text at 45 % opacity
    static let textSecondary = Color(hex: "#f0ece2").opacity(0.45)

    /// Warm accent — #c97d4a
    static let accent = Color(hex: "#c97d4a")

    /// Rose — #d4727e
    static let rose = Color(hex: "#d4727e")

    /// Green — #6ecf94
    static let green = Color(hex: "#6ecf94")

    /// Blue — #6aafe8
    static let blue = Color(hex: "#6aafe8")

    // MARK: Skyline Colors

    static let skylineDistant = Color(red: 40/255, green: 45/255, blue: 85/255)
    static let skylineMid = Color(red: 30/255, green: 34/255, blue: 68/255)
    static let skylineNear = Color(red: 20/255, green: 22/255, blue: 48/255)
    static let skylineBeacon = Color(red: 220/255, green: 80/255, blue: 80/255)

    // MARK: Window Colors

    static let windowAmber = Color(red: 232/255, green: 195/255, blue: 106/255)
    static let windowBrightAmber = Color(red: 245/255, green: 217/255, blue: 138/255)
    static let windowCoolBlue = Color(red: 180/255, green: 210/255, blue: 255/255)

    // MARK: Seasonal Glow

    enum Season { case spring, summer, fall, winter }

    static var currentSeason: Season {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .fall
        default: return .winter
        }
    }

    static var seasonalGlowColor: Color {
        switch currentSeason {
        case .spring: return rose
        case .summer, .fall: return accent
        case .winter: return blue
        }
    }

    static var seasonalGlowOpacity: Double {
        switch currentSeason {
        case .spring: return 0.25
        case .summer: return 0.30
        case .fall: return 0.25
        case .winter: return 0.22
        }
    }

    // MARK: Gradients

    /// Gold-to-accent linear gradient (mirrors web `grad`)
    static let gradient = LinearGradient(
        colors: [gold, accent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: Borough Colors

    /// Maps borough / region names to their brand colors.
    static let boroughColors: [String: Color] = [
        "Brooklyn": rose,
        "Manhattan": gold,
        "Queens": blue,
        "Bronx": green,
        "Across the River": accent,
    ]

    // MARK: Fonts

    /// Serif body font at the given size (uses the system New York font).
    static func serif(_ size: CGFloat = 16) -> Font {
        .custom("NewYork-Regular", size: size, relativeTo: .body)
    }

    /// Bold serif font at the given size.
    static func serifBold(_ size: CGFloat = 16) -> Font {
        .custom("NewYork-Bold", size: size, relativeTo: .body)
    }

    /// Display / headline font — system serif design.
    static func display(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .serif)
    }
}

// MARK: - Color + Hex Initializer

extension Color {
    /// Creates a `Color` from a CSS-style hex string (e.g. `"#e8c36a"` or `"e8c36a"`).
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
