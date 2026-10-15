//
//  GalleryView.swift
//  Index "/" — search + grid of specimen cards.
//

import SwiftUI

struct GalleryView: View {
    @EnvironmentObject var store: WardrobeStore
    @EnvironmentObject var outfits: OutfitStore
    @EnvironmentObject var packing: PackingStore
    @EnvironmentObject var theme: ThemeSettings
    @State private var search: String = ""
    @State private var presented: Specimen?
    @State private var filter: GalleryFilter = .all
    @State private var selectedTags: Set<String> = []
    @State private var showJournal = false
    @State private var showPacking = false
    @State private var showBulkImport = false

    enum GalleryFilter: String, CaseIterable {
        case all = "All"
        case favorites = "Favorites"
        case wishlist = "Wishlist"

        /// Localised chip label. The rawValue still serves as a stable
        /// Swift identifier; the user-visible text is looked up here.
        var displayName: LocalizedStringKey {
            switch self {
            case .all:       return "All"
            case .favorites: return "Favorites"
            case .wishlist:  return "Wishlist"
            }
        }
    }

    /// Distinct tags across the entire wardrobe (regardless of current filter),
    /// alphabetised. Drives the tag chip row below All/Favorites.
    var allTags: [String] {
        Array(Set(store.specimens.flatMap(\.tags))).sorted()
    }

    var filtered: [Specimen] {
        var pool = store.specimens
        // Apply the chip filter first, then the text search.
        switch filter {
        case .favorites:
            pool = pool.filter { $0.isFavorite }
        case .wishlist:
            pool = pool.filter { $0.wishlist }
        case .all:
            break
        }
        if !selectedTags.isEmpty {
            pool = pool.filter { !$0.tags.filter { selectedTags.contains($0) }.isEmpty }
        }
        guard !search.isEmpty else { return pool }
        let q = search.lowercased()
        return pool.filter {
            $0.note.lowercased().contains(q) ||
            $0.tags.joined(separator: " ").lowercased().contains(q)
        }
    }

