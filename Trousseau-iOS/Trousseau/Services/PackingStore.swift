//
//  PackingStore.swift
//  JSON-backed packing-list service. Separate from wardrobe + outfits so
//  each domain can be migrated/imported independently.
//

import Foundation
import SwiftUI

@MainActor
final class PackingStore: ObservableObject {
    @Published private(set) var lists: [PackingList] = []

    private var dbURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let root = docs.appendingPathComponent("Trousseau", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root.appendingPathComponent("packing.json")
    }

    init() { load() }

    /// Re-read `packing.json` from disk. Called by the restore flow.
    func reload() { load() }

    // MARK: - Persistence

    private func load() {
        let path = dbURL.path
        guard FileManager.default.fileExists(atPath: path) else {
            print("PackingStore.load: no file at \(path)")
            lists = []; return
        }
        do {
            let data = try Data(contentsOf: dbURL)
            print("PackingStore.load: read \(data.count) bytes")
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { d in
                let c = try d.singleValueContainer()
                let s = try c.decode(String.self)
                if let date = ISO8601DateFormatter().date(from: s)
                    ?? Self.fractional.date(from: s)
                    ?? Self.pythonish.date(from: s)
                    ?? Self.zoned.date(from: s) {
                    return date
                }
                throw DecodingError.dataCorruptedError(in: c,
                    debugDescription: "Unrecognised date format: \(s)")
            }
            let decoded = try decoder.decode([PackingList].self, from: data)
            print("PackingStore.load: decoded \(decoded.count) lists")
            lists = decoded.sorted { $0.createdAt > $1.createdAt }
        } catch {
            print("PackingStore.load FAILED: \(error)")
            lists = []
        }
    }

    private func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(lists)
            try data.write(to: dbURL, options: .atomic)
        } catch {
            print("PackingStore save failed: \(error)")
        }
    }

    // MARK: - Date formatters (mirror OutfitStore)

    nonisolated(unsafe) private static let fractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    nonisolated(unsafe) private static let zoned: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    nonisolated(unsafe) private static let pythonish: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    // MARK: - CRUD

    func append(_ p: PackingList) {
        lists.insert(p, at: 0)
        lists.sort { $0.createdAt > $1.createdAt }
        save()
    }

    func update(_ p: PackingList) {
        guard let idx = lists.firstIndex(where: { $0.id == p.id }) else { return }
        lists[idx] = p
        lists.sort { $0.createdAt > $1.createdAt }
        save()
    }

    func delete(id: String) {
        lists.removeAll { $0.id == id }
        save()
    }

    /// Toggle whether one item is packed inside one list.
    func togglePacked(listId: String, specimenId: String) {
        guard let li = lists.firstIndex(where: { $0.id == listId }) else { return }
        guard let ii = lists[li].items.firstIndex(where: { $0.specimenId == specimenId }) else { return }
        lists[li].items[ii].packed.toggle()
        save()
    }
}