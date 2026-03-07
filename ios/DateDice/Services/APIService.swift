import Foundation

actor APIService {
    static let shared = APIService()

    private let streamURL = URL(string: "https://datedice-nyc.vercel.app/api/stream")!
    private let searchURL = URL(string: "https://datedice-nyc.vercel.app/api/search")!

    // MARK: - Public API

    func streamSuggestion(prompt: String, onText: @Sendable @escaping (String) -> Void) async throws -> Suggestion? {
        let body = requestBody(prompt: prompt, stream: true)
        var request = URLRequest(url: streamURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return nil
        }

        var accumulated = ""
        var buffer = ""

        for try await byte in bytes {
            let char = String(UnicodeScalar(byte))
            buffer += char

            if char == "\n" {
                let line = buffer.trimmingCharacters(in: .newlines)
                buffer = ""

                guard line.hasPrefix("data: ") else { continue }
                let payload = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                if payload == "[DONE]" { break }

                guard let eventData = payload.data(using: .utf8),
                      let event = try? JSONSerialization.jsonObject(with: eventData) as? [String: Any],
                      let type = event["type"] as? String, type == "content_block_delta",
                      let delta = event["delta"] as? [String: Any],
                      let deltaType = delta["type"] as? String, deltaType == "text_delta",
                      let text = delta["text"] as? String else {
                    continue
                }

                accumulated += text
                onText(accumulated)
            }
        }

        return Self.parseJSON(accumulated)
    }

    func fetchSuggestion(prompt: String) async throws -> Suggestion? {
        let body = requestBody(prompt: prompt, stream: false)
        var request = URLRequest(url: searchURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return nil
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        // Extract text from content blocks
        guard let contentBlocks = json["content"] as? [[String: Any]] else { return nil }
        let raw = contentBlocks.compactMap { block -> String? in
            guard block["type"] as? String == "text" else { return nil }
            return block["text"] as? String
        }.joined()

        return Self.parseJSON(raw)
    }

    // MARK: - Prompt Builder

    func buildPrompt(
        type: String,
        filters: FilterState,
        usedNames: [String] = [],
        nearMe: (lat: Double, lng: Double, borough: String?)? = nil,
        recentCategories: [String] = [],
        variation: Int? = nil
    ) -> String {
        let season = Self.getSeason()
        let today = Self.formatDate(Date())
        let avoidList = usedNames.suffix(80).joined(separator: ", ")

        let neighborhoodStr = filters.neighborhood.isEmpty
            ? "anywhere in NYC or nearby"
            : filters.neighborhood.joined(separator: ", ")

        let vibeStr = filters.vibe.isEmpty ? "any" : filters.vibe.joined(separator: ", ")
        let cuisineStr = filters.cuisine.isEmpty ? "any cuisine — surprise us" : filters.cuisine.joined(separator: ", ")

        var nearMeStr = ""
        if let loc = nearMe {
            let latStr = String(format: "%.3f", loc.lat)
            let lngStr = String(format: "%.3f", loc.lng)
            let boroughNote = loc.borough.map { " (\($0))" } ?? ""
            nearMeStr = "\n- User's approximate location: \(latStr), \(lngStr)\(boroughNote). Prioritize spots within a 15-minute walk or short subway ride."
        }

        var diversityHint = ""
        if recentCategories.count >= 2 {
            let recent = recentCategories.suffix(3).joined(separator: ", ")
            diversityHint = "\n- For variety, suggest something DIFFERENT from these recent picks: \(recent). Go for a different cuisine, style, or vibe."
        }

        let rollId = Int(Date().timeIntervalSince1970 * 1000)
        let variationHint: String
        if let v = variation {
            variationHint = "\nImportant: Pick a DIFFERENT and UNIQUE option — variation #\(v), roll \(rollId). Do NOT repeat any previously suggested place."
        } else {
            variationHint = "\nRoll ID: \(rollId)."
        }

        let jsonNote = "\n\nRespond with ONLY a raw JSON object — no markdown, no backticks, no extra text." + variationHint

        let avoidSection = avoidList.isEmpty ? "" : "Do NOT suggest: \(avoidList)\n"

        if type == "food" {
            return """
            You are a NYC food expert with deep knowledge of every neighborhood's restaurant scene. Suggest ONE specific real, currently-operating restaurant, bar, café, or food experience matching:
            - Neighborhood: \(neighborhoodStr)\(nearMeStr)
            - Cuisine: \(cuisineStr)
            - Time: \(filters.timeOfDay ?? "any")
            - Weather: \(filters.weather ?? "any") (cozy/indoor for cold/rain; outdoor/rooftop for warm/sunny)
            - Vibe: \(vibeStr)
            - Budget: \(filters.budget ?? "any") (Free=free events, Under $50=casual, $50-150=mid-range, $150-300=upscale, Splurge=$300+/person)
            - Duration: \(filters.duration ?? "any")
            - Season: \(season) · Today: \(today)\(diversityHint)
            \(avoidSection)
            - For bookingUrl: ONLY use a URL that appeared in your web search results. Copy the exact URL from search results — do NOT guess, construct, or fabricate URLs. Use empty string if no relevant booking page appeared in results or if walk-in only.\(jsonNote)
            {"name":"...","desc":"One vivid sentence — what makes it special and what to order","area":"Neighborhood","address":"Full street address","cat":"Food & Drink","priceRange":"$/$$/$$$/$$$$","cuisine":"type","emoji":"🍽","tip":"One insider tip","bookingUrl":"exact URL from search results or empty string","bookingPlatform":"Resy|OpenTable|Tock|Website|WalkIn"}
            """
        }

        let actTypeStr = filters.activityType ?? "any activity or experience"
        return """
        You are a NYC experiences expert with deep knowledge of museums, shows, parks, events, classes, and hidden gems. Suggest ONE specific real, currently-available experience matching:
        - Type: \(actTypeStr)
        - Neighborhood: \(neighborhoodStr)\(nearMeStr)
        - Time: \(filters.timeOfDay ?? "any")
        - Weather: \(filters.weather ?? "any") (indoor for rain/cold; outdoor for sunny)
        - Vibe: \(vibeStr)
        - Budget: \(filters.budget ?? "any") (Free, Under $50, $50-150, $150-300, Splurge=$300+)
        - Duration: \(filters.duration ?? "any")
        - Season: \(season) · Today: \(today)\(diversityHint)
        \(avoidSection)
        - For bookingUrl: ONLY use a URL that appeared in your web search results. Copy the exact URL from search results — do NOT guess, construct, or fabricate URLs. Use empty string if no relevant booking page appeared in results or if free/no-booking.\(jsonNote)
        {"name":"...","desc":"One vivid sentence — what makes it special and why it's great for a date","area":"Neighborhood or location","address":"Address or general area","cat":"Activity","emoji":"✨","tip":"One insider tip","bookingUrl":"exact URL from search results or empty string","bookingPlatform":"Eventbrite|Website|Ticketmaster|NoReservation"}
        """
    }

    // MARK: - Private Helpers

    private func requestBody(prompt: String, stream: Bool) -> [String: Any] {
        var body: [String: Any] = [
            "model": "claude-sonnet-4-6",
            "max_tokens": 1000,
            "tools": [["type": "web_search_20250305", "name": "web_search"]],
            "messages": [["role": "user", "content": prompt]],
        ]
        if stream {
            body["stream"] = true
        }
        return body
    }

    private static func stripCites(_ str: String) -> String {
        var result = str
        // Remove <cite ...>...</cite> tags
        if let regex = try? NSRegularExpression(pattern: "<cite[^>]*>[\\s\\S]*?</cite>", options: .caseInsensitive) {
            result = regex.stringByReplacingMatches(in: result, range: NSRange(result.startIndex..., in: result), withTemplate: "")
        }
        // Remove orphan <cite> or </cite> tags
        if let regex = try? NSRegularExpression(pattern: "</?cite[^>]*>", options: .caseInsensitive) {
            result = regex.stringByReplacingMatches(in: result, range: NSRange(result.startIndex..., in: result), withTemplate: "")
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func parseJSON(_ text: String) -> Suggestion? {
        var clean = stripCites(text)
        clean = clean.replacingOccurrences(of: "```json", with: "")
        clean = clean.replacingOccurrences(of: "```", with: "")
        clean = clean.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let regex = try? NSRegularExpression(pattern: "\\{[\\s\\S]*\\}"),
              let match = regex.firstMatch(in: clean, range: NSRange(clean.startIndex..., in: clean)),
              let range = Range(match.range, in: clean) else {
            return nil
        }

        let jsonString = String(clean[range])
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        guard let name = json["name"] as? String,
              let desc = json["desc"] as? String,
              let area = json["area"] as? String,
              let address = json["address"] as? String,
              let cat = json["cat"] as? String,
              let emoji = json["emoji"] as? String else {
            return nil
        }

        return Suggestion(
            name: name,
            desc: desc,
            area: area,
            address: address,
            cat: cat,
            priceRange: json["priceRange"] as? String,
            cuisine: json["cuisine"] as? String,
            emoji: emoji,
            tip: json["tip"] as? String,
            bookingUrl: json["bookingUrl"] as? String,
            bookingPlatform: json["bookingPlatform"] as? String,
            rolledAt: Date()
        )
    }

    static func getSeason() -> String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5: return "Spring"
        case 6...8: return "Summer"
        case 9...11: return "Fall"
        default: return "Winter"
        }
    }

    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date)
    }
}
