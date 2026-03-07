import Foundation

struct WeatherInfo: Equatable {
    let temperature: Double
    let apparentTemp: Double
    let weatherCode: Int
    let humidity: Double
    let windSpeed: Double
    let uvIndex: Double
    let description: String
    let emoji: String
    let autoFilter: String

    static func classify(code: Int) -> (desc: String, emoji: String, filter: String) {
        switch code {
        case 0: return ("Clear sky", "☀️", "Sunny")
        case 1, 2: return ("Partly cloudy", "⛅", "Cloudy")
        case 3: return ("Overcast", "☁️", "Cloudy")
        case 45, 48: return ("Foggy", "🌫", "Cloudy")
        case 51, 53, 55: return ("Drizzle", "🌦", "Rainy")
        case 61, 63, 65, 80, 81, 82: return ("Rainy", "🌧", "Rainy")
        case 66, 67: return ("Freezing rain", "🧊", "Cold")
        case 71, 73, 75, 77, 85, 86: return ("Snowy", "❄️", "Snowy")
        case 95, 96, 99: return ("Thunderstorm", "⛈", "Rainy")
        default: return ("Clear", "☀️", "Sunny")
        }
    }
}
