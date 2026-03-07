import SwiftUI

@Observable
class AppViewModel {
    // MARK: - State

    var filters = FilterState()
    var currentResult: Suggestion?
    var alternates: [Suggestion] = []
    var history: [Suggestion] = []
    var favorites: [Suggestion] = []
    var weather: WeatherInfo?
    var weatherLoading = true
    var nearMeActive = false

    // Rolling state
    var isRolling = false
    var loadingMessage = ""
    var streamingText = ""
    var showResult = false

    // Toast
    var toastMessage: String?

    // Diversity
    var usedNames: [String] = []
    var recentCategories: [String] = []

    // Services
    let api = APIService()
    let locationManager = LocationManager()

    // MARK: - Init

    init() {
        history = StorageService.loadHistory()
        favorites = StorageService.loadFavorites()
        usedNames = history.map(\.name)
    }

    // MARK: - Weather

    func loadWeather() async {
        weatherLoading = true
        let lat = locationManager.latitude ?? 40.6782
        let lng = locationManager.longitude ?? -73.9442
        let result = await WeatherService.fetch(lat: lat, lng: lng)
        await MainActor.run {
            self.weather = result
            self.weatherLoading = false
        }
    }

    // MARK: - Near Me

    func activateNearMe() async {
        if nearMeActive {
            nearMeActive = false
            showToast("📍 Near Me off")
            return
        }

        // If location already known, activate immediately
        if locationManager.latitude != nil && locationManager.longitude != nil {
            nearMeActive = true
            showToast("📍 Searching near you")
            return
        }

        // Otherwise request location
        do {
            _ = try await locationManager.requestLocation()
            await MainActor.run {
                self.nearMeActive = true
            }
            showToast("📍 Searching near you")
            // Refresh weather with actual location
            await loadWeather()
        } catch {
            showToast("📍 Location unavailable — pick a neighborhood instead")
        }
    }

    // MARK: - Roll

    @MainActor
    func roll() async {
        guard !isRolling else { return }

        isRolling = true
        showResult = false
        currentResult = nil
        alternates = []
        streamingText = ""
        loadingMessage = AppConstants.loadingMessages.randomElement() ?? "Rolling..."

        Haptics.diceShake()

        // Determine type from category
        let type: String
        if let category = filters.category {
            if category == "Surprise Me" {
                type = Bool.random() ? "food" : "activity"
            } else if category == "Food & Drink" {
                type = "food"
            } else {
                type = "activity"
            }
        } else {
            type = Bool.random() ? "food" : "activity"
        }

        // Build nearMe tuple if active
        let nearMe: (lat: Double, lng: Double, borough: String?)?
        if nearMeActive, let lat = locationManager.latitude, let lng = locationManager.longitude {
            nearMe = (lat: lat, lng: lng, borough: locationManager.borough)
        } else {
            nearMe = nil
        }

        // Build prompt
        let prompt = await api.buildPrompt(
            type: type,
            filters: filters,
            usedNames: usedNames,
            nearMe: nearMe,
            recentCategories: recentCategories
        )

        do {
            // Try streaming first
            var suggestion: Suggestion?

            do {
                suggestion = try await api.streamSuggestion(prompt: prompt) { [weak self] accumulated in
                    Task { @MainActor in
                        self?.streamingText = accumulated
                    }
                }
            } catch {
                // Fallback to non-streaming
                suggestion = try await api.fetchSuggestion(prompt: prompt)
            }

            if let suggestion {
                currentResult = suggestion
                usedNames.append(suggestion.name)

                // Track recent categories (keep last 5)
                recentCategories.append(suggestion.cat)
                if recentCategories.count > 5 {
                    recentCategories = Array(recentCategories.suffix(5))
                }

                // Insert into history (cap at 100)
                history.insert(suggestion, at: 0)
                if history.count > 100 {
                    history = Array(history.prefix(100))
                }
                StorageService.saveHistory(history)

                Haptics.diceLand()
                showResult = true

                // Load alternates in background
                Task {
                    await loadAlternates(type: type, nearMe: nearMe)
                }
            } else {
                showToast("Couldn't find a suggestion — try again!")
            }
        } catch {
            showToast("Something went wrong — check your connection and try again")
        }

        isRolling = false
    }

    // MARK: - Alternates

