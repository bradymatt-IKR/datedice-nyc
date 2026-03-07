import SwiftUI

struct FavoritesView: View {
    @Environment(AppViewModel.self) private var vm

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackgroundView()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ShimmerTitleView("Favorites", fontSize: 24)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        if vm.favorites.isEmpty {
                            // MARK: - Empty State
                            VStack(spacing: 12) {
                                Text("\u{2764}\u{FE0F}")
                                    .font(.system(size: 48))

                                Text("No favorites yet")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(Theme.text)

                                Text("Tap the heart on any suggestion to save it")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Theme.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 40)
                            .padding(.top, 40)
                        } else {
                            // MARK: - Favorites List
                            LazyVStack(spacing: 16) {
                                ForEach(vm.favorites) { fav in
                                    ResultCardView(
                                        suggestion: fav,
                                        isFavorite: vm.isFavorite(fav),
                                        onFavorite: { vm.toggleFavorite(fav) },
                                        onShare: { shareResult(fav) }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 40)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Share

    private func shareResult(_ suggestion: Suggestion) {
        let text = "\(suggestion.emoji) \(suggestion.name) \u{2014} \(suggestion.desc)\n\u{1F4CD} \(suggestion.address)\nFound with Date Dice NYC \u{1F3B2}"

        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }

        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )

        // Prevent crash on iPad
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootVC.view
            popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.maxY - 50, width: 0, height: 0)
        }

        rootVC.present(activityVC, animated: true)
    }
}

#Preview {
    FavoritesView()
        .environment(AppViewModel())
}
