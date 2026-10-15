//
//  OutfitEntry.swift
//  One day of dressing — date + the specimens worn + a note/theme.
//

import Foundation

struct OutfitEntry: Identifiable, Codable, Hashable {
    /// Stable id. String (not UUID) so the same JSON shape works whether
    /// seeded by hand, generated in-app, or migrated from the web Flask backend.
    let id: String
    /// ISO yyyy-MM-dd — keyed to the same date format as `Specimen.logs`,
    /// so a day's "what I wore" can intersect with the per-item wear log.
    var date: String
    /// IDs of the specimens that made up the outfit, in any order.
    var specimenIds: [String]
    /// Free-text note the wearer attached. Often a theme name like
    /// "Memorial Service" or "Sunday brunch".
    var note: String
    /// Wall-clock instant the entry was created (used for default sort).
    var createdAt: Date

    init(id: String = UUID().uuidString.lowercased(),
         date: String,
         specimenIds: [String],
         note: String,
         createdAt: Date = Date()) {
        self.id = id
        self.date = date
        self.specimenIds = specimenIds
        self.note = note
        self.createdAt = createdAt
    }

    /// Convenience: today's date in the canonical yyyy-MM-dd string.
    static func todayISO() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone.current
        return f.string(from: Date())
    }
}