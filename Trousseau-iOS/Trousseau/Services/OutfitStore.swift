//
//  OutfitStore.swift
//  JSON-backed outfit journal, separate from the wardrobe DB so the
//  two domains can be migrated/imported independently.
//

import Foundation
import SwiftUI

@MainActor
final class OutfitStore: ObservableObject {
    @Published private(set) var entries: [OutfitEntry] = []

    private var dbURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let root = docs.appendingPathComponent("Trousseau", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root.appendingPathComponent("outfits.json")
    }

    init() { load() }

    /// Re-read `outfits.json` from disk. Called by the restore flow.
    func reload() { load() }

    // MARK: - Persistence

    private func load() {
        let path = dbURL.path
        guard FileManager.default.fileExists(atPath: path) else {
            print("OutfitStore.load: no file at \(path)")
            entries = []; return
        }
        do {
            let data = try Data(contentsOf: dbURL)
            print("OutfitStore.load: read \(data.count) bytes from \(path)")
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { d in
                let container = try d.singleValueContainer()
                let s = try container.decode(String.self)
                if let date = ISO8601DateFormatter().date(from: s)
                    ?? Self.fractional.date(from: s)
                    ?? Self.pythonish.date(from: s)
                    ?? Self.zoned.date(from: s) {
                    return date
                }
                throw DecodingError.dataCorruptedError(in: container,
                    debugDescription: "Unrecognised date format: \(s)")
            }
            let decoded = try decoder.decode([OutfitEntry].self, from: data)
            print("OutfitStore.load: decoded \(decoded.count) entries")
            entries = decoded.sorted { $0.date > $1.date }
        } catch {
            print("OutfitStore.load FAILED: \(error)")
            entries = []
        }
    }

    private func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(entries)
            try data.write(to: dbURL, options: .atomic)
        } catch {
            print("OutfitStore save failed: \(error)")
        }
    }

    // MARK: - Date format fallbacks

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

    /// Python `datetime.isoformat()` — microsecond precision, no timezone.
    nonisolated(unsafe) private static let pythonish: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    // MARK: - CRUD

    func append(_ e: OutfitEntry) {
        entries.insert(e, at: 0)
        entries.sort { $0.date > $1.date }
        save()
    }

    func update(_ e: OutfitEntry) {
        guard let idx = entries.firstIndex(where: { $0.id == e.id }) else { return }
        entries[idx] = e
        entries.sort { $0.date > $1.date }
        save()
    }

    func delete(id: String) {
        entries.removeAll { $0.id == id }
        save()
    }

    func entries(for date: String) -> [OutfitEntry] {
        entries.filter { $0.date == date }
    }
}