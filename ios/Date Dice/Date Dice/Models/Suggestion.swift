import Foundation

enum DateStatus: String, Codable, Sendable {
    case rolled
    case locked
    case completed
}

struct Suggestion: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    let name: String
    let desc: String
    let area: String
    let address: String
    let cat: String
    let priceRange: String?
    let cuisine: String?
    let emoji: String
    let tip: String?
    let bookingUrl: String?
    let bookingPlatform: String?
    let rolledAt: Date

    // Lock In lifecycle
    var status: DateStatus
    var lockedAt: Date?
    var completedAt: Date?
    var rating: Int?

    enum CodingKeys: String, CodingKey {
        case name, desc, area, address, cat, priceRange, cuisine, emoji, tip
        case bookingUrl, bookingPlatform, rolledAt
        case status, lockedAt, completedAt, rating
    }

    nonisolated init(name: String, desc: String, area: String, address: String, cat: String,
         priceRange: String? = nil, cuisine: String? = nil, emoji: String,
         tip: String? = nil, bookingUrl: String? = nil, bookingPlatform: String? = nil,
         rolledAt: Date = Date(), status: DateStatus = .rolled) {
        self.name = name; self.desc = desc; self.area = area; self.address = address
        self.cat = cat; self.priceRange = priceRange; self.cuisine = cuisine
        self.emoji = emoji; self.tip = tip; self.bookingUrl = bookingUrl
        self.bookingPlatform = bookingPlatform; self.rolledAt = rolledAt
        self.status = status
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        desc = try c.decode(String.self, forKey: .desc)
        area = try c.decode(String.self, forKey: .area)
        address = try c.decode(String.self, forKey: .address)
        cat = try c.decode(String.self, forKey: .cat)
        priceRange = try c.decodeIfPresent(String.self, forKey: .priceRange)
        cuisine = try c.decodeIfPresent(String.self, forKey: .cuisine)
        emoji = try c.decode(String.self, forKey: .emoji)
        tip = try c.decodeIfPresent(String.self, forKey: .tip)
        bookingUrl = try c.decodeIfPresent(String.self, forKey: .bookingUrl)
        bookingPlatform = try c.decodeIfPresent(String.self, forKey: .bookingPlatform)
        rolledAt = try c.decodeIfPresent(Date.self, forKey: .rolledAt) ?? Date()

        // Backward-compatible: old items without status decode as .rolled
        status = try c.decodeIfPresent(DateStatus.self, forKey: .status) ?? .rolled
        lockedAt = try c.decodeIfPresent(Date.self, forKey: .lockedAt)
        completedAt = try c.decodeIfPresent(Date.self, forKey: .completedAt)
        rating = try c.decodeIfPresent(Int.self, forKey: .rating)
    }

    // MARK: - Lifecycle Mutations

    mutating func lock() {
        status = .locked
        lockedAt = Date()
    }

    mutating func complete(with stars: Int) {
        status = .completed
        completedAt = Date()
        rating = max(1, min(5, stars))
    }
}