    var body: some View {
        ZStack {
            // NavigationStack on iOS 17 draws its own opaque systemMaterial
            // background, which would cover any view placed before it in a
            // ZStack. The PaperBackdrop has to live *inside* the stack so it
            // sits on top of that material layer.
            NavigationStack {
                ZStack {
                    PaperBackdrop()
                    VStack(spacing: 0) {
                        header
                        if filtered.isEmpty {
                            emptyState
                        } else {
                            grid
                        }
                    }
                }
                .navigationBarHidden(true)
                .navigationDestination(item: $presented) { spec in
                    SpecimenDetailView(specimenID: spec.id)
                }
                .onAppear {
                    // Headless deep-link: consume the debug key set by RootView.
                    if let id = UserDefaults.standard.string(forKey: "debug.autoDetailID"),
                       let spec = store.specimen(id: id) {
                        UserDefaults.standard.removeObject(forKey: "debug.autoDetailID")
                        presented = spec
                    }
                    if UserDefaults.standard.bool(forKey: "debug.showJournal") {
                        UserDefaults.standard.removeObject(forKey: "debug.showJournal")
                        showJournal = true
                    }
                    if UserDefaults.standard.bool(forKey: "debug.showPacking") {
                        UserDefaults.standard.removeObject(forKey: "debug.showPacking")
                        showPacking = true
                    }
                    if UserDefaults.standard.bool(forKey: "debug.showBulk") {
                        UserDefaults.standard.removeObject(forKey: "debug.showBulk")
                        showBulkImport = true
                    }
                }
                .sheet(isPresented: $showJournal) {
                    JournalView()
                        .environmentObject(store)
                        .environmentObject(outfits)
                }
                .sheet(isPresented: $showPacking) {
                    PackingListView()
                        .environmentObject(store)
                        .environmentObject(packing)
                }
                .sheet(isPresented: $showBulkImport) {
                    BulkImportView()
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            HStack(alignment: .center) {
                Spacer()
                // The brand mark — intentionally NOT localised. Pinyon Script
                // is a Latin-only display face; rendering Chinese glyphs in
                // it would fall back to a system font and clash with the
                // hand-lettered aesthetic. Keep it English in every locale.
                //
                // `lineLimit(1)` + `minimumScaleFactor` keeps the title on
                // one line — Pinyon Script is wide and the 22-character
                // brand wouldn't fit on a single row at the default 48pt.
                Text(verbatim: "The Ethereal Trousseau")
                    .font(.scriptTitle(40))
                    .foregroundColor(.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .truncationMode(.tail)
                    .padding(.top, 8)
                Spacer()
            }
            WeatherBanner()
                .padding(.horizontal, 24)
                .padding(.bottom, 4)
            HStack(spacing: 0) {
                TextField("Search Archives...", text: $search)
                    .font(.serifBody(17))
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .padding(.vertical, 6)
                    .overlay(
                        Rectangle()
                            .fill(Color.ink)
                            .frame(height: 1)
                            .padding(.top, 36),
                        alignment: .bottom
                    )
                Button {
                    showBulkImport = true
                } label: {
                    Image(systemName: "rectangle.stack.badge.plus")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(.ink)
                        .padding(8)
                        .overlay(Circle().stroke(Color.ink, lineWidth: 1))
                }
                .accessibilityLabel("Bulk import photos")
                .padding(.trailing, 4)
                Button {
                    showPacking = true
                } label: {
                    Image(systemName: "suitcase")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(.ink)
                        .padding(8)
                        .overlay(Circle().stroke(Color.ink, lineWidth: 1))
                }
                .accessibilityLabel("Open packing lists")
                .padding(.trailing, 4)
                Button {
                    showJournal = true
                } label: {
                    Image(systemName: "book.closed")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(.ink)
                        .padding(8)
                        .overlay(Circle().stroke(Color.ink, lineWidth: 1))
                }
                .accessibilityLabel("Open journal")
                .padding(.trailing, 16)
            }
            .padding(.bottom, 8)

            // Filter chips — small Victorian-style filter row.
            HStack(spacing: 10) {
                ForEach(GalleryFilter.allCases, id: \.self) { f in
                    Button {
                        filter = f
                    } label: {
                        Text(f.displayName)
                            .font(.serifHeadline(11))
                            .tracking(2)
                            .foregroundColor(filter == f ? .parchment : .ink)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(
                                Rectangle()
                                    .fill(filter == f ? Color.ink : Color.clear)
                                    .overlay(Rectangle().stroke(Color.ink, lineWidth: 1))
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)

            // Tag chip row — only visible when at least one tag exists.
            if !allTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(allTags, id: \.self) { tag in
                            let on = selectedTags.contains(tag)
                            Button {
                                if on { selectedTags.remove(tag) }
                                else  { selectedTags.insert(tag) }
                            } label: {
                                Text("#\(tag.uppercased())")
                                    .font(.serifHeadline(10))
                                    .tracking(1)
                                    .foregroundColor(on ? .parchment : .ink)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        Rectangle()
                                            .fill(on ? Color.ink : Color.clear)
                                            .overlay(Rectangle().stroke(Color.ink, lineWidth: 0.75))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 10)
            }

            Rectangle()
                .fill(Color.ink)
                .frame(height: 1)
                .overlay(
                    Rectangle()
                        .fill(Color.ink)
                        .frame(height: 1)
                        .offset(y: 3)
                )
        }
        .padding(.bottom, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Text("Collection Empty")
                .font(.serifItalic(20))
                .foregroundColor(.ink.opacity(0.6))
            Text(L10n.collectionEmptyHint)
                .font(.serifItalic(16))
                .foregroundColor(.ink.opacity(0.5))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 150, maximum: 180), spacing: 16)
            ], spacing: 16) {
                ForEach(Array(filtered.enumerated()), id: \.element.id) { idx, spec in
                    Button {
                        presented = spec
                    } label: {
                        GalleryCell(specimen: spec, number: filtered.count - idx)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
    }
}

private struct GalleryCell: View {
    @EnvironmentObject var theme: ThemeSettings
    let specimen: Specimen
    let number: Int

    var body: some View {
        VStack(spacing: 6) {
            Group {
                if let ui = UIImage(contentsOfFile: storeURL.path) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                        .blendMode(.multiply)
                        .saturation(0.92)
                        .contrast(1.04)
                } else {
                    theme.baseColor
                }
            }
            .padding(8)
            .overlay(Rectangle().stroke(Color.ink, lineWidth: 1))
            .overlay(alignment: .topTrailing) {
                // Heart badge — only visible when favorited.
                if specimen.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.dangerInk)
                        .padding(6)
                        .background(
                            Circle().fill(theme.baseColor.opacity(0.85))
                                .overlay(Circle().stroke(Color.ink, lineWidth: 0.75))
                        )
                        .padding(6)
                }
            }
            Text("No. \(number)")
                .font(.scriptTitle(20))
                .foregroundColor(.ink)
                .padding(.top, 6)
                .overlay(
                    Rectangle()
                        .fill(Color.fadedInk)
                        .frame(height: 1)
                        .offset(y: -4),
                    alignment: .top
                )
        }
    }

    private var storeURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("Trousseau").appendingPathComponent(specimen.image)
    }
}
