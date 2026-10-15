//
//  SettingsView.swift
//  User-tunable paper surface. Three sliders, live preview, reset button.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var theme: ThemeSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            PaperBackdrop()
            ScrollView {
                VStack(spacing: 32) {
                    header
                    preview
                    warmthSlider
                    darknessSlider
                    textureSlider
                    resetButton
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
                    .font(.serifHeadline(14))
                    .tracking(2)
                    .foregroundColor(.ink)
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 4) {
            Text("Paper Atelier")
                .font(.scriptTitle(44))
                .foregroundColor(.ink)
            Text("Tune the surface to your taste")
                .font(.serifItalic(15))
                .foregroundColor(.ink.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }

    /// Live mini-preview of the current surface — gives immediate feedback
    /// while the user drags the sliders.
    private var preview: some View {
        VStack(spacing: 8) {
            ZStack {
                PaperBackdrop()
                VStack(spacing: 6) {
                    Text("Preview")
                        .font(.scriptTitle(28))
                        .foregroundColor(.ink.opacity(0.85))
                    Rectangle()
                        .fill(Color.ink.opacity(0.6))
                        .frame(width: 120, height: 1)
                        .overlay(
                            Rectangle()
                                .fill(Color.ink.opacity(0.6))
                                .frame(width: 120, height: 1)
                                .offset(y: 3)
                        )
                    Text("Specimen No. 12")
                        .font(.serifItalic(15))
                        .foregroundColor(.ink.opacity(0.7))
                }
                .padding(20)
            }
            .frame(height: 180)
            .overlay(
                Rectangle()
                    .stroke(Color.ink.opacity(0.5), lineWidth: 1)
                    .padding(1)
            )
            .overlay(
                Rectangle()
                    .stroke(Color.ink.opacity(0.5), lineWidth: 1)
            )
            Text(themeDescription)
                .font(.serifItalic(13))
                .foregroundColor(.ink.opacity(0.55))
                .multilineTextAlignment(.center)
        }
    }

    private var warmthSlider: some View {
        sliderCard(
            title: "Warmth",
            subtitle: "Cool ivory at 0, warm amber at 1.",
            value: $theme.warmth,
            minLabel: "❄  Cool",
            maxLabel: "🔥  Warm"
        )
    }

    private var darknessSlider: some View {
        sliderCard(
            title: "Depth",
            subtitle: "Light parchment at 0, candlelit at 1.",
            value: $theme.darkness,
            minLabel: "Light",
            maxLabel: "Deep"
        )
    }

    private var textureSlider: some View {
        sliderCard(
            title: "Paper Texture",
            subtitle: "Smooth printing at 0, full fibre grain at 1.",
            value: $theme.texture,
            minLabel: "Smooth",
            maxLabel: "Rough"
        )
    }

    private var resetButton: some View {
        Button {
            theme.resetToDefaults()
        } label: {
            Text("RESET TO DEFAULTS")
                .font(.serifHeadline(13))
                .tracking(3)
                .foregroundColor(.ink)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .overlay(Rectangle().stroke(Color.ink, lineWidth: 1))
        }
    }

    // MARK: - Building blocks

    private func sliderCard(
        title: String,
        subtitle: String,
        value: Binding<Double>,
        minLabel: String,
        maxLabel: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.scriptTitle(28))
                    .foregroundColor(.ink)
                Spacer()
                Text(String(format: "%.2f", value.wrappedValue))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.ink.opacity(0.55))
            }
            Text(subtitle)
                .font(.serifItalic(14))
                .foregroundColor(.ink.opacity(0.6))
            Slider(value: value, in: 0...1)
                .tint(.ink)
            HStack {
                Text(minLabel)
                    .font(.serifHeadline(12))
                    .tracking(1)
                    .foregroundColor(.ink.opacity(0.6))
                Spacer()
                Text(maxLabel)
                    .font(.serifHeadline(12))
                    .tracking(1)
                    .foregroundColor(.ink.opacity(0.6))
            }
        }
        .padding(20)
        .overlay(Rectangle().stroke(Color.ink.opacity(0.4), lineWidth: 1))
    }

    // MARK: - Live description

    private var themeDescription: String {
        let warmth = theme.warmth < 0.2 ? "cool ivory"
                       : theme.warmth > 0.8 ? "warm amber"
                       : "balanced"
        let depth = theme.darkness < 0.2 ? "luminous"
                      : theme.darkness > 0.8 ? "shadowed"
                      : "settled"
        let grain = theme.texture < 0.2 ? "smooth"
                      : theme.texture > 0.8 ? "rough fibre"
                      : "lightly textured"
        return "\(warmth) · \(depth) · \(grain)"
    }
}
