//
//  PackingListView.swift
//  Reached from the Collection header — a sheet that lists every packing
//  trip the wearer has drafted, with progress dots per list.
//

import SwiftUI

struct PackingListView: View {
    @EnvironmentObject var store: WardrobeStore
    @EnvironmentObject var packing: PackingStore
    @EnvironmentObject var theme: ThemeSettings
    @Environment(\.dismiss) private var dismiss

    @State private var editing: PackingListEditor.Sheet?

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackdrop()
                ScrollView {
                    VStack(spacing: 20) {
                        header
                        if packing.lists.isEmpty {
                            emptyState
                        } else {
                            listStack
                        }
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
                        editing = PackingListEditor.Sheet(existing: nil)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(.ink)
                    }
                    .accessibilityLabel("New packing list")
                }
            }
            .sheet(item: $editing) { sheet in
                PackingListEditor(existing: sheet.existing)
                    .environmentObject(store)
                    .environmentObject(packing)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 4) {
            Text(L10n.trunksTitle)
                .font(.scriptTitle(40))
                .foregroundColor(.ink)
            Text(L10n.tripsOnHorizon(packing.lists.count))
                .font(.serifItalic(15))
                .foregroundColor(.ink.opacity(0.6))
        }
        .padding(.bottom, 8)
        .overlay(
            Rectangle().fill(Color.ink).frame(height: 1)
                .overlay(Rectangle().fill(Color.ink).frame(height: 1).offset(y: 3)),
            alignment: .bottom
        )
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Spacer().frame(height: 28)
            Text(L10n.noTrunksYet)
                .font(.serifItalic(17))
                .foregroundColor(.ink.opacity(0.6))
            Text(L10n.draftFirstTrip)
                .font(.serifItalic(13))
                .foregroundColor(.ink.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var listStack: some View {
        VStack(spacing: 14) {
            ForEach(packing.lists) { list in
                Button {
                    editing = PackingListEditor.Sheet(existing: list)
                } label: {
                    listCard(list)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func listCard(_ list: PackingList) -> some View {
        let packed = list.items.filter(\.packed).count
        let total = list.items.count
        let progress = list.progress
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(list.title.isEmpty ? L10n.untitledTrip : list.title)
                    .font(.scriptTitle(26))
                    .foregroundColor(.ink)
                Spacer()
                Text("\(packed)/\(total)")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.ink.opacity(0.6))
            }
            if let dr = list.dateRangeString {
                Text(dr)
                    .font(.serifHeadline(11))
                    .tracking(1)
                    .foregroundColor(.ink.opacity(0.55))
            }
            // Progress bar — Victorian-styled double line.
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .stroke(Color.ink.opacity(0.4), lineWidth: 0.75)
                    Rectangle()
                        .fill(Color.ink)
                        .frame(width: max(0, geo.size.width * progress))
                }
            }
            .frame(height: 6)
            if total == 0 {
                Text(L10n.emptyKit)
                    .font(.serifItalic(12))
                    .foregroundColor(.ink.opacity(0.5))
            }
        }
        .padding(14)
        .overlay(Rectangle().stroke(Color.ink.opacity(0.5), lineWidth: 0.75))
    }
}