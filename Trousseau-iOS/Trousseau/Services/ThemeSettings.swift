//
//  ThemeSettings.swift
//  User-adjustable paper theme. Persisted via @AppStorage so all views
//  react automatically when the sliders move.
//

import SwiftUI

/// Three independent knobs that describe the page surface.
///
/// - `warmth`     0 = cool ivory (#f4ecd8, web version), 1 = warm amber
/// - `darkness`   0 = untouched base, 1 = darkened by 30 % (deeper shadow corners)
/// - `texture`    0 = glass-smooth, 1 = strong fibre grain + heavy noise
///
/// Each value is a `@AppStorage` backed `Double`, so the moment a slider
/// moves the entire view tree that depends on it invalidates and redraws.
final class ThemeSettings: ObservableObject {
    @AppStorage("trousseau.warmth")   var warmth:   Double = 0.6
    @AppStorage("trousseau.darkness") var darkness: Double = 0.0
    @AppStorage("trousseau.texture")  var texture:  Double = 0.6

    /// The page-filling base color, computed from `warmth` and `darkness`.
    var baseColor: Color {
        Self.color(warmth: warmth, darkness: darkness)
    }

    /// The vignette rim color (always a bit deeper than the centre).
    var deepColor: Color {
        Self.color(warmth: min(1.0, warmth + 0.15), darkness: min(1.0, darkness + 0.2))
    }

    /// Warm wash used in the diagonal overlay.
    var warmWash: Color {
        let r = 232.0/255, g = 192.0/255, b = 128.0/255
        let k = 1.0 - darkness * 0.3
        return Color(red: r * k, green: g * k, blue: b * k)
    }

    // MARK: - Color math

    /// Interpolate in sRGB between the cool ivory anchor and the warm amber
    /// anchor, then apply a multiplicative darken.
    static func color(warmth: Double, darkness: Double) -> Color {
        // Cold anchor — matches the web version's #f4ecd8.
        let cold = (r: 244.0, g: 236.0, b: 216.0)
        // Warm anchor — saturated amber parchment.
        let warm = (r: 218.0, g: 184.0, b: 124.0)
        let t = warmth.clamped(to: 0...1)
        let r = cold.r + (warm.r - cold.r) * t
        let g = cold.g + (warm.g - cold.g) * t
        let b = cold.b + (warm.b - cold.b) * t
        let k = 1.0 - darkness.clamped(to: 0...1) * 0.35
        return Color(red: (r * k) / 255.0, green: (g * k) / 255.0, blue: (b * k) / 255.0)
    }

    /// Reset to the defaults we shipped with.
    func resetToDefaults() {
        warmth = 0.6
        darkness = 0.0
        texture = 0.6
    }
}

// MARK: - Range helper

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
