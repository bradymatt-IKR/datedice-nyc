import Foundation

struct Suggestion: Codable, Identifiable, Equatable {
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

    enum CodingKeys: String, CodingKey {
        case name, desc, area, address, cat, priceRange, cuisine, emoji, tip, bookingUrl, bookingPlatform, rolledAt
    }

    init(name: String, desc: String, area: String, address: String, cat: String,
         priceRange: String? = nil, cuisine: String? = nil, emoji: String,
         tip: String? = nil, bookingUrl: String? = nil, bookingPlatform: String? = nil,
         rolledAt: Date = Date()) {
        self.name = name; self.desc = desc; self.area = area; self.address = address
        self.cat = cat; self.priceRange = priceRange; self.cuisine = cuisine
        self.emoji = emoji; self.tip = tip; self.bookingUrl = bookingUrl
        self.bookingPlatform = bookingPlatform; self.rolledAt = rolledAt
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
    }
}
