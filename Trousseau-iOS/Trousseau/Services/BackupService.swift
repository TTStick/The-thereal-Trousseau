//
//  BackupService.swift
//  Bundle every Trousseau file (wardrobe, outfits, packing, and the
//  clothes/uploads image folders) into a single shareable JSON archive,
//  or restore one back. Pure on-device — no cloud, no network.
//
//  Format: a top-level `BackupBundle` with the three JSON dbs and two
//  base64-encoded image folders. The on-disk shape mirrors the live one
//  so a future "extract to disk" restore can be a no-op.
//

import Foundation
import SwiftUI

// MARK: - On-disk shape (mirrors the live data folder)

struct BackupBundle: Codable {
    var version: Int = 1
    /// ISO timestamp the bundle was produced.
    var exportedAt: Date
    /// Image bytes keyed by relative path, e.g. "clothes/abc.jpg".
    var imageFiles: [String: String]   // base64
    /// Inline JSON of `wardrobe_db.json` (the canonical list).
    var wardrobeDB: WardrobeBackup
    /// Inline JSON of `outfits.json`.
    var outfits: OutfitsBackup
    /// Inline JSON of `packing.json`.
    var packing: PackingBackup

    struct WardrobeBackup: Codable { var specimens: [Specimen] }
    struct OutfitsBackup: Codable  { var entries:   [OutfitEntry] }
    struct PackingBackup: Codable  { var lists:     [PackingList] }
}

enum BackupError: LocalizedError {
    case writeFailed(Error)
    case readFailed(Error)
    case malformed(String)
    case ioFailed(String)

    var errorDescription: String? {
        switch self {
        case .writeFailed(let e):  return "Export failed: \(e.localizedDescription)"
        case .readFailed(let e):   return "Import failed: \(e.localizedDescription)"
        case .malformed(let m):    return "Malformed backup: \(m)"
        case .ioFailed(let m):     return "I/O failed: \(m)"
        }
    }
}

// MARK: - Service

@MainActor
final class BackupService {
    static let shared = BackupService()

    /// Root of the live Trousseau data folder in the app sandbox.
    private var dataRoot: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("Trousseau", isDirectory: true)
    }

    // MARK: - Export

    /// Build a `BackupBundle` from the current on-disk state.
    func buildBundle() throws -> BackupBundle {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let wardrobe: [Specimen] = try readJSON(named: "wardrobe_db.json", using: decoder) ?? []
        let outfits:  [OutfitEntry] = try readJSON(named: "outfits.json", using: decoder) ?? []
        let packing:  [PackingList] = try readJSON(named: "packing.json", using: decoder) ?? []

        let images = try snapshotImages()

        return BackupBundle(
            exportedAt: Date(),
            imageFiles: images,
            wardrobeDB: .init(specimens: wardrobe),
            outfits:    .init(entries:   outfits),
            packing:    .init(lists:     packing)
        )
    }

    /// Write the bundle to a temp `.trousseau.json` file and return the URL.
    /// Caller is responsible for presenting a `UIActivityViewController`.
    func writeExportToTemp() throws -> URL {
        let bundle = try buildBundle()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data: Data
        do {
            data = try encoder.encode(bundle)
        } catch {
            throw BackupError.writeFailed(error)
        }
        let stamp: String = {
            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd_HHmm"
            return f.string(from: Date())
        }()
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("trousseau-\(stamp).json")
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw BackupError.writeFailed(error)
        }
        return url
    }

    // MARK: - Import

    /// Read a `.json` backup file URL, validate, and return a `BackupBundle`.
    func readBundle(from url: URL) throws -> BackupBundle {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw BackupError.readFailed(error)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(BackupBundle.self, from: data)
        } catch {
            throw BackupError.malformed("\(error.localizedDescription)")
        }
    }

    /// Apply a bundle to disk: writes the three JSON dbs and re-materialises
    /// every image under `clothes/` and `uploads/`. Existing files of the
    /// same name are overwritten — restore is "replace" semantics, not merge.
    func applyRestore(_ bundle: BackupBundle) throws {
        // 1. Ensure the data root exists.
        let fm = FileManager.default
        try? fm.createDirectory(at: dataRoot, withIntermediateDirectories: true)
        let clothes = dataRoot.appendingPathComponent("clothes", isDirectory: true)
        let uploads = dataRoot.appendingPathComponent("uploads", isDirectory: true)
        try? fm.createDirectory(at: clothes, withIntermediateDirectories: true)
        try? fm.createDirectory(at: uploads, withIntermediateDirectories: true)

        // 2. Write the three JSON DBs.
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try writeJSON(bundle.wardrobeDB.specimens, to: "wardrobe_db.json", using: encoder)
        try writeJSON(bundle.outfits.entries,    to: "outfits.json",      using: encoder)
        try writeJSON(bundle.packing.lists,      to: "packing.json",      using: encoder)

        // 3. Re-materialise images.
        for (rel, b64) in bundle.imageFiles {
            guard let data = Data(base64Encoded: b64) else { continue }
            let dest = dataRoot.appendingPathComponent(rel)
            let parent = dest.deletingLastPathComponent()
            try? fm.createDirectory(at: parent, withIntermediateDirectories: true)
            do {
                try data.write(to: dest, options: .atomic)
            } catch {
                throw BackupError.ioFailed("could not write \(rel): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Internals

    private func readJSON<T: Decodable>(named: String, using decoder: JSONDecoder) throws -> T? {
        let url = dataRoot.appendingPathComponent(named)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try decoder.decode(T.self, from: data)
    }

    private func writeJSON<T: Encodable>(_ value: T, to name: String, using encoder: JSONEncoder) throws {
        let url = dataRoot.appendingPathComponent(name)
        let data = try encoder.encode(value)
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw BackupError.ioFailed("\(name): \(error.localizedDescription)")
        }
    }

    /// Walk `clothes/` and `uploads/` under dataRoot, base64-encoding every
    /// file. Returns a path → base64 map. Skips files that can't be read.
    private func snapshotImages() throws -> [String: String] {
        var out: [String: String] = [:]
        let fm = FileManager.default
        let subdirs = ["clothes", "uploads"]
        for sub in subdirs {
            let dir = dataRoot.appendingPathComponent(sub, isDirectory: true)
            guard let urls = try? fm.contentsOfDirectory(at: dir,
                                                          includingPropertiesForKeys: nil) else {
                continue
            }
            for u in urls {
                guard let data = try? Data(contentsOf: u) else { continue }
                let rel = "\(sub)/\(u.lastPathComponent)"
                out[rel] = data.base64EncodedString()
            }
        }
        return out
    }
}