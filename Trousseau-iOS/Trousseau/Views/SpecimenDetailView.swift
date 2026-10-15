//
//  SpecimenDetailView.swift
//  /item/<id> — palette, tags, usage chronicle.
//

import SwiftUI

struct SpecimenDetailView: View {
    let specimenID: String

    @EnvironmentObject var store: WardrobeStore
    @EnvironmentObject var theme: ThemeSettings
    @Environment(\.dismiss) private var dismiss

    @State private var tagsInput: String = ""
    @State private var newLogDate: Date = Date()
    @State private var noteDraft: String = ""
    @State private var priceDraft: String = ""
    @State private var showDiscardConfirm = false

    var specimen: Specimen? { store.specimen(id: specimenID) }

    var body: some View {
        ZStack {
            PaperBackdrop()
            if let s = specimen {
                content(for: s)
            } else {
                missingState
            }
        }
        .navigationBarHidden(true)
        .overlay(alignment: .bottom) { bottomBar }
        .onAppear {
            if let s = specimen {
                tagsInput = s.tags.joined(separator: ", ")
                noteDraft = s.note
                if let p = s.purchasePrice {
                    priceDraft = p.truncatingRemainder(dividingBy: 1) == 0
                        ? String(format: "%.0f", p)
                        : String(p)
                } else {
                    priceDraft = ""
                }
            }
        }
        .alert("Discard this specimen?", isPresented: $showDiscardConfirm) {
            Button("Discard", role: .destructive) {
                store.delete(id: specimenID)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func content(for s: Specimen) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                photo(s)
                archiveCard(s)
                palette(s)
                section("Curator's Note") {
                    TextField("", text: $noteDraft, axis: .vertical)
                        .font(.serifItalic(18))
                        .lineLimit(1...5)
                        .padding(.vertical, 4)
                        .overlay(
                            Rectangle().fill(Color.ink).frame(height: 1).padding(.top, 36),
                            alignment: .top
                        )
                    HStack {
                        Spacer()
                        Button("Update Note") {
                            store.updateNote(id: s.id, note: noteDraft)
                        }
                        .font(.serifHeadline(13))
                        .tracking(2)
                        .foregroundColor(.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .overlay(Rectangle().stroke(Color.ink, lineWidth: 1))
                    }
                }

                section("Taxonomy Tags") {
                    tagsDisplay(s)
                    TextField("Edit tags (e.g. Silk, Summer, Vintage)", text: $tagsInput)
                        .font(.serifItalic(17))
                        .padding(.vertical, 4)
                        .overlay(
                            Rectangle().fill(Color.ink).frame(height: 1).padding(.top, 32),
                            alignment: .top
                        )
                    HStack {
                        Spacer()
                        Button("Update Taxonomy") {
                            let parsed = tagsInput.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                            store.updateTags(id: s.id, tags: parsed)
                        }
                        .font(.serifHeadline(13))
                        .tracking(2)
                        .foregroundColor(.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .overlay(Rectangle().stroke(Color.ink, lineWidth: 1))
                    }
                }

                section("Usage Chronicle") {
                    logTable(s)
                    // One-tap "today" log — the common case.
                    Button {
                        store.markWornToday(id: s.id)
                    } label: {
                        HStack {
                            Spacer()
                            Text("MARK TODAY AS WORN")
                                .font(.serifHeadline(13))
                                .tracking(2)
                                .foregroundColor(.parchment)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                            Spacer()
                        }
                        .background(Color.ink)
                    }
                    .padding(.top, 10)

                    // Custom date log for back-filling.
                    HStack {
                        DatePicker("", selection: $newLogDate, displayedComponents: .date)
                            .labelsHidden()
                            .accentColor(.ink)
                        Button("Log Custom Date") {
                            let fmt = DateFormatter()
                            fmt.dateFormat = "yyyy-MM-dd"
                            store.addLog(id: s.id, date: fmt.string(from: newLogDate))
                        }
                        .font(.serifHeadline(13))
                        .tracking(2)
                        .foregroundColor(.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .overlay(Rectangle().stroke(Color.ink, lineWidth: 1))
                    }
                    .padding(.top, 6)
                }

                section("Purchase Ledger") {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("¥")
                            .font(.serifHeadline(22))
                            .foregroundColor(.ink.opacity(0.7))
                        TextField("Original price (CNY)", text: $priceDraft)
                            .keyboardType(.decimalPad)
                            .font(.serifItalic(20))
                            .foregroundColor(.ink)
                        Text("CNY")
                            .font(.serifHeadline(12))
                            .tracking(2)
                            .foregroundColor(.ink.opacity(0.5))
                    }
                    .padding(.vertical, 6)
                    .overlay(
                        Rectangle().fill(Color.ink).frame(height: 1),
                        alignment: .bottom
                    )
                    HStack {
                        Spacer()
                        Button("Update Ledger") {
                            let trimmed = priceDraft.trimmingCharacters(in: .whitespaces)
                            let parsed = trimmed.isEmpty ? nil : Double(trimmed)
                            store.updatePurchasePrice(id: s.id, price: parsed)
                        }
                        .font(.serifHeadline(13))
                        .tracking(2)
                        .foregroundColor(.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .overlay(Rectangle().stroke(Color.ink, lineWidth: 1))
                    }
                    Text("Required for cost-per-wear calculations.")
                        .font(.serifItalic(12))
                        .foregroundColor(.ink.opacity(0.5))
                        .padding(.top, 4)
                }
            }
            .padding(20)
            .padding(.bottom, 80) // room for fixed bottom bar
        }
    }

    private var missingState: some View {
        VStack {
            Text("Specimen not found")
                .font(.serifItalic(22))
                .foregroundColor(.ink.opacity(0.6))
        }
    }

    private func photo(_ s: Specimen) -> some View {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Trousseau").appendingPathComponent(s.image)
        return Group {
            if let ui = UIImage(contentsOfFile: url.path) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFit()
                    .blendMode(.multiply)
            } else {
                theme.baseColor
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .overlay(
            Group {
                Rectangle().stroke(Color.ink, lineWidth: 1)
                Rectangle().stroke(Color.ink, lineWidth: 1).padding(2)
            }
        )
        .overlay(alignment: .topTrailing) {
            // Heart toggle — sits over the photo's upper-right corner.
            Button {
                store.toggleFavorite(id: s.id)
            } label: {
                Image(systemName: s.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(s.isFavorite ? .dangerInk : .ink)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(theme.baseColor.opacity(0.85))
                            .overlay(Circle().stroke(Color.ink, lineWidth: 1))
                    )
            }
            .padding(18)
            .accessibilityLabel(s.isFavorite ? "Remove from favorites" : "Add to favorites")
        }
        .overlay(alignment: .topLeading) {
            // Bookmark (wishlist) toggle — upper-left of the photo.
            Button {
                store.toggleWishlist(id: s.id)
            } label: {
                Image(systemName: s.wishlist ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(s.wishlist ? .ink : .ink.opacity(0.6))
                    .padding(10)
                    .background(
                        Circle()
                            .fill(theme.baseColor.opacity(0.85))
                            .overlay(Circle().stroke(Color.ink, lineWidth: 1))
                    )
            }
            .padding(18)
            .accessibilityLabel(s.wishlist ? "Remove from wishlist" : "Add to wishlist")
        }
    }

    /// Three-stat "档案卡": worn count, last worn, cost-per-wear.
    /// Rendered as a tight triple-cell ribbon so the eye reads it as one record.
    private func archiveCard(_ s: Specimen) -> some View {
        HStack(spacing: 0) {
            statCell(
                title: "WORN",
                value: "\(s.wornCount)",
                subtitle: "times"
            )
            divider
            statCell(
                title: "LAST",
                value: s.lastWornRelativeString(),
                subtitle: nil
            )
            divider
            statCell(
                title: "COST/WEAR",
                value: formatCPW(s.costPerWear),
                subtitle: s.purchasePrice == nil ? "no price" : "CNY"
            )
        }
        .padding(.vertical, 14)
        .overlay(
            Rectangle().stroke(Color.ink, lineWidth: 1)
        )
        .overlay(
            Rectangle().stroke(Color.ink, lineWidth: 1).padding(2)
        )
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.ink.opacity(0.5))
            .frame(width: 1)
            .padding(.vertical, 8)
    }

    private func statCell(title: String, value: String, subtitle: String?) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.serifHeadline(10))
                .tracking(2)
                .foregroundColor(.ink.opacity(0.55))
            Text(value)
                .font(.scriptTitle(24))
                .foregroundColor(.ink)
                .multilineTextAlignment(.center)
            if let s = subtitle {
                Text(s)
                    .font(.serifItalic(11))
                    .foregroundColor(.ink.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
    }

    /// ¥120 / ¥120.5 — never show "$0" for missing price.
    private func formatCPW(_ v: Double?) -> String {
        guard let v = v else { return "—" }
        return v.truncatingRemainder(dividingBy: 1) == 0
            ? "¥\(Int(v))"
            : String(format: "¥%.1f", v)
    }

    private func palette(_ s: Specimen) -> some View {
        HStack(spacing: 10) {
            ForEach(s.colors, id: \.self) { hex in
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 28, height: 28)
                    .overlay(Circle().stroke(Color.ink, lineWidth: 1))
            }
            Text("PIGMENT ANALYSIS")
                .font(.serifHeadline(13))
                .tracking(2)
                .foregroundColor(.ink.opacity(0.6))
                .padding(.leading, 6)
        }
        .padding(.bottom, 8)
        .overlay(
            Rectangle().fill(Color.ink).frame(height: 1),
            alignment: .bottom
        )
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.scriptTitle(34))
                .foregroundColor(.ink)
                .overlay(
                    Rectangle().fill(Color.ink).frame(height: 1),
                    alignment: .bottom
                )
            content()
        }
    }

    private func tagsDisplay(_ s: Specimen) -> some View {
        FlowLayout(spacing: 6) {
            ForEach(s.tags, id: \.self) { t in
                Text(t.uppercased())
                    .font(.serifHeadline(12))
                    .tracking(1)
                    .foregroundColor(.ink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.ink, lineWidth: 1))
            }
        }
    }

