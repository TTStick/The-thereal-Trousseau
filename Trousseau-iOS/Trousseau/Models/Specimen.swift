//
//  Specimen.swift
//  One archived garment. Mirrors the JSON shape used by the web version.
//

import Foundation

struct Specimen: Identifiable, Codable, Hashable {
    let id: String
    /// Processed, background-removed image, stored relative to documents root.
    var image: String
    /// Original raw photo, kept so the user can re-process if needed.
    var rawImage: String
    var note: String
    var tags: [String]
    /// Hex colors (e.g. "#8b5a3d"), first entry is the most prominent.
    var colors: [String]
    /// ISO yyyy-MM-dd strings — when this garment was worn.
    var logs: [String]
    /// Wall-clock instant the specimen was archived (used for default ordering).
    var createdAt: Date
    /// Original purchase price in CNY. Optional — user may not know.
    /// Synthesised Codable handles the absent-key case for Optional fields,
    /// so legacy `wardrobe_db.json` files decode without migration.
    var purchasePrice: Double?
    /// Hearted by the wearer — drives the "Favorites" filter in Gallery.
    /// Defaults to false; missing in legacy JSON decodes to false.
    var isFavorite: Bool = false
    /// Bookmarked for "want to buy later" — distinct from Favorites which means
    /// "I own and love this". Drives the "Wishlist" filter in Gallery.
    var wishlist: Bool = false

    static func new(id: String, image: String, rawImage: String, note: String, colors: [String], purchasePrice: Double? = nil) -> Specimen {
        Specimen(
            id: id,
            image: image,
            rawImage: rawImage,
            note: note,
            tags: [],
            colors: colors,
            logs: [],
            createdAt: Date(),
            purchasePrice: purchasePrice,
            isFavorite: false,
            wishlist: false
        )
    }

    // MARK: - Derived (read-only)

    /// Number of times the wearer has logged this garment.
    var wornCount: Int { logs.count }

    /// Most recent wear date, parsed from the leading `logs` entry.
    /// Logs are kept sorted descending by `WardrobeStore.addLog`.
    var lastWornDate: Date? {
        guard let s = logs.first else { return nil }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone.current
        return f.date(from: s)
    }

    /// Average cost per wear. `nil` until price AND at least one wear log exist.
    var costPerWear: Double? {
        guard let price = purchasePrice, wornCount > 0 else { return nil }
        return price / Double(wornCount)
    }

    /// Human-friendly "X days ago" string. Empty array → "Never worn".
    func lastWornRelativeString(now: Date = Date()) -> String {
        guard let date = lastWornDate else { return L10n.neverWorn }
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: date), to: cal.startOfDay(for: now)).day ?? 0
        if days <= 0 { return L10n.today }
        if days == 1 { return L10n.yesterday }
        return L10n.daysAgo(days)
    }
}