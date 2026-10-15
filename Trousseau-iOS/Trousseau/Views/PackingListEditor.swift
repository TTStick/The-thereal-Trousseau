//
//  PackingListEditor.swift
//  Sheet for creating/editing a single packing list — pick a title,
//  travel dates, and the specimens to bring.
//

import SwiftUI

struct PackingListEditor: View {
    @EnvironmentObject var store: WardrobeStore
    @EnvironmentObject var packing: PackingStore
    @Environment(\.dismiss) private var dismiss

    /// Routing wrapper so `.sheet(item:)` can carry either create or edit.
    struct Sheet: Identifiable {
        let id = UUID()
        let existing: PackingList?
    }

    let existing: PackingList?

    @State private var title: String = ""
    @State private var startDate: Date = Date()
    @State private var hasStart: Bool = false
    @State private var endDate: Date = Date()
    @State private var hasEnd: Bool = false
    @State private var selected: Set<String> = []
    @State private var packed: Set<String> = []

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackdrop()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        titleField
                        datesBlock
                        specimenPickerHeader
                        specimenGrid
                        Spacer(minLength: 60)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(existing == nil ? "New Trunk" : "Edit Trunk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.serifHeadline(13))
                        .foregroundColor(.ink)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .font(.serifHeadline(13).weight(.semibold))
                        .foregroundColor(.ink)
                }
                if existing != nil {
                    ToolbarItem(placement: .bottomBar) {
                        Button(role: .destructive) {
                            if let id = existing?.id {
                                packing.delete(id: id)
                                dismiss()
                            }
                        } label: {
                            Text("Discard Trip")
                                .font(.serifItalic(13))
                                .foregroundColor(.dangerInk)
                        }
                    }
                }
            }
            .onAppear { hydrate() }
        }
    }

    // MARK: - Subviews

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Trip Title")
                .font(.serifHeadline(11))
                .tracking(1)
                .foregroundColor(.ink.opacity(0.55))
            TextField("e.g. Kyoto Autumn", text: $title)
                .font(.serifBody(18))
                .padding(.vertical, 8)
                .overlay(
                    Rectangle().fill(Color.ink).frame(height: 1),
                    alignment: .bottom
                )
        }
    }

    private var datesBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Dates")
                    .font(.serifHeadline(11))
                    .tracking(1)
                    .foregroundColor(.ink.opacity(0.55))
                Spacer()
                if hasStart || hasEnd {
                    Button("Clear") {
                        hasStart = false; hasEnd = false
                    }
                    .font(.serifItalic(11))
                    .foregroundColor(.dangerInk)
                }
            }
            HStack(spacing: 16) {
                toggleDate(label: "Start", on: $hasStart, date: $startDate)
                toggleDate(label: "End", on: $hasEnd, date: $endDate)
            }
        }
    }

    private func toggleDate(label: String, on: Binding<Bool>, date: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.serifHeadline(10))
                .tracking(1)
                .foregroundColor(.ink.opacity(0.55))
            if on.wrappedValue {
                DatePicker("", selection: date, displayedComponents: .date)
                    .labelsHidden()
                    .scaleEffect(0.9, anchor: .leading)
            } else {
                Button { on.wrappedValue = true } label: {
                    Text("set")
                        .font(.serifItalic(13))
                        .foregroundColor(.ink.opacity(0.55))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.ink.opacity(0.4), lineWidth: 0.75))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var specimenPickerHeader: some View {
        HStack {
            Text("Specimens")
                .font(.serifHeadline(11))
                .tracking(1)
                .foregroundColor(.ink.opacity(0.55))
            Spacer()
            Text("\(selected.count) selected")
                .font(.serifItalic(12))
                .foregroundColor(.ink.opacity(0.6))
        }
    }

    private var specimenGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(store.specimens) { spec in
                let on = selected.contains(spec.id)
                Button {
                    if on {
                        selected.remove(spec.id)
                        packed.remove(spec.id)
                    } else {
                        selected.insert(spec.id)
                    }
                } label: {
                    VStack(spacing: 4) {
                        thumbOrFallback(for: spec)
                            .frame(maxWidth: .infinity)
                            .frame(height: 96)
                            .overlay(
                                Rectangle()
                                    .stroke(on ? Color.ink : Color.ink.opacity(0.35),
                                            lineWidth: on ? 2 : 0.75)
                            )
                            .overlay(alignment: .topTrailing) {
                                if on {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.parchment)
                                        .padding(5)
                                        .background(Circle().fill(Color.ink))
                                        .padding(4)
                                }
                            }
                        Text(spec.tags.first ?? spec.id.prefix(4).lowercased())
                            .font(.serifHeadline(10))
                            .tracking(1)
                            .foregroundColor(.ink.opacity(0.6))
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func thumbOrFallback(for spec: Specimen) -> some View {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent("Trousseau").appendingPathComponent(spec.image)
        if let ui = UIImage(contentsOfFile: url.path) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
                .clipped()
                .blendMode(.multiply)
        } else {
            // Use the dominant pigment as a fallback swatch.
            ZStack {
                Color(spec.dominantColor)
                Text(spec.tags.first?.prefix(1).uppercased() ?? "?")
                    .font(.scriptTitle(40))
                    .foregroundColor(.parchment)
            }
        }
    }

    // MARK: - Helpers

    private func hydrate() {
        guard let e = existing else { return }
        title = e.title
        if let s = e.startDate {
            hasStart = true
            startDate = parseISO(s) ?? startDate
        }
        if let ed = e.endDate {
            hasEnd = true
            endDate = parseISO(ed) ?? endDate
        }
        selected = Set(e.items.map(\.specimenId))
        packed = Set(e.items.filter(\.packed).map(\.specimenId))
    }

    private func parseISO(_ s: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: s)
    }

    private func save() {
        let sStr = hasStart ? isoString(startDate) : nil
        let eStr = hasEnd   ? isoString(endDate)   : nil
        let items = selected
            .sorted()
            .map { PackingItem(specimenId: $0, packed: packed.contains($0)) }

        if let existing = existing {
            var updated = existing
            updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            updated.startDate = sStr
            updated.endDate = eStr
            updated.items = items
            packing.update(updated)
        } else {
            let p = PackingList(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                startDate: sStr,
                endDate: eStr,
                items: items
            )
            packing.append(p)
        }
        dismiss()
    }

    private func isoString(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }
}