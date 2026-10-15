//
//  BulkImportView.swift
//  Multi-select photo import — pick any number of photos, run background
//  removal on each, and archive them as separate specimens in one batch.
//

import SwiftUI
import PhotosUI
import UIKit

struct BulkImportView: View {
    @EnvironmentObject var store: WardrobeStore
    @Environment(\.dismiss) private var dismiss

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var processing: Bool = false
    @State private var processedCount: Int = 0
    @State private var totalCount: Int = 0
    @State private var errors: [String] = []
    @State private var currentError: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackdrop()
                if processing {
                    progressView
                } else {
                    form
                }
            }
            .navigationTitle("Bulk Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard & Return") { dismiss() }
                        .font(.serifItalic(15))
                        .foregroundColor(.ink)
                }
            }
            .alert("Error", isPresented: Binding(
                get: { currentError != nil },
                set: { if !$0 { currentError = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(currentError ?? "")
            }
        }
    }

    // MARK: - Form

    private var form: some View {
        VStack(spacing: 24) {
            Text("Bulk Import")
                .font(.scriptTitle(36))
                .foregroundColor(.ink)
                .padding(.top, 12)

            PhotosPicker(
                selection: $pickerItems,
                maxSelectionCount: 20,
                matching: .images
            ) {
                VStack(spacing: 8) {
                    Image(systemName: "rectangle.stack.badge.plus")
                        .font(.system(size: 36, weight: .thin))
                        .foregroundColor(.ink)
                    Text(pickerItems.isEmpty
                         ? L10n.bulkSelect
                         : L10n.bulkSelectedCount(pickerItems.count))
                        .font(.serifItalic(17))
                        .foregroundColor(.ink)
                    if !pickerItems.isEmpty {
                        Text(L10n.tapToChange)
                            .font(.serifItalic(12))
                            .foregroundColor(.ink.opacity(0.5))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 160)
                .background(
                    RoundedRectangle(cornerRadius: 0)
                        .strokeBorder(Color.ink, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                )
            }
            .onChange(of: pickerItems) { _, items in
                if !items.isEmpty {
                    Task { await processAll(items) }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("How bulk import works")
                    .font(.serifHeadline(12))
                    .tracking(1)
                    .foregroundColor(.ink.opacity(0.6))
                Text("Each photo is sent through the local tailor (background removal + colour extraction) and archived as its own specimen. Notes, tags, and prices can be filled in afterwards by tapping any item in the collection.")
                    .font(.serifItalic(14))
                    .foregroundColor(.ink.opacity(0.65))
                    .lineSpacing(4)
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)

            if !errors.isEmpty {
                Text("Some photos could not be processed:")
                    .font(.serifItalic(13))
                    .foregroundColor(.dangerInk)
                ForEach(errors, id: \.self) { e in
                    Text("• \(e)")
                        .font(.serifItalic(12))
                        .foregroundColor(.dangerInk.opacity(0.8))
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    // MARK: - Progress

    private var progressView: some View {
        VStack(spacing: 18) {
            Spacer()
            ProgressView(value: Double(processedCount),
                         total: Double(max(totalCount, 1)))
                .progressViewStyle(.linear)
                .tint(.ink)
                .frame(maxWidth: 240)
            Text(String.localizedStringWithFormat(
                NSLocalizedString("%lld of %lld tailored", comment: ""),
                processedCount, totalCount))
                .font(.serifHeadline(16))
                .tracking(2)
                .foregroundColor(.ink)
            Text(L10n.tailorBackRoom)
                .font(.scriptTitle(24))
                .foregroundColor(.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Processing

    private func processAll(_ items: [PhotosPickerItem]) async {
        processing = true
        processedCount = 0
        totalCount = items.count
        errors = []
        defer { processing = false }

        for item in items {
            do {
                try await processOne(item)
                processedCount += 1
            } catch {
                errors.append(error.localizedDescription)
                processedCount += 1  // count it as "skipped" so the bar moves
            }
        }

        // If everything succeeded, dismiss. Otherwise show the form again
        // with the error list so the user can retry the rest.
        if errors.isEmpty {
            dismiss()
        } else {
            pickerItems = []
        }
    }

    private func processOne(_ item: PhotosPickerItem) async throws {
        guard let data = try await item.loadTransferable(type: Data.self),
              let raw = UIImage(data: data) else {
            throw NSError(domain: "BulkImport", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Could not read photo bytes."])
        }

        let uuid = UUID().uuidString.lowercased()
        guard let rawRel = store.saveRaw(data, uuid: uuid) else {
            throw NSError(domain: "BulkImport", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Could not save original photo."])
        }

        let processed = try await BackgroundRemovalService.shared.process(input: raw)
        guard let procRel = store.saveProcessed(processed, uuid: uuid) else {
            throw NSError(domain: "BulkImport", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "Could not save processed photo."])
        }

        let palette = ColorPaletteService.palette(from: processed)
        // Bulk imports get a placeholder note. The user can edit later.
        let spec = Specimen.new(
            id: uuid,
            image: procRel,
            rawImage: rawRel,
            note: L10n.bulkImportNote,
            colors: palette,
            purchasePrice: nil
        )
        store.append(spec)
    }
}