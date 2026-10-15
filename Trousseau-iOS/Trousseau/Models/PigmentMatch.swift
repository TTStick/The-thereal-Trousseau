//
//  PigmentMatch.swift
//  Color matching helpers for the "配色检索" feature.
//  Operates on hex strings, not SwiftUI Color, so the math is portable.
//

import Foundation
import SwiftUI

extension String {
    /// Parses "#RRGGBB" → (r, g, b) bytes 0–255. Returns nil on malformed input.
    var rgbBytes: (Int, Int, Int)? {
        let s = self.replacingOccurrences(of: "#", with: "")
        guard s.count == 6, let v = UInt64(s, radix: 16) else { return nil }
        return (Int((v >> 16) & 0xff), Int((v >> 8) & 0xff), Int(v & 0xff))
    }
}

extension Color {
    /// Builds a SwiftUI `Color` from "#RRGGBB" or "RRGGBB" hex. Falls back to
    /// `.ink` on malformed input so callers can stay nil-free.
    init(hex hexString: String, fallback: Color = .ink) {
        let s = hexString.replacingOccurrences(of: "#", with: "")
        guard s.count == 6, let v = UInt64(s, radix: 16) else {
            self = fallback
            return
        }
        let r = Double((v >> 16) & 0xff) / 255
        let g = Double((v >> 8)  & 0xff) / 255
        let b = Double( v        & 0xff) / 255
        self = Color(red: r, green: g, blue: b)
    }
}

extension Specimen {
    /// SwiftUI Color for the primary (first) pigment — useful for swatches
    /// and placeholders when the image hasn't loaded.
    var dominantColor: Color {
        Color(hex: colors.first ?? "2c2c2c")
    }
}

enum Pigment {
    /// Specimens whose `colors` array contains a hex within RGB-sq-distance
    /// `threshold` of `targetHex`. Empty array if either side can't be parsed.
    ///
    /// The default threshold (~3000) is roughly "within 30 units per channel"
    /// which catches slight palette quantisation differences without
    /// accidentally matching dissimilar hues (e.g. terracotta vs burgundy).
    static func matching(targetHex: String,
                         in specimens: [Specimen],
                         threshold: Int = 3000) -> [Specimen] {
        guard let target = targetHex.rgbBytes else { return [] }
        return specimens.filter { spec in
            spec.colors.contains { hex in
                guard let c = hex.rgbBytes else { return false }
                let dr = c.0 - target.0
                let dg = c.1 - target.1
                let db = c.2 - target.2
                return (dr*dr + dg*dg + db*db) <= threshold
            }
        }
    }

    /// Aggregated dominant colors across all specimens.
    /// Returns (hex, count) sorted by count desc, capped at `limit`.
    /// Specimens can contribute multiple colors; the primary (first) color
    /// is weighted x3 so the dominant pigment shows up first.
    static func dominant(in specimens: [Specimen], limit: Int = 8) -> [(String, Int)] {
        var counter: [String: Int] = [:]
        for s in specimens {
            guard let primary = s.colors.first else { continue }
            counter[primary, default: 0] += 3
            for c in s.colors.dropFirst() {
                counter[c, default: 0] += 1
            }
        }
        return counter
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { ($0.key, $0.value) }
    }
}