    private func loadAlternates(type: String, nearMe: (lat: Double, lng: Double, borough: String?)?) async {
        let prompt1 = await api.buildPrompt(
            type: type,
            filters: filters,
            usedNames: usedNames,
            nearMe: nearMe,
            recentCategories: recentCategories,
            variation: 1
        )
        let prompt2 = await api.buildPrompt(
            type: type,
            filters: filters,
            usedNames: usedNames,
            nearMe: nearMe,
            recentCategories: recentCategories,
            variation: 2
        )

        async let result1 = try? api.fetchSuggestion(prompt: prompt1)
        async let result2 = try? api.fetchSuggestion(prompt: prompt2)

        let r1 = await result1
        let r2 = await result2

        var results: [Suggestion] = []
        if let s = r1 {
            results.append(s)
            await MainActor.run { usedNames.append(s.name) }
        }
        if let s = r2 {
            results.append(s)
            await MainActor.run { usedNames.append(s.name) }
        }

        await MainActor.run {
            self.alternates = results
        }
    }

    // MARK: - Favorites

    func toggleFavorite(_ suggestion: Suggestion) {
        if let index = favorites.firstIndex(where: { $0.name == suggestion.name }) {
            favorites.remove(at: index)
        } else {
            favorites.insert(suggestion, at: 0)
            Haptics.favorite()
        }
        StorageService.saveFavorites(favorites)
    }

    func isFavorite(_ suggestion: Suggestion) -> Bool {
        favorites.contains(where: { $0.name == suggestion.name })
    }

    // MARK: - Presets

    func applyPreset(_ preset: FilterState) {
        filters = preset
        Haptics.chipTap()
    }

    // MARK: - Dealer's Choice

    func dealersChoice() {
        var newFilters = FilterState()

        // Category: 40% Food & Drink, 30% Activities, 30% Surprise Me
        let categoryRoll = Double.random(in: 0..<1)
        if categoryRoll < 0.4 {
            newFilters.category = "Food & Drink"
        } else if categoryRoll < 0.7 {
            newFilters.category = "Activities"
        } else {
            newFilters.category = "Surprise Me"
        }

        // Always pick 1-2 random vibes
        let vibeCount = Int.random(in: 1...2)
        newFilters.vibe = Array(AppConstants.vibes.shuffled().prefix(vibeCount))

        // 70% chance random budget
        if Double.random(in: 0..<1) < 0.7 {
            newFilters.budget = AppConstants.budgets.randomElement()
        }

        // 40% chance random duration
        if Double.random(in: 0..<1) < 0.4 {
            newFilters.duration = AppConstants.durations.randomElement()
        }

        // timeOfDay: 60% auto-detect from hour, 40% random
        if Double.random(in: 0..<1) < 0.6 {
            newFilters.timeOfDay = getTimeOfDay()
        } else {
            newFilters.timeOfDay = AppConstants.timesOfDay.randomElement()
        }

        // If weather exists, use autoFilter
        if let weather {
            newFilters.weather = weather.autoFilter
        }

        // 35% chance 1-2 random neighborhoods
        if Double.random(in: 0..<1) < 0.35 {
            let allHoods = AppConstants.neighborhoods.flatMap(\.hoods)
            let hoodCount = Int.random(in: 1...2)
            newFilters.neighborhood = Array(allHoods.shuffled().prefix(hoodCount))
        }

        // If not Activities, 30% chance 1-3 random cuisines
        if newFilters.category != "Activities" && Double.random(in: 0..<1) < 0.3 {
            let cuisineCount = Int.random(in: 1...3)
            newFilters.cuisine = Array(AppConstants.cuisines.shuffled().prefix(cuisineCount))
        }

        filters = newFilters

        let toasts = [
            "\u{1F0CF} Dealer's choice!",
            "\u{1F3B2} Fate has spoken!",
            "\u{2728} The dice gods have decided!",
            "\u{1F3B0} Let's see where this goes!",
        ]
        showToast(toasts.randomElement()!)
    }

    // MARK: - Toast

    func showToast(_ message: String) {
        toastMessage = message
        let capturedMessage = message
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.5))
            if self.toastMessage == capturedMessage {
                self.toastMessage = nil
            }
        }
    }

    // MARK: - History Management

    func removeHistory(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        StorageService.saveHistory(history)
    }

    // MARK: - Private Helpers

    private func getTimeOfDay() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<21: return "Evening"
        default: return "Late Night"
        }
    }
}
