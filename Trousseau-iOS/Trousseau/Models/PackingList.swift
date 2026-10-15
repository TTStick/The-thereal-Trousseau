//
//  PackingList.swift
//  A curated kit for a trip — name, travel window, and a list of specimens
//  the traveller intends to bring, each with a packed/not-packed toggle.
//

import Foundation

struct PackingList: Identifiable, Codable, Hashable {
    /// Stable id (String, not UUID — same JSON shape rationale as OutfitEntry).
    let id: String

    /// Free-text trip title — "Kyoto Autumn", "Lake Como Wedding".
    var title: String

    /// ISO yyyy-MM-dd, optional so a half-built draft still saves.
    var startDate: String?

    /// ISO yyyy-MM-dd, optional.
    var endDate: String?

    /// The chosen specimens, in any order. The order is the wearer's
    /// intended packing order — top of suitcase first.
    var items: [PackingItem]

    /// Wall-clock instant the entry was created.
    var createdAt: Date

    init(id: String = UUID().uuidString.lowercased(),
         title: String,
         startDate: String? = nil,
         endDate: String? = nil,
         items: [PackingItem] = [],
         createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.items = items
        self.createdAt = createdAt
    }

    /// Fraction of items already packed (0...1).
    var progress: Double {
        guard !items.isEmpty else { return 0 }
        let done = items.filter(\.packed).count
        return Double(done) / Double(items.count)
    }

    /// Convenience for header display: "OCT 18 — OCT 25" (or localised
    /// "from OCT 18" / "until OCT 25" if only one date is set).
    var dateRangeString: String? {
        switch (startDate, endDate) {
        case let (s?, e?):
            return "\(shortMD(s)) — \(shortMD(e))"
        case let (s?, nil):
            return L10n.fromDate(shortMD(s))
        case let (nil, e?):
            return L10n.untilDate(shortMD(e))
        default:
            return nil
        }
    }

    private func shortMD(_ iso: String) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: iso) else { return iso }
        let out = DateFormatter(); out.dateFormat = "MMM d"
        return out.string(from: d).uppercased()
    }
}

/// One row in a packing list — a chosen specimen + whether it's been
/// ticked into the suitcase. Kept as its own struct so a single change
/// (toggling packed) can re-encode just that item.
struct PackingItem: Identifiable, Codable, Hashable {
    var id: String { specimenId }
    let specimenId: String
    var packed: Bool

    init(specimenId: String, packed: Bool = false) {
        self.specimenId = specimenId
        self.packed = packed
    }
}