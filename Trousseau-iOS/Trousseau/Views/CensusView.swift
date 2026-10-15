//
//  CensusView.swift
//  /stats — total count, top tags, Oracle.
//

import SwiftUI

struct CensusView: View {
    @EnvironmentObject var store: WardrobeStore
    @State private var oracleTarget: Specimen?
    @State private var pigmentSheet: PigmentSheet?

    /// Wraps the tapped hex + its computed match list so the sheet is
    /// snapshot-proof (no recomputation on dismissal).
    struct PigmentSheet: Identifiable {
        let id = UUID()
        let hex: String
        let specimens: [Specimen]
    }

    var body: some View {
        ZStack {
            // PaperBackdrop inside the NavigationStack, on top of systemMaterial.
            NavigationStack {
                ZStack {
                    PaperBackdrop()
                    ScrollView {
                        VStack(spacing: 32) {
                            totalBlock
                            pigmentsBlock
                            tagsBlock
                            oracleBlock
                            Spacer(minLength: 60)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                    }
                }
                .navigationDestination(item: $oracleTarget) { spec in
                    SpecimenDetailView(specimenID: spec.id)
                }
            }
        }
        .sheet(item: $pigmentSheet) { sheet in
            SpecimensByColorView(tappedHex: sheet.hex, specimens: sheet.specimens)
        }
        .onAppear {
            // Headless screenshot helper: present a pigment sheet on first appear.
            if let hex = UserDefaults.standard.string(forKey: "debug.pigmentHex") {
                UserDefaults.standard.removeObject(forKey: "debug.pigmentHex")
                let matches = Pigment.matching(targetHex: hex, in: store.specimens)
                pigmentSheet = PigmentSheet(hex: hex, specimens: matches)
            }
        }
    }

    private var totalBlock: some View {
        VStack(spacing: 4) {
            Text("The Census")
                .font(.scriptTitle(48))
                .foregroundColor(.ink)
            Text("TOTAL SPECIMENS ARCHIVED")
                .font(.serifHeadline(13))
                .tracking(3)
                .foregroundColor(.ink.opacity(0.8))
            Text(romanNumber(store.specimens.count))
                .font(.system(size: 96, weight: .regular, design: .serif))
                .foregroundColor(.ink)
                .padding(.vertical, 8)
                .overlay(
                    Rectangle().fill(Color.ink).frame(height: 1)
                        .overlay(Rectangle().fill(Color.ink).frame(height: 1).offset(y: 3)),
                    alignment: .bottom
                )
        }
    }

    private var tagsBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dominant Categories")
                .font(.serifHeadline(18))
                .foregroundColor(.ink)
            if topTags.isEmpty {
                Text("No tags yet.")
                    .font(.serifItalic(15))
                    .foregroundColor(.ink.opacity(0.5))
            } else {
                VStack(spacing: 4) {
                    ForEach(topTags, id: \.0) { tag, count in
                        HStack {
                            Text(tag)
                                .font(.serifBody(16))
                            Spacer()
                            Text("\(count)")
                                .font(.serifHeadline(15))
                        }
                        .padding(.vertical, 6)
                        .overlay(
                            Rectangle().fill(Color.fadedInk).frame(height: 1),
                            alignment: .bottom
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var oracleBlock: some View {
        VStack(spacing: 12) {
            Rectangle().stroke(Color.ink, lineWidth: 1).frame(height: 280)
                .overlay(
                    VStack(spacing: 12) {
                        Spacer()
                        Text("The Oracle")
                            .font(.scriptTitle(36))
                            .foregroundColor(.ink)
                        Text("Unsure of today's attire? Let the spirits decide.")
                            .font(.serifItalic(15))
                            .foregroundColor(.ink.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        Button(action: consult) {
                            Text("CONSULT THE ORACLE")
                                .font(.serifHeadline(15))
                                .tracking(2)
                                .foregroundColor(.parchment)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 14)
                                .background(Color.ink)
                        }
                        .disabled(store.specimens.isEmpty)
                        .opacity(store.specimens.isEmpty ? 0.4 : 1)
                        Spacer()
                    }
                )
        }
    }

    // MARK: - Oracle

    private func consult() {
        guard let pick = store.specimens.randomElement() else { return }
        oracleTarget = pick
    }

    // MARK: - Pigments

    private var pigmentsBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Dominant Pigments")
                    .font(.serifHeadline(18))
                    .foregroundColor(.ink)
                Spacer()
                Text("TAP A SWATCH")
                    .font(.serifHeadline(10))
                    .tracking(2)
                    .foregroundColor(.ink.opacity(0.5))
            }
            if dominant.isEmpty {
                Text("Archive specimens to populate the palette.")
                    .font(.serifItalic(14))
                    .foregroundColor(.ink.opacity(0.5))
            } else {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 60), spacing: 12)
                ], spacing: 12) {
                    ForEach(dominant, id: \.0) { hex, count in
                        Button {
                            let matches = Pigment.matching(targetHex: hex, in: store.specimens)
                            pigmentSheet = PigmentSheet(hex: hex, specimens: matches)
                        } label: {
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 44, height: 44)
                                    .overlay(Circle().stroke(Color.ink, lineWidth: 1))
                                    .overlay(Circle().stroke(Color.ink, lineWidth: 1).padding(2))
                                Text("\(count)")
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(.ink.opacity(0.6))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .overlay(Rectangle().stroke(Color.ink.opacity(0.5), lineWidth: 1))
    }

    private var dominant: [(String, Int)] { Pigment.dominant(in: store.specimens) }

    // MARK: - Tag aggregation

    private var topTags: [(String, Int)] {
        var counter: [String: Int] = [:]
        for s in store.specimens {
            for t in s.tags { counter[t, default: 0] += 1 }
        }
        return counter.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
    }

    private func romanNumber(_ n: Int) -> String {
        // Tiny roman conversion up to 3999.
        let numerals: [(Int, String)] = [
            (1000, "M"), (900, "CM"), (500, "D"), (400, "CD"),
            (100, "C"), (90, "XC"), (50, "L"), (40, "XL"),
            (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")
        ]
        var n = n, result = ""
        for (v, s) in numerals where n >= v {
            let reps = n / v
            result += String(repeating: s, count: reps)
            n -= v * reps
        }
        return result.isEmpty ? "0" : result
    }
}
