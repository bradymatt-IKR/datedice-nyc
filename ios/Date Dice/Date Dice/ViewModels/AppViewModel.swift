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
    var altsLoading = false
    var altsRetryAvailable = false
    var showConfetti = false
    private var currentRollId: UUID?
    private var messageTimer: Timer?
    private var lastRollType: String?
    private var lastRollNearMe: (lat: Double, lng: Double, borough: String?)?

    // Sky phase
    var skyPhaseInfo = SkyPhaseInfo.nightDefault
    var skyColors = ResolvedSkyColors.resolve(from: .nightDefault)
    private var sunTimes: SunTimes?
    private var skyTimer: Timer?

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
        updateSkyPhase()
        startSkyTimer()
    }

    deinit {
        skyTimer?.invalidate()
    }

    // MARK: - Weather

    func loadWeather() async {
        weatherLoading = true
        let lat = locationManager.latitude ?? 40.6782
        let lng = locationManager.longitude ?? -73.9442
        let result = await WeatherService.fetch(lat: lat, lng: lng)
        await MainActor.run {
            self.weather = result?.weather
            if let st = result?.sunTimes {
                self.sunTimes = st
                self.updateSkyPhase()
            }
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
        defer { isRolling = false }

        showResult = false
        currentResult = nil
        alternates = []
        streamingText = ""
        altsLoading = false
        altsRetryAvailable = false
        showConfetti = false
        loadingMessage = AppConstants.loadingMessages.randomElement() ?? "Rolling..."

        // Cycle loading messages every 3s
        messageTimer?.invalidate()
        messageTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isRolling else {
                    self?.messageTimer?.invalidate()
                    return
                }
                self.loadingMessage = AppConstants.loadingMessages.randomElement() ?? "Rolling..."
            }
        }

        // Safety timeout — reset after 45s no matter what
        let rollId = UUID()
        currentRollId = rollId
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(45))
            guard let self, self.currentRollId == rollId, self.isRolling else { return }
            self.isRolling = false
            self.showToast("Taking too long \u{2014} tap to try again!")
        }

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

        // Try streaming first, fall back to non-streaming
        var suggestion: Suggestion?

        do {
            let vm = self
            suggestion = try await api.streamSuggestion(prompt: prompt) { accumulated in
                Task { @MainActor in
                    vm.streamingText = accumulated
                }
            }
        } catch {
            // Streaming threw — will try fallback below
        }

        // If streaming returned nil (parse failure) or threw, try non-streaming
        if suggestion == nil {
            suggestion = try? await api.fetchSuggestion(prompt: prompt)
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

            // Store context so user can request alternates later
            lastRollType = type
            lastRollNearMe = nearMe
        } else {
            showToast("Couldn't find a suggestion — try again!")
        }
        // isRolling = false handled by defer
    }

    // MARK: - Lock In Lifecycle

    /// Whether the current result has been locked in (or completed).
    var isLocked: Bool {
        currentResult?.status == .locked || currentResult?.status == .completed
    }

    /// Count of upcoming (locked) dates for tab badge.
    var upcomingCount: Int {
        history.filter { $0.status == .locked }.count
    }

    var upcomingDates: [Suggestion] {
        history.filter { $0.status == .locked }
    }

    var completedDates: [Suggestion] {
        history.filter { $0.status == .completed }
    }

    @MainActor
    func lockIn(_ suggestion: Suggestion) async {
        // Update status in history
        if let index = history.firstIndex(where: { $0.id == suggestion.id }) {
            history[index].lock()
            currentResult = history[index]
        } else {
            var locked = suggestion
            locked.lock()
            history.insert(locked, at: 0)
            currentResult = locked
        }
        StorageService.saveHistory(history)

        Haptics.lockIn()
        showConfetti = true
        showToast("\u{1F512} Locked in! It\u{2019}s a date.")

        // Add to calendar automatically — one action, one commitment
        let calStatus = await CalendarService.addDateNight(suggestion)
        if calStatus == .added {
            showToast("\u{1F4C5} Added to your calendar")
        }

        // Schedule notifications (permission requested on first use)
        let granted = await NotificationService.requestPermission()
        if granted {
            NotificationService.scheduleDateReminder(for: suggestion)
            NotificationService.schedulePostDatePrompt(for: suggestion)
        }
    }

    func markComplete(_ suggestionId: UUID, rating: Int) {
        guard let index = history.firstIndex(where: { $0.id == suggestionId }) else { return }
        history[index].complete(with: rating)
        StorageService.saveHistory(history)
        Haptics.complete()
        showToast("\u{2B50} Date rated! \(rating) star\(rating == 1 ? "" : "s")")
        NotificationService.cancelNotifications(for: suggestionId)
    }

    func removeEntry(_ suggestionId: UUID) {
        history.removeAll { $0.id == suggestionId }
        StorageService.saveHistory(history)
        NotificationService.cancelNotifications(for: suggestionId)
    }

    // MARK: - Alternates (user-triggered)

    @MainActor
    func requestAlternates() async {
        guard !altsLoading, alternates.isEmpty else { return }
        guard let type = lastRollType else { return }

        altsLoading = true
        altsRetryAvailable = false

        let prompt1 = await api.buildPrompt(
            type: type,
            filters: filters,
            usedNames: usedNames,
            nearMe: lastRollNearMe,
            recentCategories: recentCategories,
            variation: 1
        )
        let prompt2 = await api.buildPrompt(
            type: type,
            filters: filters,
            usedNames: usedNames,
            nearMe: lastRollNearMe,
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
            usedNames.append(s.name)
        }
        if let s = r2 {
            results.append(s)
            usedNames.append(s.name)
        }

        alternates = results
        altsLoading = false

        if results.isEmpty {
            altsRetryAvailable = true
            showToast("Couldn\u{2019}t find more options \u{2014} tap to retry")
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

    // MARK: - Sky Phase

    func updateSkyPhase() {
        let times = sunTimes ?? seasonalFallbackSunTimes()
        let info = computeSkyPhase(sunTimes: times)
        skyPhaseInfo = info
        skyColors = ResolvedSkyColors.resolve(from: info)
    }

    private func startSkyTimer() {
        skyTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateSkyPhase()
            }
        }
    }
}
