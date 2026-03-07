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
        request.timeoutInterval = 30
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        var accumulated = ""
        var lineBuffer = Data()

        for try await byte in bytes {
            lineBuffer.append(byte)

            if byte == UInt8(ascii: "\n") {
                // Decode full line as UTF-8 (handles multi-byte chars like emojis)
                guard let line = String(data: lineBuffer, encoding: .utf8)?
                    .trimmingCharacters(in: .newlines) else {
                    lineBuffer.removeAll(keepingCapacity: true)
                    continue
                }
                lineBuffer.removeAll(keepingCapacity: true)

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

        // Retry once on 429/529 (rate limit / overloaded) before giving up
        for attempt in 0..<2 {
            var request = URLRequest(url: searchURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 30
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return nil
            }

            if (httpResponse.statusCode == 429 || httpResponse.statusCode == 529) && attempt < 1 {
                try await Task.sleep(for: .seconds(2))
                continue
            }

            guard httpResponse.statusCode == 200 else {
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

        return nil
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
            You are a NYC food insider — the friend who always has the perfect restaurant pick. You know the walk-in-only spots, the chef's counter worth the wait, the corner places tourists walk past. Suggest ONE specific real, currently-operating restaurant, bar, café, or food experience matching:
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
        You are a NYC local who knows every neighborhood's hidden gems — the speakeasy jazz night, the rooftop film screening, the gallery opening with free wine. Suggest ONE specific real, currently-available experience matching:
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

    // MARK: - Discover Events

    /// Custom error that carries the HTTP status code for better UI messaging.
    struct APIError: Error {
        let statusCode: Int
        let detail: String
    }

    func fetchDiscoverEvents(timeframe: String, category: String?, searchIndex: Int, shownNames: [String] = []) async throws -> [[String: String]] {
        let season = Self.getSeason()
        let today = Self.formatDate(Date())

        let varietyHints = [
            "Focus on lesser-known, off-the-beaten-path events — avoid the most obvious tourist picks.",
            "Prioritize unique, one-time-only events and limited-run experiences over permanent attractions.",
            "Lean toward neighborhood gems and local favorites rather than big-name Broadway or museum staples.",
            "Emphasize new openings, recently launched exhibits, and events that started in the last month.",
            "Highlight free or low-cost events, community gatherings, and hidden cultural experiences.",
            "Focus on immersive, interactive, or participatory events — not just things to watch.",
            "Search for events from independent venues, small galleries, community spaces, and local cultural orgs.",
            "Look for events at unconventional venues — rooftops, warehouses, parks, bookstores, bars with back rooms.",
            "Prioritize events from neighborhood blogs, local Instagram accounts, and community boards over major listing sites.",
            "Focus on NYC-specific seasonal events, block parties, street fairs, and cultural festivals happening right now.",
        ]

        let varietyHint = varietyHints[searchIndex % varietyHints.count]

        let catClause: String
        if let category {
            catClause = "Focus specifically on \(category.lowercased()) events. All 6 results should be \(category.lowercased()) or closely related."
        } else {
            catClause = "Include a diverse mix: theater/shows, museum exhibits, live music, food events, comedy, and seasonal events for \(season)."
        }

        let avoidClause = shownNames.isEmpty ? "" : "\n\nDo NOT suggest any of these previously shown events: \(shownNames.suffix(30).joined(separator: ", "))."

        let prompt = "Today is \(today) (search ID: \(Int(Date().timeIntervalSince1970 * 1000))). Search the web for NYC events happening \(timeframe). \(catClause)\n\n\(varietyHint)\n\nSEARCH STRATEGY: Do NOT just search \"NYC events\" — that only surfaces SEO-heavy aggregators. Instead, search for specific neighborhoods and venue types, e.g. \"Bushwick warehouse party\", \"East Village comedy tonight\", \"Williamsburg gallery opening\", \"Harlem jazz this week\". Mix broad and specific searches to find what a real New Yorker would actually go to — the kind of stuff you'd hear about from a friend, a neighborhood Instagram, or a Nonsense NYC email.\n\nSOURCE DIVERSITY: Do NOT pull most results from Time Out, Eventbrite, or any single aggregator. At most 1 of 6 from any one source. Search direct venue websites, neighborhood blogs (BKlyner, EV Grieve, Gothamist, The Infatuation, Nonsense NYC, Secret NYC), cultural org sites, and venue pages. Prefer the event's own website over a listing page.\(avoidClause)\n\nReturn exactly 6 items. Skip long-running tourist staples (Sleep No More, generic MoMA admission, etc.) unless something special is happening this specific timeframe. Include the url from your search results (event page, ticket page, or venue page) — empty string only if nothing appeared. Respond ONLY with a raw JSON array, no markdown: [{\"name\":\"...\",\"desc\":\"One sentence — what makes it worth going\",\"area\":\"Neighborhood\",\"cat\":\"Category\",\"cost\":\"Price or Free\",\"emoji\":\"...\",\"url\":\"https://... or empty string\"}]"

        let systemPrompt = "You are a hyper-local NYC events concierge — the friend who always knows what's happening. You read Nonsense NYC, follow venue Instagram stories, check community boards, and know the difference between tourist traps and actual local gems. You respond ONLY with a valid JSON array. Never explain, apologize, or add prose. If web search doesn't find specific events, draw on your knowledge of recurring NYC staples at specific venues (comedy at Union Hall, jazz at Smalls, DJs at Nowadays, readings at McNally Jackson, etc.). Always return exactly 6 items."

        // Try Haiku first (faster/cheaper), fall back to Sonnet if overloaded
        let models = ["claude-haiku-4-5-20251001", "claude-sonnet-4-6"]

        for model in models {
            let body: [String: Any] = [
                "model": model,
                "max_tokens": 1800,
                "system": systemPrompt,
                "tools": [["type": "web_search_20250305", "name": "web_search"]],
                "messages": [["role": "user", "content": prompt]],
            ]

            var request = URLRequest(url: searchURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 55
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            // Retry once on 429/529 before trying next model
            for attempt in 0..<2 {
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }

                if (httpResponse.statusCode == 429 || httpResponse.statusCode == 529) && attempt < 1 {
                    try await Task.sleep(for: .seconds(2))
                    continue
                }

                if httpResponse.statusCode == 429 || httpResponse.statusCode == 529 {
                    break // Try next model
                }

                guard httpResponse.statusCode == 200 else {
                    throw APIError(statusCode: httpResponse.statusCode, detail: "Server returned \(httpResponse.statusCode)")
                }

                return Self.parseDiscoverResponse(data)
            }
        }

        throw APIError(statusCode: 529, detail: "All models overloaded")
    }

    private static func parseDiscoverResponse(_ data: Data) -> [[String: String]] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentBlocks = json["content"] as? [[String: Any]] else {
            return []
        }

        let rawText = contentBlocks.compactMap { block -> String? in
            guard block["type"] as? String == "text" else { return nil }
            return block["text"] as? String
        }.joined()

        let cleaned = stripCites(rawText)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let arrayRegex = try? NSRegularExpression(pattern: "\\[[\\s\\S]*\\]"),
              let match = arrayRegex.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)),
              let range = Range(match.range, in: cleaned) else {
            return []
        }

        let arrayString = String(cleaned[range])
        guard let arrayData = arrayString.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: arrayData) as? [[String: Any]] else {
            return []
        }

        return parsed.prefix(8).compactMap { ev -> [String: String]? in
            guard let name = ev["name"] as? String, !name.isEmpty else { return nil }
            return [
                "name": stripCites(name),
                "desc": stripCites(ev["desc"] as? String ?? ""),
                "area": stripCites(ev["area"] as? String ?? ""),
                "cat": ev["cat"] as? String ?? "Event",
                "cost": ev["cost"] as? String ?? "",
                "emoji": ev["emoji"] as? String ?? "\u{1F389}",
                "url": ev["url"] as? String ?? "",
            ]
        }
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
