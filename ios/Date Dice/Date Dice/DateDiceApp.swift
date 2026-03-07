import SwiftUI

@main
struct DateDiceApp: App {
    @State private var viewModel = AppViewModel()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .preferredColorScheme(.dark)

                if !hasSeenOnboarding {
                    OnboardingView {
                        withAnimation(.easeOut(duration: 0.35)) {
                            hasSeenOnboarding = true
                        }
                    }
                    .transition(.opacity)
                    .zIndex(100)
                }
            }
            .environment(viewModel)
        }
    }
}
