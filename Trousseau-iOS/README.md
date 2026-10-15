# The Ethereal Trousseau · iOS

A native iOS port of [Trousseau-Ethereal](../Trousseau-Ethereal) — the local-first digital wardrobe. Same aesthetic, same workflow, **zero external APIs**.

> The web version runs Flask + rembg + colorgram on your laptop.
> This iOS version runs SwiftUI + Apple's Vision framework on your phone.
> Both versions store data as plain JSON in their respective documents directories.

## What was preserved

| Web route | iOS screen | File |
|---|---|---|
| `/`  Collection (gallery + search) | `GalleryView` | `Views/GalleryView.swift` |
| `/add`  Archive New Item | `AddSpecimenView` (sheet) | `Views/AddSpecimenView.swift` |
| `/item/<id>`  Specimen Detail | `SpecimenDetailView` | `Views/SpecimenDetailView.swift` |
| `/collage`  Moodboard | `CollageCanvasView` | `Views/CollageCanvasView.swift` |
| `/stats`  Census + Oracle | `CensusView` | `Views/CensusView.swift` |
| `/readme`  Curator's Manifesto | `ManifestoView` | `Views/ManifestoView.swift` |

Same colour palette (`#f4ecd8` parchment, `#2c2c2c` ink, `#8a2c2c` danger), same fonts (Pinyon Script + Cormorant Garamond, both bundled), same double-line borders, same `mix-blend-mode: multiply` so every image looks pressed into paper.

## What was re-engineered

### Local background removal (`BackgroundRemovalService.swift`)
The web version uses `rembg` (which calls u2net, a 176 MB CoreML model). The iOS version uses Apple's `VNGenerateForegroundInstanceMaskRequest` (iOS 17+), which ships with the OS and runs on the Neural Engine. No model download, no network.

Falls back to attention-based saliency (`VNGenerateAttentionBasedSaliencyImageRequest`) if the instance mask returns nothing — same `rembg` does internally for transparent backgrounds.

### Local color extraction (`ColorPaletteService.swift`)
Hand-rolled K-means (4 clusters → filter parchment → keep top 3). No dependency on `colorgram.py`. ~30 lines of Swift + `import simd`.

### JSON persistence (`WardrobeStore.swift`)
Identical shape to `wardrobe_db.json`:

```json
[
  {
    "id": "uuid",
    "image": "clothes/uuid.jpg",
    "rawImage": "uploads/uuid_raw.jpg",
    "note": "...",
    "tags": ["Silk","Summer"],
    "colors": ["#8b5a3d","#b9aa98","#cac1b0"],
    "logs": ["2026-10-07"],
    "createdAt": "2026-10-07T16:42:00Z"
  }
]
```

Stored at `Documents/Trousseau/wardrobe_db.json`. Photos at `Documents/Trousseau/{clothes,uploads}/<uuid>.jpg`.

## Requirements

- **Xcode 16 or later** (the iOS 17 SDK is bundled with Xcode 16+; Vision `VNInstanceMaskObservation` requires iOS 17 deployment target).
- **iOS 17+ device or simulator**.
- [`xcodegen`](https://github.com/yonaskolb/XcodeGen) (one-time: `brew install xcodegen`). Xcode 16+ can also import `project.yml` directly.

## Build

```bash
cd Trousseau-iOS
xcodegen generate                 # creates Trousseau.xcodeproj
open Trousseau.xcodeproj          # opens Xcode
# In Xcode: select an iPhone simulator, ⌘R
```

Or skip XcodeGen: **Xcode 16+ → File → Open → select `project.yml`** (Xcode now imports it as a project).

## Project layout

```
Trousseau-iOS/
├── project.yml                    # XcodeGen spec (source of truth)
├── README.md
└── Trousseau/
    ├── TrousseauApp.swift         # @main entry point
    ├── Info.plist
    ├── Models/
    │   └── Specimen.swift
    ├── Services/
    │   ├── WardrobeStore.swift        # JSON CRUD
    │   ├── BackgroundRemovalService.swift   # Vision instance mask
    │   └── ColorPaletteService.swift        # K-means palette
    ├── Theme/
    │   └── Theme.swift               # palette, fonts, paper grain
    ├── Views/
    │   ├── RootView.swift
    │   ├── GalleryView.swift
    │   ├── AddSpecimenView.swift
    │   ├── SpecimenDetailView.swift
    │   ├── CollageCanvasView.swift
    │   ├── CensusView.swift
    │   └── ManifestoView.swift
    └── Resources/
        ├── Assets.xcassets/
        │   ├── AppIcon.appiconset/        # AppIcon.png (1024×1024)
        │   ├── ParchmentColor.colorset/
        │   └── AccentColor.colorset/
        └── Fonts/                        # bundled .ttf, registered via UIAppFonts
            ├── PinyonScript-Regular.ttf
            ├── CormorantGaramond-Regular.ttf
            ├── CormorantGaramond-Italic.ttf
            └── CormorantGaramond-SemiBold.ttf
```

## Key implementation notes

1. **Vision instance mask** is the modern, on-device replacement for `rembg`. It's the same family of models (instance segmentation, foreground extraction) but ships with iOS so there's nothing to download.
2. **K-means clustering** on a 100×100 downsampled image runs in milliseconds. The parchment filter is the only post-processing rule — same as `colorgram.py` in the web version.
3. **`mix-blend-mode: multiply`** on every specimen image — SwiftUI's `.blendMode(.multiply)` — recreates the "printed onto paper" feel that defines the web version's aesthetic.
4. **Fonts** are bundled as resources and registered through `Info.plist`'s `UIAppFonts` array. No runtime font-download code.
5. **Storage** is plain JSON, matching the web version's `wardrobe_db.json`. If you ever want to migrate a web wardrobe to iOS, drop the JSON into the Documents directory — the shape is compatible.

## App Icon

A Victorian armoire with three elegant garments standing in the doorway, drawn in deep ink on warm parchment — same colour palette as the in-app UI. Generated procedurally; bundled as a single 1024×1024 PNG (Xcode 16 auto-generates all device sizes from it).

## Privacy

Every photo, every JSON byte, every model inference stays on your device. No network code anywhere in the project. `NSPhotoLibraryUsageDescription` is the only privacy-sensitive entitlement, and it's used solely to read the photos you choose to archive.

## Credits

- Original web version: [Trousseau-Ethereal](../Trousseau-Ethereal) by you.
- iOS port: SwiftUI + Vision framework, hand-written.
- Fonts: Pinyon Script and Cormorant Garamond from Google Fonts (SIL OFL).
- App icon: AI-generated, styled to match the project's "neo-Victorian specimen plate" aesthetic.
