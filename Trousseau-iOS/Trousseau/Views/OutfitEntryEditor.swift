//
//  OutfitEntryEditor.swift
//  Sheet for creating or editing an OutfitEntry. Multi-select specimens,
//  pick a date, name the outfit.
//

import SwiftUI

struct OutfitEntryEditor: View {
    @EnvironmentObject var store: WardrobeStore
    @EnvironmentObject var outfits: OutfitStore
    @EnvironmentObject var theme: ThemeSettings
    @Environment(\.dismiss) private var dismiss

    let initialDate: String
    let editing: OutfitEntry?

    /// Sheet identifier passed via `JournalView.editing`.
    struct Sheet: Identifiable {
        let id = UUID()
        let date: String
        let existing: OutfitEntry?
    }

    @State private var dateString: String = OutfitEntry.todayISO()
    @State private var selectedIDs: Set<String> = []
    @State private var note: String = ""
    @State private var showDiscardConfirm: Bool = false

    init(initialDate: String, editing: OutfitEntry?) {
        self.initialDate = initialDate
        self.editing = editing
        _dateString = State(initialValue: editing?.date ?? initialDate)
        _selectedIDs = State(initialValue: Set(editing?.specimenIds ?? []))
        _note = State(initialValue: editing?.note ?? "")
    }

    private var dateValue: Date {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.date(from: dateString) ?? Date()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackdrop()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        datePicker
                        pickList
                        noteField
                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.serifHeadline(14))
                        .tracking(2)
                        .foregroundColor(.ink)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .font(.serifHeadline(14))
                        .tracking(2)
                        .foregroundColor(.ink)
                        .disabled(selectedIDs.isEmpty)
                        .opacity(selectedIDs.isEmpty ? 0.4 : 1)
                }
                if editing != nil {
                    ToolbarItem(placement: .bottomBar) {
                        Button("Discard Entry", role: .destructive) {
                            if let e = editing { outfits.delete(id: e.id) }
                            dismiss()
                        }
                        .font(.serifHeadline(13))
                        .foregroundColor(.dangerInk)
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 4) {
            Text(editing == nil ? "New Entry" : "Edit Entry")
                .font(.scriptTitle(32))
                .foregroundColor(.ink)
        }
        .frame(maxWidth: .infinity)
    }

    private var datePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Date")
            HStack {
                Text(dateString)
                    .font(.serifHeadline(18))
                    .foregroundColor(.ink)
                Spacer()
                DatePicker("", selection: Binding(
                    get: { dateValue },
                    set: { newVal in
                        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
                        dateString = f.string(from: newVal)
                    }
                ), displayedComponents: .date)
                .labelsHidden()
                .accentColor(.ink)
            }
            .padding(.vertical, 8)
            .overlay(
                Rectangle().fill(Color.ink).frame(height: 1),
                alignment: .bottom
            )
        }
    }

    private var pickList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionTitle("Specimens")
                Spacer()
                Text("\(selectedIDs.count) selected")
                    .font(.serifHeadline(11))
                    .tracking(1)
                    .foregroundColor(.ink.opacity(0.55))
            }
            if store.specimens.isEmpty {
                Text("No specimens archived yet — add some in Collection.")
                    .font(.serifItalic(14))
                    .foregroundColor(.ink.opacity(0.5))
            } else {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 8)
                ], spacing: 8) {
                    ForEach(store.specimens) { s in
                        pickCell(s)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func pickCell(_ s: Specimen) -> some View {
        let on = selectedIDs.contains(s.id)
        Button {
            if on { selectedIDs.remove(s.id) }
            else  { selectedIDs.insert(s.id) }
        } label: {
            VStack(spacing: 4) {
                Group {
                    if let ui = UIImage(contentsOfFile: pickURL(s).path) {
                        Image(uiImage: ui).resizable().scaledToFit().blendMode(.multiply)
                    } else {
                        theme.baseColor
                    }
                }
                .frame(height: 64)
                .padding(4)
                .overlay(
                    Rectangle().stroke(on ? Color.ink : Color.ink.opacity(0.4),
                                       lineWidth: on ? 2 : 1)
                )
                .background(
                    Rectangle().fill(on ? Color.ink.opacity(0.06) : .clear)
                )
            }
        }
        .buttonStyle(.plain)
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Theme")
            TextField("A name for this outfit (optional)", text: $note, axis: .vertical)
                .font(.serifItalic(17))
                .lineLimit(1...3)
                .padding(.vertical, 8)
                .overlay(
                    Rectangle().fill(Color.ink).frame(height: 1),
                    alignment: .bottom
                )
        }
    }

    private func sectionTitle(_ s: String) -> some View {
        Text(s)
            .font(.serifHeadline(13))
            .tracking(3)
            .foregroundColor(.ink.opacity(0.7))
            .overlay(
                Rectangle().fill(Color.ink).frame(height: 1)
                    .offset(y: 4),
                alignment: .bottom
            )
    }

    private func pickURL(_ s: Specimen) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("Trousseau").appendingPathComponent(s.image)
    }

    private func save() {
        let entry = OutfitEntry(
            id: editing?.id ?? UUID().uuidString.lowercased(),
            date: dateString,
            specimenIds: Array(selectedIDs),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: editing?.createdAt ?? Date()
        )
        if editing != nil {
            outfits.update(entry)
        } else {
            outfits.append(entry)
            // Also mark each selected specimen as worn today so cost-per-wear updates.
            for id in selectedIDs {
                store.markWornToday(id: id)
            }
        }
        dismiss()
    }
}