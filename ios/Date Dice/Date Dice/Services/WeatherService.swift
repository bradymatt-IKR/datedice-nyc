import Foundation

struct WeatherService {
    static func fetch(lat: Double, lng: Double) async -> (weather: WeatherInfo, sunTimes: SunTimes?)? {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lng)&current=temperature_2m,apparent_temperature,weather_code,relative_humidity_2m,wind_speed_10m,uv_index&daily=sunrise,sunset&temperature_unit=fahrenheit&wind_speed_unit=mph&timezone=America/New_York"

        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let current = json["current"] as? [String: Any] else {
                return nil
            }

            guard let temperature = current["temperature_2m"] as? Double,
                  let apparentTemp = current["apparent_temperature"] as? Double,
                  let weatherCode = current["weather_code"] as? Int,
                  let humidity = current["relative_humidity_2m"] as? Double,
                  let windSpeed = current["wind_speed_10m"] as? Double,
                  let uvIndex = current["uv_index"] as? Double else {
                return nil
            }

            let classified = WeatherInfo.classify(code: weatherCode)

            let weather = WeatherInfo(
                temperature: temperature,
                apparentTemp: apparentTemp,
                weatherCode: weatherCode,
                humidity: humidity,
                windSpeed: windSpeed,
                uvIndex: uvIndex,
                description: classified.desc,
                emoji: classified.emoji,
                autoFilter: classified.filter
            )

            // Parse sunrise/sunset from daily data
            var sunTimes: SunTimes?
            if let daily = json["daily"] as? [String: Any],
               let sunriseArr = daily["sunrise"] as? [String],
               let sunsetArr = daily["sunset"] as? [String],
               let srStr = sunriseArr.first,
               let ssStr = sunsetArr.first {
                let fmt = ISO8601DateFormatter()
                fmt.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
                if let srDate = fmt.date(from: srStr),
                   let ssDate = fmt.date(from: ssStr) {
                    let cal = Calendar.current
                    let srMin = cal.component(.hour, from: srDate) * 60 + cal.component(.minute, from: srDate)
                    let ssMin = cal.component(.hour, from: ssDate) * 60 + cal.component(.minute, from: ssDate)
                    sunTimes = SunTimes(sunrise: srMin, sunset: ssMin)
                }
            }

            return (weather: weather, sunTimes: sunTimes)
        } catch {
            return nil
        }
    }
}
