//
//  WardrobeStore.swift
//  JSON-backed wardrobe persistence, equivalent to wardrobe_db.json in the web version.
//

import Foundation
import SwiftUI
import UIKit

@MainActor
final class WardrobeStore: ObservableObject {
    @Published private(set) var specimens: [Specimen] = []

    // MARK: - Paths

    /// Documents/Trousseau/wardrobe_db.json
    private var dbURL: URL {
        let dir = documentsRoot()
        return dir.appendingPathComponent("wardrobe_db.json")
    }

    /// Documents/Trousseau/clothes/<uuid>.jpg   (processed)
    private var clothesDir: URL { documentsRoot().appendingPathComponent("clothes", isDirectory: true) }

    /// Documents/Trouchau/uploads/<uuid>_raw.jpg (originals)
    private var uploadsDir: URL { documentsRoot().appendingPathComponent("uploads", isDirectory: true) }

    private func documentsRoot() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let root = docs.appendingPathComponent("Trousseau", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    init() {
        try? FileManager.default.createDirectory(at: clothesDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: uploadsDir, withIntermediateDirectories: true)
        load()
    }

    /// Re-read `wardrobe_db.json` from disk and replace the in-memory list.
    /// Called by the restore flow after `BackupService` writes new JSON.
    func reload() { load() }

    // MARK: - Persistence

    private func load() {
        guard FileManager.default.fileExists(atPath: dbURL.path) else { specimens = []; return }
        do {
            let data = try Data(contentsOf: dbURL)
            // Web Flask version writes `createdAt` as ISO-8601 datetime strings.
            // Swift's default Date strategy is `timeIntervalSinceReferenceDate`,
            // which silently fails to decode — and on failure the catch block
            // wipes the wardrobe. Lock the strategy explicitly.
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode([Specimen].self, from: data)
            // Newest first, matching `reversed(clothes)` in the web version.
            specimens = decoded.sorted { $0.createdAt > $1.createdAt }
        } catch {
            print("WardrobeStore load failed: \(error)")
            specimens = []
        }
    }

    private func save() {
        do {
            // Match the load strategy: ISO-8601 datetimes on the wire so the
            // file is portable between the iOS app and the web Flask backend.
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(specimens)
            try data.write(to: dbURL, options: .atomic)
        } catch {
            print("WardrobeStore save failed: \(error)")
        }
    }

    // MARK: - File helpers

    /// Absolute URL for a stored image (clothes or uploads).
    func url(forRelativePath rel: String) -> URL {
        documentsRoot().appendingPathComponent(rel)
    }

    // MARK: - CRUD

    func append(_ s: Specimen) {
        specimens.insert(s, at: 0)
        save()
    }

    func update(_ s: Specimen) {
        guard let idx = specimens.firstIndex(where: { $0.id == s.id }) else { return }
        specimens[idx] = s
        save()
    }

    func delete(id: String) {
        guard let s = specimens.first(where: { $0.id == id }) else { return }
        // Best-effort file cleanup, mirroring web delete_item route.
        try? FileManager.default.removeItem(at: url(forRelativePath: s.image))
        try? FileManager.default.removeItem(at: url(forRelativePath: s.rawImage))
        specimens.removeAll { $0.id == id }
        save()
    }

    func specimen(id: String) -> Specimen? {
        specimens.first(where: { $0.id == id })
    }

    func addLog(id: String, date: String) {
        guard var s = specimen(id: id) else { return }
        if !s.logs.contains(date) {
            s.logs.append(date)
            s.logs.sort(by: Self.descDate)
        }
        update(s)
    }

    func removeLog(id: String, date: String) {
        guard var s = specimen(id: id) else { return }
        s.logs.removeAll { $0 == date }
        update(s)
    }

    func updateTags(id: String, tags: [String]) {
        guard var s = specimen(id: id) else { return }
        s.tags = tags
        update(s)
    }

    func updateNote(id: String, note: String) {
        guard var s = specimen(id: id) else { return }
        s.note = note
        update(s)
    }

    func updatePurchasePrice(id: String, price: Double?) {
        guard var s = specimen(id: id) else { return }
        s.purchasePrice = price
        update(s)
    }

    /// Convenience: log today as a worn date. No-op if today is already logged.
    func markWornToday(id: String) {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone.current
        addLog(id: id, date: f.string(from: Date()))
    }

    func toggleFavorite(id: String) {
        guard var s = specimen(id: id) else { return }
        s.isFavorite.toggle()
        update(s)
    }

    func setFavorite(id: String, _ flag: Bool) {
        guard var s = specimen(id: id), s.isFavorite != flag else { return }
        s.isFavorite = flag
        update(s)
    }

    func toggleWishlist(id: String) {
        guard var s = specimen(id: id) else { return }
        s.wishlist.toggle()
        update(s)
    }

    // MARK: - Save raw image, return relative path

    /// Writes the chosen photo to `uploads/<uuid>_raw.jpg`. Returns the
    /// relative path the caller should store in `Specimen.rawImage`.
    func saveRaw(_ data: Data, uuid: String) -> String? {
        let rel = "uploads/\(uuid)_raw.jpg"
        let url = self.url(forRelativePath: rel)
        do {
            try data.write(to: url, options: .atomic)
            return rel
        } catch {
            print("saveRaw failed: \(error)")
            return nil
        }
    }

    /// Writes the processed image to `clothes/<uuid>.jpg`. Returns the
    /// relative path to store in `Specimen.image`.
    func saveProcessed(_ image: UIImage, uuid: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.95) else { return nil }
        let rel = "clothes/\(uuid).jpg"
        let url = self.url(forRelativePath: rel)
        do {
            try data.write(to: url, options: .atomic)
            return rel
        } catch {
            print("saveProcessed failed: \(error)")
            return nil
        }
    }

    // MARK: - Date sorting helper

    /// Compares ISO yyyy-MM-dd strings in descending order (newest first).
    static func descDate(_ a: String, _ b: String) -> Bool {
        a > b
    }
}
