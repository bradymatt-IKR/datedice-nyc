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
        "Islands": Color(hex: "#8b9dc3"),
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
