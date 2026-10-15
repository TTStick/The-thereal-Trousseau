//
//  L10n.swift
//  Localisation helpers. Static `Text("…")` literals auto-localise
//  through `LocalizedStringKey`; this enum is for strings with runtime
//  interpolations that the type system can't otherwise see (counts,
//  dates, formatted currency, etc.).
//
//  Every key here MUST also exist in both `en.lproj/Localizable.strings`
//  and `zh-Hans.lproj/Localizable.strings` — the English file is
//  authoritative; Chinese is translated in lockstep.
//

import Foundation

enum L10n {

    // MARK: - Gallery

    static func tripsOnHorizon(_ n: Int) -> String {
        let key = n == 1 ? "%lld trip on the horizon" : "%lld trips on the horizon"
        return String.localizedStringWithFormat(NSLocalizedString(key, comment: ""), n)
    }
    static let noTrunksYet = String(
        localized: "No trunks packed yet.")
    static let draftFirstTrip = String(
        localized: "Tap + to draft your first trip kit.")
    static let emptyKit = String(
        localized: "Empty kit — tap to add specimens.")
    static let newPackingList = String(
        localized: "New packing list")

    // MARK: - Journal

    static func entriesTotal(_ n: Int) -> String {
        String.localizedStringWithFormat(NSLocalizedString(
            "%lld total", comment: ""), n)
    }
    static let journalEmpty = String(
        localized: "The journal is empty.")
    static let journalEmptyHint = String(
        localized: "Tap a date above or the + to log today's attire.")
    static let untitledEntry = String(
        localized: "Untitled entry")
    static let newJournalEntry = String(
        localized: "New journal entry")
    static func specimensCount(_ n: Int) -> String {
        let key = n == 1 ? "%lld specimen" : "%lld specimens"
        return String.localizedStringWithFormat(NSLocalizedString(key, comment: ""), n)
    }
    static let discardEntry = String(
        localized: "Discard Entry")
    static let journalTitle = String(
        localized: "Journal of Attire")
    static let recentEntries = String(
        localized: "Recent Entries")
    static let newEntry = String(
        localized: "New Entry")

    // MARK: - Add specimen

    static let archiveNewItem = String(
        localized: "Archive New Item")
    static let selectPhotograph = String(
        localized: "Click to select photograph")
    static let selected = String(
        localized: "Selected")
    static let curatorsRemarks = String(
        localized: "Curator's Remarks")
    static let remarksPlaceholder = String(
        localized: "Enter Curator's Remarks...")
    static let originalPrice = String(
        localized: "Original price (optional)")
    static let permanentArchive = String(
        localized: "PERMANENT ARCHIVE")
    static let discardReturn = String(
        localized: "Discard & Return")
    static let tailorIsWorking = String(
        localized: "The Tailor is cutting the pattern...")
    static let tailorBackRoom = String(
        localized: "The Tailor is working in the back room...")

    // MARK: - Bulk import

    static let bulkImport = String(
        localized: "Bulk Import")
    static let bulkSelect = String(
        localized: "Click to select photographs")
    static func bulkSelectedCount(_ n: Int) -> String {
        String.localizedStringWithFormat(NSLocalizedString(
            "%lld selected", comment: ""), n)
    }
    static let tapToChange = String(
        localized: "Tap to change selection")
    static let howBulkWorks = String(
        localized: "How bulk import works")
    static let howBulkWorksBody = String(
        localized: "Each photo is sent through the local tailor (background removal + colour extraction) and archived as its own specimen. Notes, tags, and prices can be filled in afterwards by tapping any item in the collection.")
    static let bulkErrorsHeader = String(
        localized: "Some photos could not be processed:")
    static let bulkImportNote = String(
        localized: "Bulk import — edit me")
    static let bulkProgress = String(
        localized: "%lld of %lld tailored")

    // MARK: - Backup / Restore

