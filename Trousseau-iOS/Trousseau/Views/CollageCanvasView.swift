//
//  CollageCanvasView.swift
//  /collage — drag-and-drop mood board.
//

import SwiftUI

struct CollageCanvasView: View {
    @EnvironmentObject var store: WardrobeStore
    @EnvironmentObject var outfits: OutfitStore
    @EnvironmentObject var theme: ThemeSettings
    @State private var placedItems: [PlacedItem] = []
    @State private var journalEntrySheet: OutfitEntryEditor.Sheet?

    var body: some View {
        ZStack {
            PaperBackdrop()
            VStack(spacing: 0) {
                canvas
                drawer
            }
        }
        .sheet(item: $journalEntrySheet) { sheet in
            OutfitEntryEditor(
                initialDate: sheet.date,
                editing: sheet.existing
            )
            .environmentObject(store)
            .environmentObject(outfits)
        }
    }

    // MARK: - Canvas

    private var canvas: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                theme.baseColor

                VStack(alignment: .leading, spacing: 4) {
                    Text("The Moodboard")
                        .font(.scriptTitle(34))
                        .foregroundColor(.ink.opacity(0.5))
                    Text("Tap items below to add. Drag to arrange. Long-press to remove.")
                        .font(.serifItalic(14))
                        .foregroundColor(.ink.opacity(0.7))
                }
                .padding(20)
                .allowsHitTesting(false)

                ForEach($placedItems) { $p in
                    DraggableItem(
                        item: $p,
                        onRemove: { remove(p) }
                    )
                }
            }
            .frame(height: geo.size.height * 0.65)
            .overlay(
                Rectangle().fill(Color.ink).frame(height: 1)
                    .overlay(Rectangle().fill(Color.ink).frame(height: 1).offset(y: 3)),
                alignment: .bottom
            )
        }
        .frame(height: UIScreen.main.bounds.height * 0.55)
    }

    // MARK: - Drawer

    private var drawer: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button {
                    placedItems.removeAll()
                } label: {
                    Text("Finish & Return")
                        .font(.serifHeadline(13))
                        .tracking(2)
                        .foregroundColor(.ink)
                }
                .padding(.leading, 16)
                .padding(.top, 8)
                Spacer()
                Button {
                    let ids = placedItems.map(\.specimen.id)
                    journalEntrySheet = OutfitEntryEditor.Sheet(
                        date: OutfitEntry.todayISO(),
                        existing: OutfitEntry(date: OutfitEntry.todayISO(),
                                               specimenIds: ids,
                                               note: "")
                    )
                } label: {
                    Text("Save as Journal Entry")
                        .font(.serifHeadline(13))
                        .tracking(2)
                        .foregroundColor(placedItems.isEmpty ? .ink.opacity(0.4) : .ink)
                }
                .disabled(placedItems.isEmpty)
                .padding(.trailing, 16)
                .padding(.top, 8)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(store.specimens) { spec in
                        Button { addToCanvas(spec) } label: {
                            drawerCell(for: spec)
                        }
                    }
                }
                .padding(12)
            }
            .frame(maxWidth: .infinity)
            .background(theme.baseColor.opacity(0.9))
        }
    }

    private func drawerCell(for spec: Specimen) -> some View {
        let url = absoluteURL(for: spec.image)
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
        .frame(width: 96, height: 96)
        .overlay(Rectangle().stroke(Color.ink, lineWidth: 1))
    }

    // MARK: - Mutations

    private func addToCanvas(_ spec: Specimen) {
        let url = absoluteURL(for: spec.image)
        let initialPos = CGPoint(
            x: CGFloat.random(in: 80...220),
            y: CGFloat.random(in: 80...240)
        )
        placedItems.append(PlacedItem(
            id: UUID(),
            specimen: spec,
            imageURL: url,
            position: initialPos
        ))
    }

    private func remove(_ p: PlacedItem) {
        placedItems.removeAll { $0.id == p.id }
    }

    private func absoluteURL(for rel: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Trousseau").appendingPathComponent(rel)
    }
}

// MARK: - Placed item model

struct PlacedItem: Identifiable, Equatable {
    let id: UUID
    let specimen: Specimen
    let imageURL: URL
    var position: CGPoint
}

// MARK: - Draggable item view

private struct DraggableItem: View {
    @Binding var item: PlacedItem
    var onRemove: () -> Void

    @EnvironmentObject var theme: ThemeSettings
    @State private var dragOffset: CGSize = .zero
    @State private var longPressActive = false

    var body: some View {
        let ui = UIImage(contentsOfFile: item.imageURL.path)
        Group {
            if let ui {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFit()
                    .blendMode(.multiply)
                    .shadow(color: .ink.opacity(0.15), radius: 1, x: 5, y: 5)
            } else {
                theme.baseColor
            }
        }
        .frame(width: 150)
        .position(
            x: item.position.x + dragOffset.width,
            y: item.position.y + dragOffset.height
        )
        .scaleEffect(longPressActive ? 1.05 : 1.0)
        .animation(.easeOut(duration: 0.1), value: longPressActive)
        .gesture(
            DragGesture()
                .onChanged { v in dragOffset = v.translation }
                .onEnded { v in
                    item.position = CGPoint(
                        x: item.position.x + v.translation.width,
                        y: item.position.y + v.translation.height
                    )
                    dragOffset = .zero
                }
        )
        .onLongPressGesture(minimumDuration: 0.6) {
            onRemove()
        } onPressingChanged: { pressing in
            longPressActive = pressing
        }
    }
}
