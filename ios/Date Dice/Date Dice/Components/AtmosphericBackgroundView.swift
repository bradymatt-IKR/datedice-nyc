import SwiftUI

struct AtmosphericBackgroundView: View {
    @Environment(AppViewModel.self) private var vm
    @Environment(\.scenePhase) private var scenePhase
    @State private var isReady = false

    var body: some View {
        let colors = vm.skyColors

        ZStack {
            SkyGradientView(colors: colors)

            if isReady {
                if scenePhase == .active {
                    StarFieldView()
                        .opacity(colors.starOpacity)
                        .animation(.easeInOut(duration: 60), value: colors.starOpacity)
                    ShootingStarsView()
                        .opacity(colors.shootingStarOpacity)
                        .animation(.easeInOut(duration: 60), value: colors.shootingStarOpacity)
                }

                VStack(spacing: 0) {
                    Spacer()
                    SkylineView(skyColors: colors)
                        .frame(height: 280)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task {
            try? await Task.sleep(for: .milliseconds(50))
            isReady = true
        }
    }
}