    static let archivesTitle = String(
        localized: "Archives & Cipher")
    static let archivesSubtitle = String(
        localized: "Keep your trousseau close, or carry it with you.")
    static let exportLabel = String(
        localized: "Export")
    static let importLabel = String(
        localized: "Import")
    static let exportBody = String(
        localized: "Bundle every specimen, journal entry, packing list, and photo into a single .json you can keep in Files, iCloud, or email to yourself.")
    static let importBody = String(
        localized: "Pick a previously-exported .json to overwrite the current wardrobe. Existing files of the same name will be replaced.")
    static let exportTrousseau = String(
        localized: "Export Trousseau")
    static let importBackup = String(
        localized: "Import Backup")
    static let bundleReady = String(
        localized: "Bundle ready. Save it where you'll find it.")
    static let restoreOK = String(
        localized: "Trousseau restored.")
    static let replaceTitle = String(
        localized: "Replace existing wardrobe?")
    static let replaceBody = String(
        localized: "Importing will overwrite wardrobe_db.json, outfits.json, packing.json, and all photos. This cannot be undone.")
    static let replaceAction = String(
        localized: "Replace")
    static let cancelAction = String(
        localized: "Cancel")
    static let errorTitle = String(
        localized: "Error")
    static let okAction = String(
        localized: "OK")

    // MARK: - Weather

    static let weatherReading = String(
        localized: "Reading the local climate...")
    static let weatherTap = String(
        localized: "Tap to read the local climate.")
    static let weatherFrigid = String(
        localized: "A heavy coat, wool, and layers. Velvet welcomes the cold.")
    static let weatherCold = String(
        localized: "A wool overcoat over knit; consider trousers over a skirt.")
    static let weatherCool = String(
        localized: "Light layering — a shirt and a jacket will see you through.")
    static let weatherMild = String(
        localized: "A blouse or a linen piece, comfortable in open air.")
    static let weatherWarm = String(
        localized: "Linen, cotton, silks in light weaves. Leave the wool at home.")
    static let weatherHot = String(
        localized: "The lightest cottons and linens. Pale pigments reflect the sun.")
    static let weatherLocationTitle = String(
        localized: "Allow \"Trousseau\" to use your location?")
    static let weatherLocationBody = String(
        localized: "The Ethereal Trousseau reads your approximate location only to suggest what to wear given the current climate. Nothing leaves the device.")

    // MARK: - Manifesto

    static let manifestoTitle = String(
        localized: "The Curator's Manifesto")
    static let manifestoI = String(
        localized: "I. The Purpose")
    static let manifestoII = String(
        localized: "II. The Mechanism")
    static let manifestoIII = String(
        localized: "III. Usage Instructions")
    static let manifestoIV = String(
        localized: "IV. Paper Atelier")
    static let manifestoV = String(
        localized: "V. Archives & Cipher")
    static let manifestoIBody = String(
        localized: "In an age of ephemeral data, **The Ethereal Trousseau** serves as a permanent digital sanctuary for textile artistry. It is designed to catalog, preserve, and display the silhouette of garments, stripping away the noise of the physical world to reveal the essence of the design.")
    static let manifestoIIBody = String(
        localized: "This archive utilizes on-device neural processing via Apple's Vision framework. Upon the acquisition of a new image (Capture), the system autonomously isolates the subject from its surroundings (Segmentation), centers the geometry, and mounts it upon a standardized parchment canvas. No data leaves this device; privacy is absolute.")
    static let manifestoIIIToArchive = String(
        localized: "**To Archive:** Tap the central \"+\" button on the navigation ribbon. Choose a photograph. The automated tailor will process the garment on-device in seconds.")
    static let manifestoIIIToObserve = String(
        localized: "**To Observe:** Browse the Collection. Tap any specimen to view the Curator's detailed remarks, edit tags, and log a wear.")
    static let manifestoIVBody = String(
        localized: "Tune the warmth, depth and grain of the parchment to your taste. The change applies across every screen instantly.")
    static let manifestoVBody = String(
        localized: "Export the entire trousseau — every specimen, journal entry, packing list, and photo — into a single .json you can keep in Files, iCloud, or email to yourself. Or restore a previous export to overwrite the current collection.")
    static let manifestoColophon = String(
        localized: "Est. 2024 — A Personal Collection")
    static let paperAtelier = String(
        localized: "Paper Atelier")
    static let paperAtelierTitle = String(
        localized: "Paper Atelier")
    static let settingsWarmth = String(
        localized: "Warmth")
    static let settingsDarkness = String(
        localized: "Darkness")
    static let settingsTexture = String(
        localized: "Texture")
    static let settingsDone = String(
        localized: "Done")
    static let settingsDescription = String(
        localized: "These three dials shape every screen at once. Choose between a clean, crisp page and one that looks like it survived a small fire.")

