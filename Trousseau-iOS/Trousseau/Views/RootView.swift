//
//  RootView.swift
//  App shell — content area + custom bottom nav with the camera
//  centred between two pairs of tabs.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var theme: ThemeSettings
    @State private var tab: Tab = .collection
    @State private var showSettings = false
    @State private var detailPath: [String] = []

    /// Launch-arg hooks so headless screenshot runs can capture sheets / detail.
    init(autoShowSettings: Bool = false, autoShowDetail: String? = nil, initialTab: Tab? = nil, autoShowBackup: Bool = false) {
        _pendingAutoShow = State(initialValue: autoShowSettings)
        _pendingAutoDetailID = State(initialValue: autoShowDetail)
        _pendingAutoShowBackup = State(initialValue: autoShowBackup)
        if let t = initialTab {
            _tab = State(initialValue: t)
        } else if autoShowBackup {
            _tab = State(initialValue: .about)
        }
    }
    @State private var pendingAutoShow = false
    @State private var pendingAutoDetailID: String?
    @State private var pendingAutoShowBackup = false

    enum Tab: Hashable { case collection, collage, census, about }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Paper backdrop fills the entire window so any layout edge
            // matches the rest of the parchment theme.
            theme.baseColor
                .ignoresSafeArea()

            // Content area — reserves space for the bottom bar so
            // scrollable views (e.g. Census) don't get clipped.
            Group {
                switch tab {
                case .collection: GalleryView()
                case .collage:    CollageCanvasView()
                case .census:     CensusView()
                case .about:      ManifestoView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, BottomBarMetrics.barHeight)

            // Custom bottom nav — two tabs each side, camera in the middle.
            BottomBar(tab: $tab)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(theme)
        }
        .onAppear {
            if pendingAutoShow {
                pendingAutoShow = false
                showSettings = true
            }
            if let id = pendingAutoDetailID {
                // One-shot bus to GalleryView via UserDefaults; cleared on consume.
                UserDefaults.standard.set(id, forKey: "debug.autoDetailID")
                pendingAutoDetailID = nil
            }
            if pendingAutoShowBackup {
                // Stash a flag for ManifestoView to pick up on its first appear.
                UserDefaults.standard.set(true, forKey: "debug.showBackup")
                pendingAutoShowBackup = false
            }
        }
    }
}

// MARK: - Bottom nav

/// Visual metrics for the custom bottom bar. Kept in one place so the
/// content area's bottom padding stays in lock-step with the bar.
private enum BottomBarMetrics {
    /// Total height of the bar (including the camera "floating" area).
    static let barHeight: CGFloat = 64
    /// Vertical room reserved for the camera to "lift" above the bar.
    static let cameraLift: CGFloat = 18
    /// Diameter of the camera button circle.
    static let cameraSize: CGFloat = 56
}

/// The custom nav: 2 tabs on the left, camera button in the middle,
/// 2 tabs on the right. The whole thing sits on a thin paper-coloured
/// bar with a single hairline above it.
private struct BottomBar: View {
    @EnvironmentObject var theme: ThemeSettings
    @Binding var tab: RootView.Tab

    var body: some View {
        ZStack(alignment: .top) {
            // Bar background. Slightly taller than the tab row so the
            // camera's bottom half nests into it.
            theme.baseColor
                .frame(height: BottomBarMetrics.barHeight)

            // Tab row
            HStack(spacing: 0) {
                // Left pair: Collection, Collage
                BottomTabButton(icon: "photo.on.rectangle.angled",
                                label: "Collection",
                                isSelected: tab == .collection) { tab = .collection }
                BottomTabButton(icon: "rectangle.stack",
                                label: "Collage",
                                isSelected: tab == .collage)    { tab = .collage }

                // Centre spacer — reserves room for the floating camera.
                Spacer().frame(width: BottomBarMetrics.cameraSize + 12)

                // Right pair: Census, About
                BottomTabButton(icon: "books.vertical",
                                label: "Census",
                                isSelected: tab == .census)     { tab = .census }
                BottomTabButton(icon: "book.closed",
                                label: "About",
                                isSelected: tab == .about)      { tab = .about }
            }
            .frame(maxWidth: .infinity)

            // Hairline divider above the bar
            Rectangle()
                .fill(Color.ink)
                .frame(height: 1)
                .offset(y: -0.5)
        }
        .overlay(alignment: .top) {
            // Camera button — sits in the middle, lifted so it visually
            // straddles the bar's top edge.
            AddButton(tab: $tab)
                .frame(width: BottomBarMetrics.cameraSize,
                       height: BottomBarMetrics.cameraSize)
                .offset(y: -BottomBarMetrics.cameraLift)
        }
        .frame(maxWidth: .infinity, alignment: .bottom)
    }
}

