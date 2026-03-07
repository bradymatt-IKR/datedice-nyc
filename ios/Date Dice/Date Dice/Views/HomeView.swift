import SwiftUI

struct HomeView: View {
    @Environment(AppViewModel.self) private var vm
    @State private var showFilters = false

    var body: some View {
        @Bindable var vm = vm

        ZStack {
            AtmosphericBackgroundView()

            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Title
                    VStack(spacing: 6) {
                        // Dice icon above title (matches web app)
                        DiceFaceIcon()

                        ShimmerTitleView()

                        Text("NYC")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                            .tracking(4)
                    }
                    .padding(.top, 20)

                    // MARK: - Weather
                    WeatherBadgeView(
                        weather: vm.weather,
                        borough: vm.locationManager.borough,
                        loading: vm.weatherLoading
                    )

                    // MARK: - Presets Row
                    ZStack(alignment: .trailing) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                // Dealer's Choice
                                Button {
                                    vm.dealersChoice()
                                } label: {
                                    Text("\u{1F0CF} Dealer's Choice")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(Theme.background)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Theme.gold)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)

                                // Preset buttons
                                ForEach(AppConstants.presets, id: \.label) { preset in
                                    Button {
                                        vm.applyPreset(preset.filters)
                                    } label: {
                                        Text("\(preset.emoji) \(preset.label)")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(Theme.text)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(Theme.cardBackground)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(Theme.cardBorder, lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.trailing, 28)
                        }

                        // Trailing fade + chevron hint
                        HStack(spacing: 0) {
                            LinearGradient(
                                colors: [.clear, Theme.background.opacity(0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 40)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.textSecondary)
                                .padding(.trailing, 8)
                                .background(Theme.background.opacity(0.9))
                        }
                        .frame(height: 36)
                        .allowsHitTesting(false)
                    }

                    // MARK: - Active Filters Badge
                    if vm.filters.activeCount > 0 {
                        Button {
                            showFilters = true
                        } label: {
                            HStack(spacing: 6) {
                                Text("\(vm.filters.activeCount) filters active")
                                Image(systemName: "slider.horizontal.3")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.gold)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Theme.goldDim)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    // MARK: - Set the Scene Button
                    Button {
                        showFilters = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "slider.horizontal.3")
                            Text("Set the Scene")
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Theme.cardBackground)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Theme.cardBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    // MARK: - Dice + Hint/Loading
                    VStack(spacing: 2) {
                        DiceView(isRolling: $vm.isRolling) {
                            Task {
                                await vm.roll()
                            }
                        }

                        if vm.isRolling {
                            InlineLoadingView(message: vm.loadingMessage)
                                .transition(.opacity)
                        } else {
                            Text("Tap the dice to roll")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }

                    // MARK: - Result
                    if vm.showResult, let result = vm.currentResult {
                        ResultCardView(
                            suggestion: result,
                            isFavorite: vm.isFavorite(result),
                            isLocked: vm.isLocked,
                            onFavorite: { vm.toggleFavorite(result) },
                            onShare: { shareResult(result) },
                            onLockIn: { Task { await vm.lockIn(result) } }
                        )
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                        // MARK: - "What else you got?" / Retry button
                        if vm.alternates.isEmpty && !vm.altsLoading {
                            Button {
                                if vm.altsRetryAvailable {
                                    vm.altsRetryAvailable = false
                                }
                                Task { await vm.requestAlternates() }
                            } label: {
                                HStack(spacing: 6) {
                                    if vm.altsRetryAvailable {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 12, weight: .medium))
                                        Text("Retry")
                                    } else {
                                        Text("\u{2726}")
                                        Text("What else you got?")
                                    }
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(vm.altsRetryAvailable ? Theme.gold : Theme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.03))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            vm.altsRetryAvailable ? Theme.gold.opacity(0.4) : Theme.cardBorder.opacity(0.5),
                                            style: StrokeStyle(lineWidth: 1, dash: [6, 4])
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)
                        }

                        // Loading alternates
                        if vm.altsLoading {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .tint(Theme.textSecondary)
                                Text("Finding more options...")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            .padding(.vertical, 8)
                        }

                        // MARK: - Alternates
                        if !vm.alternates.isEmpty {
                            ForEach(vm.alternates) { alt in
                                ResultCardView(
                                    suggestion: alt,
                                    isFavorite: vm.isFavorite(alt),
                                    onFavorite: { vm.toggleFavorite(alt) },
                                    onShare: { shareResult(alt) }
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    Spacer(minLength: 40)
                }
            }
            .scrollIndicators(.hidden)

            // MARK: - Confetti
            ConfettiView(isActive: $vm.showConfetti)
                .ignoresSafeArea()

            // MARK: - Toast
            if let toast = vm.toastMessage {
                VStack {
                    Spacer()
                    Text(toast)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.text)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(.bottom, 30)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: vm.toastMessage)
            }
        }
        .sheet(isPresented: $showFilters) {
            FilterSheet()
        }
        .task {
            await vm.loadWeather()
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
    HomeView()
        .environment(AppViewModel())
}
