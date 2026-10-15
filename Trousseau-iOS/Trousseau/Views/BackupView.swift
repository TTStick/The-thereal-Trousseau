//
//  BackupView.swift
//  Two-button sheet: Export the entire Trousseau to a single .json file
//  (shared via UIActivityViewController), or Import a previously-exported
//  backup via UIDocumentPickerViewController.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct BackupView: View {
    @EnvironmentObject var wardrobe: WardrobeStore
    @EnvironmentObject var outfits: OutfitStore
    @EnvironmentObject var packing: PackingStore
    @Environment(\.dismiss) private var dismiss

    @State private var status: String? = nil
    @State private var statusIsError: Bool = false
    @State private var presentingShare: ShareItem? = nil
    @State private var presentingPicker = false
    @State private var pendingImport: BackupBundle? = nil
    @State private var confirmingRestore = false

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackdrop()
                ScrollView {
                    VStack(spacing: 22) {
                        header
                        sectionCard(
                            title: "Export",
                            sub: "Bundle every specimen, journal entry, packing list, and photo into a single .json you can keep in Files, iCloud, or email to yourself.",
                            actionLabel: "Export Trousseau",
                            action: doExport
                        )
                        sectionCard(
                            title: "Import",
                            sub: "Pick a previously-exported .json to overwrite the current wardrobe. Existing files of the same name will be replaced.",
                            actionLabel: "Import Backup",
                            action: { presentingPicker = true }
                        )
                        if let s = status {
                            Text(s)
                                .font(.serifItalic(14))
                                .foregroundColor(statusIsError ? .dangerInk : .ink)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
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
            }
            .sheet(item: $presentingShare) { item in
                ShareSheet(items: [item.url])
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $presentingPicker) {
                DocumentPicker(types: [.json]) { url in
                    handlePickerResult(url)
                }
                .ignoresSafeArea()
            }
            .alert("Replace existing wardrobe?",
                   isPresented: $confirmingRestore,
                   actions: {
                Button("Replace", role: .destructive) {
                    if let b = pendingImport {
                        doRestore(bundle: b)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }, message: {
                Text("Importing will overwrite wardrobe_db.json, outfits.json, packing.json, and all photos. This cannot be undone.")
            })
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 4) {
            Text("Archives & Cipher")
                .font(.scriptTitle(40))
                .foregroundColor(.ink)
            Text("Keep your trousseau close, or carry it with you.")
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

    @ViewBuilder
    private func sectionCard(title: LocalizedStringKey,
                             sub: LocalizedStringKey,
                             actionLabel: LocalizedStringKey,
                             action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.serifHeadline(13))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(.ink)
            Text(sub)
                .font(.serifBody(15))
                .foregroundColor(.ink.opacity(0.75))
            Button(action: action) {
                HStack {
                    Spacer()
                    Text(actionLabel)
                        .font(.serifHeadline(14))
                        .tracking(2)
                        .foregroundColor(.parchment)
                    Spacer()
                }
                .padding(.vertical, 10)
                .background(Rectangle().fill(Color.ink))
                .overlay(Rectangle().stroke(Color.ink, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .overlay(Rectangle().stroke(Color.ink.opacity(0.5), lineWidth: 0.75))
    }

    // MARK: - Actions

    private func doExport() {
        do {
            let url = try BackupService.shared.writeExportToTemp()
            presentingShare = ShareItem(url: url)
            status = L10n.bundleReady
            statusIsError = false
        } catch {
            status = error.localizedDescription
            statusIsError = true
        }
    }

    private func handlePickerResult(_ url: URL?) {
        guard let url = url else { return }
        // The picker hands us an out-of-process URL — make it readable
        // before the app suspends (file is owned by the picker process).
        let secured = url.startAccessingSecurityScopedResource()
        defer { if secured { url.stopAccessingSecurityScopedResource() } }
        do {
            let bundle = try BackupService.shared.readBundle(from: url)
            pendingImport = bundle
            confirmingRestore = true
        } catch {
            status = error.localizedDescription
            statusIsError = true
        }
    }

    private func doRestore(bundle: BackupBundle) {
        do {
            try BackupService.shared.applyRestore(bundle)
            // Reload all three stores from disk.
            wardrobe.reload()
            outfits.reload()
            packing.reload()
            status = L10n.restoreOK
            statusIsError = false
        } catch {
            status = error.localizedDescription
            statusIsError = true
        }
    }
}

// MARK: - Helper UIKit bridges

private struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

private struct DocumentPicker: UIViewControllerRepresentable {
    let types: [UTType]
    let onPicked: (URL?) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let vc = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPicked: onPicked) }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPicked: (URL?) -> Void
        init(onPicked: @escaping (URL?) -> Void) { self.onPicked = onPicked }
        func documentPicker(_ controller: UIDocumentPickerViewController,
                            didPickDocumentsAt urls: [URL]) {
            onPicked(urls.first)
        }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onPicked(nil)
        }
    }
}