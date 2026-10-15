//
//  JournalView.swift
//  OOTD diary — calendar strip at top, list of outfit entries below.
//  Reached via the "Journal" button in Collection's header.
//

import SwiftUI

struct JournalView: View {
    @EnvironmentObject var store: WardrobeStore
    @EnvironmentObject var outfits: OutfitStore
    @EnvironmentObject var theme: ThemeSettings
    @Environment(\.dismiss) private var dismiss

    @State private var displayedMonth: Date = Date()
    @State private var editing: OutfitEntryEditor.Sheet?

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackdrop()
                ScrollView {
                    VStack(spacing: 24) {
                        calendarHeader
                        monthGrid
                        entryList
                        Spacer(minLength: 60)
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
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        editing = OutfitEntryEditor.Sheet(date: OutfitEntry.todayISO(), existing: nil)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(.ink)
                    }
                    .accessibilityLabel(L10n.newJournalEntry)
                }
            }
            .sheet(item: $editing) { sheet in
                OutfitEntryEditor(
                    initialDate: sheet.date,
                    editing: sheet.existing
                )
                .environmentObject(store)
                .environmentObject(outfits)
            }
        }
    }

    // MARK: - Calendar header (month nav)

    private var calendarHeader: some View {
        VStack(spacing: 4) {
            Text(L10n.journalTitle)
                .font(.scriptTitle(40))
                .foregroundColor(.ink)
            HStack(spacing: 24) {
                Button {
                    shiftMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.ink)
                }
                Text(monthTitle(displayedMonth))
                    .font(.serifHeadline(18))
                    .tracking(2)
                    .foregroundColor(.ink)
                Button {
                    shiftMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.ink)
                }
            }
            .overlay(
                Rectangle().fill(Color.ink).frame(height: 1)
                    .overlay(Rectangle().fill(Color.ink).frame(height: 1).offset(y: 3)),
                alignment: .bottom
            )
        }
    }

    // MARK: - Month grid (Sun-Sat weeks)

    private var monthGrid: some View {
        let cal = Calendar.current
        let range = cal.range(of: .day, in: .month, for: displayedMonth) ?? 1..<1
        let firstWeekday = cal.component(.weekday, from: firstOfMonth()) - 1 // 0 = Sun
        let days: [Date?] = {
            var arr: [Date?] = Array(repeating: nil, count: firstWeekday)
            for d in range {
                if let day = cal.date(byAdding: .day, value: d - 1, to: firstOfMonth()) {
                    arr.append(day)
                }
            }
            while arr.count % 7 != 0 { arr.append(nil) }
            return arr
        }()

        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

        return VStack(spacing: 6) {
            HStack {
                ForEach(["S","M","T","W","T","F","S"], id: \.self) { d in
                    Text(d)
                        .font(.serifHeadline(10))
                        .tracking(1)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.ink.opacity(0.55))
                }
            }
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(days.indices, id: \.self) { i in
                    if let d = days[i] {
                        dayCell(d)
                    } else {
                        Color.clear.aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        .padding(12)
        .overlay(Rectangle().stroke(Color.ink.opacity(0.4), lineWidth: 1))
    }

    private func dayCell(_ d: Date) -> some View {
        let cal = Calendar.current
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        let iso = f.string(from: d)
        let count = outfits.entries(for: iso).count
        let isToday = cal.isDateInToday(d)
        return Button {
            editing = OutfitEntryEditor.Sheet(date: iso, existing: nil)
        } label: {
            VStack(spacing: 2) {
                Text("\(cal.component(.day, from: d))")
                    .font(.system(size: 13, design: .serif))
                    .foregroundColor(.ink)
                    .frame(maxWidth: .infinity, alignment: .top)
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.dangerInk)
                }
            }
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(isToday ? Color.ink : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Entry list (chronological)

    private var entryList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.recentEntries)
                    .font(.serifHeadline(18))
                    .foregroundColor(.ink)
                Spacer()
                Text(L10n.entriesTotal(outfits.entries.count))
                    .font(.serifHeadline(11))
                    .tracking(1)
                    .foregroundColor(.ink.opacity(0.5))
            }
            .overlay(
                Rectangle().fill(Color.ink).frame(height: 1)
                    .overlay(Rectangle().fill(Color.ink).frame(height: 1).offset(y: 3)),
                alignment: .bottom
            )

            if outfits.entries.isEmpty {
                VStack(spacing: 4) {
                    Spacer().frame(height: 24)
                    Text(L10n.journalEmpty)
                        .font(.serifItalic(17))
                        .foregroundColor(.ink.opacity(0.6))
                    Text(L10n.journalEmptyHint)
                        .font(.serifItalic(13))
                        .foregroundColor(.ink.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            } else {
                ForEach(outfits.entries) { entry in
                    entryRow(entry)
                }
            }
        }
    }

    @ViewBuilder
    private func entryRow(_ entry: OutfitEntry) -> some View {
        let itemCount = entry.specimenIds.count
        let thumbs = entry.specimenIds.prefix(4).compactMap { id -> (Specimen, UIImage)? in
            guard let s = store.specimen(id: id),
                  let img = UIImage(contentsOfFile: imageURL(for: s).path) else { return nil }
            return (s, img)
        }
        Button {
            editing = OutfitEntryEditor.Sheet(date: entry.date, existing: entry)
        } label: {
            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text(dayOf(entry.date))
                        .font(.scriptTitle(26))
                        .foregroundColor(.ink)
                    Text(monthAbbr(entry.date))
                        .font(.serifHeadline(10))
                        .tracking(1)
                        .foregroundColor(.ink.opacity(0.6))
                }
                .frame(width: 60)

                Rectangle()
                    .fill(Color.ink.opacity(0.5))
                    .frame(width: 1)

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.note.isEmpty ? L10n.untitledEntry : entry.note)
                        .font(.serifItalic(16))
                        .foregroundColor(.ink)
                        .lineLimit(1)
                    Text(L10n.specimensCount(itemCount))
                        .font(.serifHeadline(11))
                        .tracking(1)
                        .foregroundColor(.ink.opacity(0.55))
                    HStack(spacing: -8) {
                        ForEach(thumbs.indices, id: \.self) { i in
                            Image(uiImage: thumbs[i].1)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 26, height: 26)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.ink, lineWidth: 0.75))
                        }
                        if itemCount > 4 {
                            Text("+\(itemCount - 4)")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.ink.opacity(0.6))
                                .frame(width: 26, height: 26)
                                .background(Circle().fill(theme.baseColor))
                                .overlay(Circle().stroke(Color.ink, lineWidth: 0.75))
                        }
                    }
                    .padding(.top, 2)
                }
                Spacer()
            }
            .padding(10)
            .overlay(Rectangle().stroke(Color.ink.opacity(0.5), lineWidth: 0.75))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func firstOfMonth() -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: displayedMonth)
        return cal.date(from: comps) ?? displayedMonth
    }

    private func shiftMonth(by months: Int) {
        if let next = Calendar.current.date(byAdding: .month, value: months, to: displayedMonth) {
            displayedMonth = next
        }
    }

    private func monthTitle(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: d).uppercased()
    }

    private func dayOf(_ iso: String) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        if let d = f.date(from: iso) {
            let out = DateFormatter(); out.dateFormat = "d"
            return out.string(from: d)
        }
        return "?"
    }

    private func monthAbbr(_ iso: String) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        if let d = f.date(from: iso) {
            let out = DateFormatter(); out.dateFormat = "MMM"
            return out.string(from: d).uppercased()
        }
        return ""
    }

    private func imageURL(for s: Specimen) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("Trousseau").appendingPathComponent(s.image)
    }
}