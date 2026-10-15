//
//  TrousseauApp.swift
//  The Ethereal Trousseau
//
//  Local-first digital wardrobe. All processing on-device.
//  Vision framework for foreground segmentation. No external APIs.
//

import SwiftUI

@main
struct TrousseauApp: App {
    @StateObject private var store = WardrobeStore()
    @StateObject private var outfits = OutfitStore()
    @StateObject private var packing = PackingStore()
    @StateObject private var theme = ThemeSettings()

    /// Debug-only: pass `--show-settings` to auto-present the Paper Atelier
    /// sheet on launch so screenshots can capture it headlessly.
    private var autoShowSettings: Bool {
        CommandLine.arguments.contains("--show-settings")
    }

    /// Debug-only: `--show-detail <id>` deep-links into a specimen's detail.
    private var autoShowDetail: String? {
        guard let idx = CommandLine.arguments.firstIndex(of: "--show-detail"),
              idx + 1 < CommandLine.arguments.count else { return nil }
        return CommandLine.arguments[idx + 1]
    }

    /// Debug-only: `--tab <name>` jumps to the named tab on launch.
    /// Accepts: collection / collage / census / about
    private var autoTab: RootView.Tab? {
        guard let idx = CommandLine.arguments.firstIndex(of: "--tab"),
              idx + 1 < CommandLine.arguments.count else { return nil }
        switch CommandLine.arguments[idx + 1] {
        case "collage": return .collage
        case "census":  return .census
        case "about":   return .about
        case "collection": return .collection
        default: return nil
        }
    }

    /// Debug-only: `--show-backup` auto-presents the BackupView (also jumps to About tab).
    private var autoShowBackup: Bool {
        CommandLine.arguments.contains("--show-backup")
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                autoShowSettings: autoShowSettings,
                autoShowDetail: autoShowDetail,
                initialTab: autoTab,
                autoShowBackup: autoShowBackup
            )
            .environmentObject(store)
            .environmentObject(outfits)
            .environmentObject(packing)
            .environmentObject(theme)
            .preferredColorScheme(.light)
            .tint(.ink)
        }
    }
}
