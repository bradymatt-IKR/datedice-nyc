import SwiftUI

/// Renders a vertical gradient background driven by the current sky phase.
/// Night = `Theme.background` solid (pixel-identical to current look).
/// Other phases blend smoothly via SwiftUI animation.
struct SkyGradientView: View {
    let colors: ResolvedSkyColors

    var body: some View {
        ZStack {
            Theme.background

            LinearGradient(
                colors: [colors.skyTop, colors.skyMid, colors.skyHorizon],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 120), value: colors)
    }
}
