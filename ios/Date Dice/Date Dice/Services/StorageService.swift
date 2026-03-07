import Foundation

struct StorageService {
    private static let historyKey = "datedice:history"
    private static let favoritesKey = "datedice:favorites"

    static func loadHistory() -> [Suggestion] {
        return load(key: historyKey)
    }

    static func saveHistory(_ items: [Suggestion]) {
        save(items, key: historyKey)
    }

    static func loadFavorites() -> [Suggestion] {
        return load(key: favoritesKey)
    }

    static func saveFavorites(_ items: [Suggestion]) {
        save(items, key: favoritesKey)
    }

    // MARK: - Private Helpers

    private static func load(key: String) -> [Suggestion] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode([Suggestion].self, from: data)
        } catch {
            return []
        }
    }

    private static func save(_ items: [Suggestion], key: String) {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            // Silently fail on encode error
        }
    }
}