    // MARK: - Common

    static let done = String(
        localized: "Done")
    static let cancel = String(
        localized: "Cancel")
    static let save = String(
        localized: "Save")
    static let search = String(
        localized: "Search Archives...")
    static let title = String(
        localized: "The Ethereal Trousseau")
    static let archiveNewSpecimen = String(
        localized: "Archive New Specimen")
    static let openJournal = String(
        localized: "Open journal")
    static let openPackingLists = String(
        localized: "Open packing lists")
    static let bulkImportPhotos = String(
        localized: "Bulk import photos")

    // MARK: - Gallery filter

    static let allFilter = String(localized: "All")
    static let favoritesFilter = String(localized: "Favorites")
    static let wishlistFilter = String(localized: "Wishlist")
    static let collectionEmpty = String(localized: "Collection Empty")
    static let collectionEmptyHint = String(localized: "Press \"+\" to archive.")

    // MARK: - Specimen detail

    static let wearToday = String(
        localized: "MARK TODAY AS WORN")
    static let costPerWear = String(
        localized: "COST / WEAR")
    static let wornLabel = String(localized: "WORN")
    static let lastLabel = String(localized: "LAST")
    static let costLabel = String(localized: "COST")
    static let wearLabel = String(localized: "WEAR")
    static let purchaseLedger = String(localized: "Purchase Ledger")
    static let purchasePriceTitle = String(localized: "Purchase Price (CNY)")
    static let savePrice = String(localized: "Save Price")
    static let neverWorn = String(localized: "Never worn")
    static func daysAgo(_ n: Int) -> String {
        String.localizedStringWithFormat(NSLocalizedString(
            "%lld days ago", comment: ""), n)
    }
    static let today = String(localized: "Today")
    static let yesterday = String(localized: "Yesterday")
    static func wornCount(_ n: Int) -> String {
        String.localizedStringWithFormat(NSLocalizedString(
            "%lld wears", comment: ""), n)
    }
    static let favoriteOn = String(localized: "Favorite")
    static let favoriteOff = String(localized: "Favorite")
    static let wishlistOn = String(localized: "On wishlist")
    static let wishlistOff = String(localized: "Not on wishlist")
    static let alreadyLoggedToday = String(localized: "Today's wear already logged.")
    static let wearLogged = String(localized: "Logged today as worn.")
    static let archiveMenu = String(localized: "Archive")

    // MARK: - Census

    static let censusTitle = String(localized: "Census of the Wardrobe")
    static let censusSubtitle = String(localized: "A statistical view of what you own.")
    static let mostWorn = String(localized: "Most Worn")
    static let leastWorn = String(localized: "Least Worn")
    static let dormantTitle = String(localized: "Dormant")
    static let dormantSubtitle = String(localized: "Archived but never worn.")
    static let dominantPigments = String(localized: "Dominant Pigments")
    static let dominantPigmentsSub = String(localized: "Tinted swatches of the wardrobe's most recurring hues.")
    static let specimensByColor = String(localized: "Specimens by Pigment")
    static let noMatch = String(localized: "No specimens match this colour.")

    // MARK: - Packing editor

    static let newTrunk = String(localized: "New Trunk")
    static let editTrunk = String(localized: "Edit Trunk")
    static let tripTitle = String(localized: "Trip Title")
    static let tripTitlePlaceholder = String(localized: "e.g. Kyoto Autumn")
    static let dates = String(localized: "Dates")
    static let clear = String(localized: "Clear")
    static let startLabel = String(localized: "Start")
    static let endLabel = String(localized: "End")
    static let setLabel = String(localized: "set")
    static let specimensLabel = String(localized: "Specimens")
    static func selectedCount(_ n: Int) -> String {
        String.localizedStringWithFormat(NSLocalizedString(
            "%lld selected", comment: ""), n)
    }
    static let discardTrip = String(localized: "Discard Trip")
    static let untitledTrip = String(localized: "Untitled trip")
    static let trunksTitle = String(localized: "Trunk & Trousseau")
    static func fromDate(_ s: String) -> String {
        String.localizedStringWithFormat(NSLocalizedString(
            "from %@", comment: ""), s)
    }
    static func untilDate(_ s: String) -> String {
        String.localizedStringWithFormat(NSLocalizedString(
            "until %@", comment: ""), s)
    }
}