/// A single tab in the custom bar: vertical icon + label, two states.
private struct BottomTabButton: View {
    @EnvironmentObject var theme: ThemeSettings
    let icon: String
    let label: LocalizedStringKey
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(isSelected ? .ink : .ink.opacity(0.55))
                Text(label)
                    .font(.serifHeadline(10))
                    .tracking(1)
                    .foregroundColor(isSelected ? .ink : .ink.opacity(0.55))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AddButton (camera)

/// The camera button that sits in the middle of the bottom bar.
/// Tapping opens the Add Specimen sheet and pulses the lens.
private struct AddButton: View {
    @EnvironmentObject var theme: ThemeSettings
    @Binding var tab: RootView.Tab
    @State private var showAdd = false
    @State private var irisScale: CGFloat = 1.0

    var body: some View {
        Button {
            showAdd = true
            // Iris pulses outward then settles — mimics a shutter release.
            withAnimation(.easeOut(duration: 0.12)) {
                irisScale = 1.35
            }
            withAnimation(.easeIn(duration: 0.32).delay(0.10)) {
                irisScale = 1.0
            }
        } label: {
            ZStack {
                Circle()
                    .stroke(Color.ink, lineWidth: 1)
                    .background(Circle().fill(theme.baseColor))
                VintageCameraGlyph()
                    .frame(width: 30, height: 22)
                    .environment(\.irisScale, irisScale)
            }
            .frame(width: BottomBarMetrics.cameraSize,
                   height: BottomBarMetrics.cameraSize)
        }
        .accessibilityLabel(L10n.archiveNewSpecimen)
        .sheet(isPresented: $showAdd) {
            AddSpecimenView()
        }
    }
}

// MARK: - Camera glyph

/// A small folding-plate camera drawn from primitives:
///   • a top "viewfinder bump" rectangle
///   • a wider rounded body
///   • a circle lens with a centred aperture dot
///   • a small flash bulb to the right
///
/// The lens scales with the `\.irisScale` environment value so the
/// parent can animate the shutter on tap.
private struct VintageCameraGlyph: View {
    @Environment(\.irisScale) private var irisScale: CGFloat

    var body: some View {
        VStack(spacing: 1.5) {
            // Top viewfinder bump
            RoundedRectangle(cornerRadius: 1)
                .stroke(Color.ink, lineWidth: 0.75)
                .frame(width: 11, height: 3.5)

            // Camera body
            ZStack {
                RoundedRectangle(cornerRadius: 2.5)
                    .stroke(Color.ink, lineWidth: 0.9)

                // Lens housing
                Circle()
                    .stroke(Color.ink, lineWidth: 0.9)
                    .frame(width: 14, height: 14)
                    .scaleEffect(irisScale)

                // Inner aperture dot
                Circle()
                    .fill(Color.ink)
                    .frame(width: 2.5, height: 2.5)

                // Flash bulb (top-right corner of the body)
                Circle()
                    .stroke(Color.ink, lineWidth: 0.6)
                    .frame(width: 2.5, height: 2.5)
                    .offset(x: 9, y: -5)
            }
            .frame(width: 28, height: 17)
        }
    }
}

// MARK: - Environment plumbing

/// Environment key the AddButton uses to drive the lens animation
/// without breaking the camera glyph's reusability elsewhere.
private struct IrisScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1.0
}

private extension EnvironmentValues {
    var irisScale: CGFloat {
        get { self[IrisScaleKey.self] }
        set { self[IrisScaleKey.self] = newValue }
    }
}