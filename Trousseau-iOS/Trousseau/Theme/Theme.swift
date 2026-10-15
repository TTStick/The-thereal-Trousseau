//
//  Theme.swift
//  Centralised palette, fonts, and paper texture.
//

import SwiftUI

extension Color {
    /// Backwards-compat default parchment — now lives in `ThemeSettings`.
    /// Kept as a fallback for places that haven't been migrated to read
    /// from `ThemeSettings.baseColor` yet.
    static let parchment = ThemeSettings.color(warmth: 0.6, darkness: 0.0)
    /// Deep ink for typography and strokes (#2c2c2c).
    static let ink = Color(red: 44/255, green: 44/255, blue: 44/255)
    /// Soft danger red used by "Discard" (#8a2c2c).
    static let dangerInk = Color(red: 138/255, green: 44/255, blue: 44/255)
    /// Faded ink used for borders and grid lines.
    static let fadedInk = Color(red: 44/255, green: 44/255, blue: 44/255).opacity(0.3)
}

extension Font {
    /// Pinyon Script — used for h1 titles, specimen numbers, manifesto headings.
    /// Falls back to a cursive system font if the embedded font fails to load.
    static func scriptTitle(_ size: CGFloat = 48) -> Font {
        .custom("PinyonScript-Regular", size: size, relativeTo: .largeTitle)
    }

    /// Cormorant Garamond body / serif text. Three weights bundled.
    static func serifBody(_ size: CGFloat = 17) -> Font {
        .custom("CormorantGaramond-Regular", size: size, relativeTo: .body)
    }
    static func serifItalic(_ size: CGFloat = 17) -> Font {
        .custom("CormorantGaramond-Italic", size: size, relativeTo: .body)
    }
    static func serifHeadline(_ size: CGFloat = 17) -> Font {
        .custom("CormorantGaramond-SemiBold", size: size, relativeTo: .body)
    }
}

extension View {
    /// Legacy entry point — keeps any caller still using it alive.
    /// New code should drop a `PaperBackdrop()` as the bottom layer of a ZStack.
    func paperBackground() -> some View {
        self.background(PaperBackdrop())
    }
}

/// Standalone paper-backdrop view. Reads `ThemeSettings` from the environment
/// so the warmth / darkness / texture knobs are reflected everywhere at once.
struct PaperBackdrop: View {
    @EnvironmentObject var theme: ThemeSettings

    var body: some View {
        ZStack {
            // Radial vignette: brighter in the centre, deep amber at corners.
            RadialGradient(
                colors: [theme.baseColor, theme.deepColor],
                center: .center,
                startRadius: 60,
                endRadius: 520
            )
            // Warm wash diagonal — gives the page a candlelit feel.
            // Opacity scales with the texture knob so a "smooth" setting
            // really does turn off the wash.
            LinearGradient(
                colors: [
                    theme.warmWash.opacity(0.18 * theme.texture),
                    .clear,
                    theme.deepColor.opacity(0.22 * theme.texture)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            // Hand-drawn fibre grain (warm sepia flecks).
            PaperGrain(strength: theme.texture)
            // Fine dark hairline grain — equivalent of the web SVG noise.
            NoiseOverlay(strength: theme.texture)
        }
        .ignoresSafeArea()
    }
}

/// Larger warm flecks — gives the surface its "this is actual paper" character.
private struct PaperGrain: View {
    /// 0 = no grain, 1 = strong fibre
    var strength: Double
    var body: some View {
        Canvas { ctx, size in
            guard strength > 0.02 else { return }
            let density = Int((size.width * size.height) / 600 * strength)
            let darken: Double = 1.0 - strength * 0.3
            for _ in 0..<density {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                let r = CGFloat.random(in: 0.6...2.0)
                let tone = Color(
                    red: (148/255 * darken) + CGFloat.random(in: -0.06...0.06),
                    green: (110/255 * darken) + CGFloat.random(in: -0.06...0.06),
                    blue:  (62/255 * darken) + CGFloat.random(in: -0.06...0.06)
                )
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                         with: .color(tone.opacity(Double.random(in: 0.20...0.45) * strength)))
            }
        }
        .allowsHitTesting(false)
        .blendMode(.multiply)
    }
}

/// Fine dark hairline grain — the equivalent of the web SVG `feTurbulence`.
private struct NoiseOverlay: View {
    var strength: Double
    var body: some View {
        Canvas { ctx, size in
            guard strength > 0.02 else { return }
            let count = Int((size.width * size.height) / 12 * strength)
            for _ in 0..<count {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                let a = Double.random(in: 0.06...0.14) * strength
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                         with: .color(.ink.opacity(a)))
            }
        }
        .allowsHitTesting(false)
        .blendMode(.multiply)
        .opacity(0.7)
    }
}

/// Reusable parchment card with the same double-line border treatment
/// used in `detail.html` and the gallery frames.
struct ParchmentFrame<Content: View>: View {
    var doubleLine: Bool = false
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(doubleLine ? 12 : 8)
            .overlay(
                Rectangle()
                    .stroke(Color.ink, lineWidth: 1)
            )
            .overlay(
                Group {
                    if doubleLine {
                        Rectangle()
                            .stroke(Color.ink, lineWidth: 1)
                            .padding(2)
                    }
                }
            )
    }
}