    private func logTable(_ s: Specimen) -> some View {
        VStack(spacing: 0) {
            ForEach(s.logs.sorted(by: >), id: \.self) { d in
                HStack {
                    Text(d)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.ink)
                    Spacer()
                    Text("Worn")
                        .font(.serifItalic(15))
                        .foregroundColor(.ink.opacity(0.8))
                    Button {
                        store.removeLog(id: s.id, date: d)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .light))
                            .foregroundColor(.ink.opacity(0.5))
                    }
                    .padding(.leading, 6)
                }
                .padding(.vertical, 6)
                .overlay(
                    Rectangle().fill(Color.fadedInk).frame(height: 1),
                    alignment: .bottom
                )
            }
        }
    }

    private var bottomBar: some View {
        HStack {
            Button { dismiss() } label: {
                Text("← Collection")
                    .font(.serifHeadline(14))
                    .tracking(2)
                    .foregroundColor(.ink)
            }
            Spacer()
            Button { showDiscardConfirm = true } label: {
                Text("Discard")
                    .font(.serifHeadline(14))
                    .tracking(2)
                    .foregroundColor(.dangerInk)
                    .overlay(
                        Rectangle().fill(Color.dangerInk.opacity(0.6)).frame(height: 1),
                        alignment: .bottom
                    )
            }
        }
        .padding(.horizontal, 24)
        .frame(height: 60)
        .background(
            theme.baseColor
                .overlay(
                    Rectangle()
                        .fill(Color.ink)
                        .frame(height: 1)
                        .overlay(Rectangle().fill(Color.ink).frame(height: 1).offset(y: 3)),
                    alignment: .top
                )
        )
    }
}

// MARK: - Flow layout for tag chips

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0, totalHeight: CGFloat = 0, rowHeight: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if rowWidth + s.width > maxWidth {
                totalHeight += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += s.width + spacing
            rowHeight = max(rowHeight, s.height)
        }
        return CGSize(width: maxWidth, height: totalHeight + rowHeight)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            rowHeight = max(rowHeight, s.height)
        }
    }
}

// MARK: - Hex → Color

extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let r = Double((v >> 16) & 0xff) / 255
        let g = Double((v >> 8) & 0xff) / 255
        let b = Double(v & 0xff) / 255
        self = Color(red: r, green: g, blue: b)
    }
}
