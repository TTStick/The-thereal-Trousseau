//
//  AddSpecimenView.swift
//  /add — pick photo, run local background removal, archive.
//

import SwiftUI
import PhotosUI
import UIKit

struct AddSpecimenView: View {
    @EnvironmentObject var store: WardrobeStore
    @EnvironmentObject var theme: ThemeSettings
    @Environment(\.dismiss) private var dismiss

    @State private var pickerItem: PhotosPickerItem?
    @State private var processing: Bool = false
    @State private var note: String = ""
    @State private var priceText: String = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackdrop()
                if processing {
                    loader
                } else {
                    form
                }
            }
            .navigationTitle("Archive New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard & Return") { dismiss() }
                        .font(.serifItalic(15))
                        .foregroundColor(.ink)
                }
            }
            .alert("Error", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(error ?? "")
            }
        }
    }

    private var form: some View {
        VStack(spacing: 24) {
            Text("Archive New Item")
                .font(.scriptTitle(36))
                .foregroundColor(.ink)
                .padding(.top, 12)

            PhotosPicker(selection: $pickerItem, matching: .images) {
                VStack(spacing: 8) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 36, weight: .thin))
                        .foregroundColor(.ink)
                    Text(pickerItem == nil ? "Click to Select Photograph" : "Selected")
                        .font(.serifItalic(17))
                        .foregroundColor(.ink)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .background(
                    RoundedRectangle(cornerRadius: 0)
                        .strokeBorder(Color.ink, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                )
            }

            TextEditor(text: $note)
                .font(.serifItalic(18))
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .frame(height: 120)
                .overlay(alignment: .topLeading) {
                    if note.isEmpty {
                        Text("Enter Curator's Remarks...")
                            .font(.serifItalic(18))
                            .foregroundColor(.ink.opacity(0.45))
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                }
                .overlay(
                    Rectangle()
                        .fill(Color.ink)
                        .frame(height: 1)
                        .padding(.top, 36),
                    alignment: .top
                )
                .overlay(
                    Rectangle()
                        .fill(Color.ink)
                        .frame(height: 1)
                        .padding(.top, 76),
                    alignment: .top
                )

            // Optional purchase price — kept in CNY. Empty string → nil.
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("¥")
                    .font(.serifHeadline(22))
                    .foregroundColor(.ink.opacity(0.7))
                TextField("Original price (optional)", text: $priceText)
                    .keyboardType(.decimalPad)
                    .font(.serifItalic(20))
                    .foregroundColor(.ink)
                Text("CNY")
                    .font(.serifHeadline(12))
                    .tracking(2)
                    .foregroundColor(.ink.opacity(0.5))
            }
            .padding(.vertical, 10)
            .overlay(
                Rectangle().fill(Color.ink).frame(height: 1),
                alignment: .bottom
            )

            Button {
                Task { await process() }
            } label: {
                Text("PERMANENT ARCHIVE")
                    .font(.serifHeadline(16))
                    .tracking(3)
                    .foregroundColor(.parchment)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.ink)
            }
            .disabled(pickerItem == nil)
            .opacity(pickerItem == nil ? 0.4 : 1)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .onChange(of: pickerItem) { _, _ in /* triggers via button */ }
    }

    private var loader: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.6)
                .tint(.ink)
            Text("The Tailor is cutting the pattern...")
                .font(.scriptTitle(28))
                .foregroundColor(.ink)
                .transition(.opacity)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func process() async {
        guard let item = pickerItem else { return }
        processing = true
        defer { processing = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let raw = UIImage(data: data) else {
                error = "Failed to load the selected photo."
                return
            }

            let uuid = UUID().uuidString.lowercased()
            guard let rawRel = store.saveRaw(data, uuid: uuid) else {
                error = "Failed to save the original photo."
                return
            }

            // Local background removal.
            let processed = try await BackgroundRemovalService.shared.process(input: raw)
            guard let procRel = store.saveProcessed(processed, uuid: uuid) else {
                error = "Failed to save the processed image."
                return
            }

            // Colour palette from processed image.
            let palette = ColorPaletteService.palette(from: processed)

            let parsedPrice = Double(priceText.trimmingCharacters(in: .whitespaces))
            let spec = Specimen.new(
                id: uuid,
                image: procRel,
                rawImage: rawRel,
                note: note,
                colors: palette,
                purchasePrice: parsedPrice
            )
            store.append(spec)
            dismiss()
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
