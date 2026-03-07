import Foundation

struct FilterState: Equatable {
    var category: String?
    var timeOfDay: String?
    var weather: String?
    var vibe: [String] = []
    var budget: String?
    var duration: String?
    var cuisine: [String] = []
    var activityType: String?
    var neighborhood: [String] = []

    var isEmpty: Bool {
        category == nil && timeOfDay == nil && weather == nil && vibe.isEmpty
        && budget == nil && duration == nil && cuisine.isEmpty
        && activityType == nil && neighborhood.isEmpty
    }

    mutating func clear() {
        self = FilterState()
    }

    var activeCount: Int {
        var count = 0
        if category != nil { count += 1 }
        if timeOfDay != nil { count += 1 }
        if weather != nil { count += 1 }
        count += vibe.count
        if budget != nil { count += 1 }
        if duration != nil { count += 1 }
        count += cuisine.count
        if activityType != nil { count += 1 }
        count += neighborhood.count
        return count
    }
}
