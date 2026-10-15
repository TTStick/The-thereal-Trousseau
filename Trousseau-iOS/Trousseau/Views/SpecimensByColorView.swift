//
//  SpecimensByColorView.swift
//  Shown when the user taps a pigment swatch in CensusView.
//  Lists all specimens whose palette contains a near-match of the tapped hex.
//

import SwiftUI

struct SpecimensByColorView: View {
    let tappedHex: String
    let specimens: [Specimen]

    @EnvironmentObject var theme: ThemeSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackdrop()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        if specimens.isEmpty {
                            emptyState
                        } else {
                            grid
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("")
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
    }

    private var header: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color(hex: tappedHex))
                .frame(width: 60, height: 60)
                .overlay(Circle().stroke(Color.ink, lineWidth: 1))
                .overlay(
                    Circle().stroke(Color.ink, lineWidth: 1).padding(3)
                )
            VStack(alignment: .leading, spacing: 4) {
                Text("Pigment Match")
                    .font(.scriptTitle(32))
                    .foregroundColor(.ink)
                Text("\(specimens.count) specimen\(specimens.count == 1 ? "" : "s") near \(tappedHex.uppercased())")
                    .font(.serifItalic(14))
                    .foregroundColor(.ink.opacity(0.7))
            }
            Spacer()
        }
        .padding(.bottom, 4)
        .overlay(
            Rectangle().fill(Color.ink).frame(height: 1)
                .overlay(Rectangle().fill(Color.ink).frame(height: 1).offset(y: 3)),
            alignment: .bottom
        )
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer().frame(height: 60)
            Text("No specimens match this pigment.")
                .font(.serifItalic(18))
                .foregroundColor(.ink.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var grid: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 150, maximum: 180), spacing: 16)
        ], spacing: 16) {
            ForEach(Array(specimens.enumerated()), id: \.element.id) { idx, spec in
                VStack(spacing: 6) {
                    Group {
                        if let ui = UIImage(contentsOfFile: storeURL(for: spec).path) {
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFit()
                                .blendMode(.multiply)
                                .saturation(0.92)
                                .contrast(1.04)
                        } else {
                            theme.baseColor
                        }
                    }
                    .padding(8)
                    .overlay(Rectangle().stroke(Color.ink, lineWidth: 1))
                    Text("No. \(specimens.count - idx)")
                        .font(.scriptTitle(20))
                        .foregroundColor(.ink)
                        .padding(.top, 6)
                        .overlay(
                            Rectangle().fill(Color.fadedInk).frame(height: 1)
                                .offset(y: -4),
                            alignment: .top
                        )
                }
            }
        }
    }

    private func storeURL(for spec: Specimen) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("Trousseau").appendingPathComponent(spec.image)
    }
}