#!/usr/bin/env python3
"""
generate_xcodeproj.py — minimal, reliable Xcode project generator.

Writes Trousseau.xcodeproj from the Trousseau-iOS/ source tree.
Run if you don't want to install XcodeGen:

    python3 generate_xcodeproj.py
    open Trousseau.xcodeproj

Stdlib only.
"""

import hashlib
import pathlib

ROOT = pathlib.Path(__file__).parent.resolve()  # Trousseau-iOS/
SRC  = ROOT / "Trousseau"

# All paths in pbxproj are interpreted relative to the enclosing group,
# with the root group representing the directory containing the .xcodeproj.
# So the root group has path = "" (== ROOT), Trousseau/ group has path = "Trousseau",
# Models/ group has path = "Models" (relative to Trousseau/), etc.

SWIFT  = sorted(p for p in SRC.rglob("*.swift"))
FONTS  = sorted(p for p in (SRC / "Resources" / "Fonts").glob("*.ttf"))
ASSETS = sorted(p for p in (SRC / "Resources").rglob("*.xcassets"))
# Localization folders — each <lang>.lproj directory is one language.
# Discovered anywhere under Resources/. The dir name (without .lproj) is
# the language code that lands in Info.plist's CFBundleLocalizations.
LPROJS = sorted(p for p in (SRC / "Resources").rglob("*.lproj"))
LOCALES = [p.stem for p in LPROJS]  # e.g. ["en", "zh-Hans"]
PLIST  = SRC / "Info.plist"
print(f"Found {len(SWIFT)} Swift, {len(FONTS)} fonts, {len(ASSETS)} asset bundles, {len(LPROJS)} lproj ({', '.join(LOCALES) or 'none'})")

def u(s): return hashlib.md5(s.encode()).hexdigest()[:24].upper()

ID = {
    "PROJECT":      u("PROJECT"),
    "MAIN":         u("MAIN_GROUP"),       # root group, path = ""
    "PROD":         u("PRODUCTS_GROUP"),
    "TGT":          u("TARGET_TROUSSEAU"),
    "PROD_REF":     u("PRODUCT_REF"),      # PBXFileReference for Trousseau.app
    "PH_SRC":       u("PHASE_SOURCES"),
    "PH_RES":       u("PHASE_RESOURCES"),
    "PH_FW":        u("PHASE_FRAMEWORKS"),
    "CFG_PRJ_D":    u("CFG_PROJ_DEBUG"),
    "CFG_PRJ_R":    u("CFG_PROJ_RELEASE"),
    "CFG_TGT_D":    u("CFG_TARGET_DEBUG"),
    "CFG_TGT_R":    u("CFG_TARGET_RELEASE"),
    "CFG_LIST_PRJ": u("CFGLIST_PROJECT"),
    "CFG_LIST_TGT": u("CFGLIST_TARGET"),
    "PLIST":        u("INFO_PLIST"),
}
for p in SWIFT:
    ID[f"S:{p.name}"]  = u(f"S:{p.name}")
    ID[f"R:{p.name}"]  = u(f"R:{p.name}")
for p in FONTS:
    ID[f"F:{p.name}"]  = u(f"F:{p.name}")
    ID[f"FR:{p.name}"] = u(f"FR:{p.name}")
for p in ASSETS:
    ID[f"A:{p.name}"]  = u(f"A:{p.name}")
    ID[f"AR:{p.name}"] = u(f"AR:{p.name}")
for p in LPROJS:
    ID[f"L:{p.name}"]  = u(f"L:{p.name}")
    ID[f"LR:{p.name}"] = u(f"LR:{p.name}")

# Compute every group we'll need. Group paths are RELATIVE TO ROOT.
GROUPS = {"": ID["MAIN"], "Products": ID["PROD"]}
GROUPS["Trousseau"] = u("G:Trousseau")

# Walk every file's parent dir, compute path relative to ROOT
def rel_to_root(p):
    return str(p.parent.relative_to(ROOT))

file_parent_dirs = {rel_to_root(p) for p in SWIFT + FONTS + ASSETS + LPROJS}
for d in file_parent_dirs:
    if d not in GROUPS:
        GROUPS[d] = u(f"G:{d}")
    # Also ensure ancestors exist (intermediate dirs)
    parts = pathlib.Path(d).parts
    for i in range(1, len(parts)):
        anc = str(pathlib.Path(*parts[:i]))
        if anc not in GROUPS:
            GROUPS[anc] = u(f"G:{anc}")

# Compute which files (basename) belong to each dir
def files_in(dir_rel):
    out = []
    for p in SWIFT:
        if rel_to_root(p) == dir_rel:
            out.append(("swift", p, ID[f"R:{p.name}"]))
    for p in FONTS:
        if rel_to_root(p) == dir_rel:
            out.append(("font", p, ID[f"FR:{p.name}"]))
    for p in ASSETS:
        if rel_to_root(p) == dir_rel:
            out.append(("asset", p, ID[f"AR:{p.name}"]))
    for p in LPROJS:
        if rel_to_root(p) == dir_rel:
            out.append(("lproj", p, ID[f"LR:{p.name}"]))
    return out

# Compute subdirs of a given dir
def subdirs_of(dir_rel):
    out = []
    for d in GROUPS:
        if d == dir_rel or d == "" or d == "Products": continue
        parent_path = pathlib.Path(d).parent
        parent = "" if parent_path == pathlib.Path(".") else str(parent_path)
        if parent == dir_rel:
            out.append(d)
    return out

out = []
def w(s=""): out.append(s)

w("// !$*UTF8*$!")
w("{")
w("\tarchiveVersion = 1;")
w("\tclasses = {")
w("\t\t};")
w("\t\tobjectVersion = 56;")
w("\t\tobjects = {")

# PBXBuildFile
w("/* Begin PBXBuildFile section */")
for p in SWIFT:
    w(f"\t{ID[f'S:{p.name}']} /* {p.name} in Sources */ = {{isa = PBXBuildFile; fileRef = {ID[f'R:{p.name}']} /* {p.name} */; }};")
for p in FONTS:
    w(f"\t{ID[f'F:{p.name}']} /* {p.name} in Resources */ = {{isa = PBXBuildFile; fileRef = {ID[f'FR:{p.name}']} /* {p.name} */; }};")
for p in ASSETS:
    w(f"\t{ID[f'A:{p.name}']} /* {p.name} in Resources */ = {{isa = PBXBuildFile; fileRef = {ID[f'AR:{p.name}']} /* {p.name} */; }};")
for p in LPROJS:
    w(f"\t{ID[f'L:{p.name}']} /* {p.name} in Resources */ = {{isa = PBXBuildFile; fileRef = {ID[f'LR:{p.name}']} /* {p.name} */; }};")
w("/* End PBXBuildFile section */")

# PBXFileReference
w("/* Begin PBXFileReference section */")
w(f"\t{ID['PROD_REF']} /* Trousseau.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Trousseau.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
w(f"\t{ID['PLIST']} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Trousseau/Info.plist; sourceTree = \"<group>\"; }};")
for p in SWIFT:
    w(f"\t{ID[f'R:{p.name}']} /* {p.name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {p.name}; sourceTree = \"<group>\"; }};")
for p in FONTS:
    w(f"\t{ID[f'FR:{p.name}']} /* {p.name} */ = {{isa = PBXFileReference; lastKnownFileType = file; path = {p.name}; sourceTree = \"<group>\"; }};")
for p in ASSETS:
    w(f"\t{ID[f'AR:{p.name}']} /* {p.name} */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = {p.name}; sourceTree = \"<group>\"; }};")
for p in LPROJS:
    # `.lproj` is treated as a folder by Xcode — Xcode auto-detects that
    # the contents are localization files and groups them under the locale
    # in the project navigator.
    w(f"\t{ID[f'LR:{p.name}']} /* {p.name} */ = {{isa = PBXFileReference; lastKnownFileType = folder; path = {p.name}; sourceTree = \"<group>\"; }};")
w("/* End PBXFileReference section */")

# PBXFrameworksBuildPhase
w("/* Begin PBXFrameworksBuildPhase section */")
w(f"\t{ID['PH_FW']} /* Frameworks */ = {{")
w("\t\tisa = PBXFrameworksBuildPhase;")
w("\t\tbuildActionMask = 2147483647;")
w("\t\tfiles = (")
w("\t\t);")
w("\t\trunOnlyForDeploymentPostprocessing = 0;")
w("\t};")
w("/* End PBXFrameworksBuildPhase section */")

# PBXGroup — root group has path = "" so everything resolves from project root.
w("/* Begin PBXGroup section */")

def emit_group(dir_rel):
    if dir_rel == "":
        gid = ID["MAIN"]
        label = "Trousseau-iOS"
    elif dir_rel == "Products":
        gid = ID["PROD"]
        label = "Products"
    else:
        gid = GROUPS[dir_rel]
        label = pathlib.Path(dir_rel).name

    w(f"\t{gid} /* {label} */ = {{")
    w("\t\tisa = PBXGroup;")
    w("\t\tchildren = (")
    # Files at this level
    for kind, p, ref_id in files_in(dir_rel):
        w(f"\t\t\t{ref_id} /* {p.name} */,")
    # Subdirs at this level
    for sub in subdirs_of(dir_rel):
        sub_label = pathlib.Path(sub).name
        w(f"\t\t\t{GROUPS[sub]} /* {sub_label} */,")
    w("\t\t);")
    if dir_rel == "":
        w("\t\tsourceTree = \"<group>\";")
    elif dir_rel == "Products":
        w("\t\tname = Products;")
        w("\t\tsourceTree = \"<group>\";")
    else:
        # Path = basename of this dir (relative to its parent)
        w(f"\t\tpath = {pathlib.Path(dir_rel).name};")
        w("\t\tsourceTree = \"<group>\";")
    w("\t};")

# Emit root, then Products, then every other group
emit_group("")
emit_group("Products")
for d in sorted(GROUPS):
    if d in ("", "Products"): continue
    emit_group(d)
w("/* End PBXGroup section */")

# PBXNativeTarget
w("/* Begin PBXNativeTarget section */")
w(f"\t{ID['TGT']} /* Trousseau */ = {{")
w("\t\tisa = PBXNativeTarget;")
w(f"\t\tbuildConfigurationList = {ID['CFG_LIST_TGT']} /* Build configuration list for PBXNativeTarget \"Trousseau\" */;")
w("\t\tbuildPhases = (")
w(f"\t\t\t{ID['PH_SRC']} /* Sources */,")
w(f"\t\t\t{ID['PH_FW']} /* Frameworks */,")
w(f"\t\t\t{ID['PH_RES']} /* Resources */,")
w("\t\t);")
w("\t\tbuildRules = (")
w("\t\t);")
w("\t\tdependencies = (")
w("\t\t);")
w("\t\tname = Trousseau;")
w("\t\tproductName = Trousseau;")
w(f"\t\tproductReference = {ID['PROD_REF']} /* Trousseau.app */;")
w("\t\tproductType = \"com.apple.product-type.application\";")
w("\t};")
w("/* End PBXNativeTarget section */")

# PBXProject
w("/* Begin PBXProject section */")
w(f"\t{ID['PROJECT']} /* Project object */ = {{")
w("\t\tisa = PBXProject;")
w("\t\tattributes = {")
w("\t\t\tLastSwiftUpdateCheck = 1600;")
w("\t\t\tLastUpgradeCheck = 1600;")
w("\t\t\tTargetAttributes = {")
w(f"\t\t\t\t{ID['TGT']} = {{")
w("\t\t\t\t\tCreatedOnToolsVersion = 16.0;")
w("\t\t\t\t};")
w("\t\t\t};")
w("\t\t};")
w(f"\t\tbuildConfigurationList = {ID['CFG_LIST_PRJ']} /* Build configuration list for PBXProject \"Trousseau\" */;")
w("\t\tcompatibilityVersion = \"Xcode 14.0\";")
w("\t\tdevelopmentRegion = en;")
w("\t\thasScannedForEncodings = 0;")
w("\t\tknownRegions = (")
w("\t\t\ten,")
w("\t\t\tBase,")
for loc in LOCALES:
    if loc != "en":
        w(f"\t\t\t{loc},")
w("\t\t);")
w(f"\t\tmainGroup = {ID['MAIN']};")
w(f"\t\tproductRefGroup = {ID['PROD']} /* Products */;")
w("\t\tprojectDirPath = \"\";")
w("\t\tprojectRoot = \"\";")
w("\t\ttargets = (")
w(f"\t\t\t{ID['TGT']} /* Trousseau */,")
w("\t\t);")
w("\t};")
w("/* End PBXProject section */")

# PBXResourcesBuildPhase
w("/* Begin PBXResourcesBuildPhase section */")
w(f"\t{ID['PH_RES']} /* Resources */ = {{")
w("\t\tisa = PBXResourcesBuildPhase;")
w("\t\tbuildActionMask = 2147483647;")
w("\t\tfiles = (")
for p in FONTS:
    w(f"\t\t\t{ID[f'F:{p.name}']} /* {p.name} in Resources */,")
for p in ASSETS:
    w(f"\t\t\t{ID[f'A:{p.name}']} /* {p.name} in Resources */,")
for p in LPROJS:
    w(f"\t\t\t{ID[f'L:{p.name}']} /* {p.name} in Resources */,")
w("\t\t);")
w("\t\trunOnlyForDeploymentPostprocessing = 0;")
w("\t};")
w("/* End PBXResourcesBuildPhase section */")

# PBXSourcesBuildPhase
w("/* Begin PBXSourcesBuildPhase section */")
w(f"\t{ID['PH_SRC']} /* Sources */ = {{")
w("\t\tisa = PBXSourcesBuildPhase;")
w("\t\tbuildActionMask = 2147483647;")
w("\t\tfiles = (")
for p in SWIFT:
    w(f"\t\t\t{ID[f'S:{p.name}']} /* {p.name} in Sources */,")
w("\t\t);")
w("\t\trunOnlyForDeploymentPostprocessing = 0;")
w("\t};")
w("/* End PBXSourcesBuildPhase section */")

# XCBuildConfiguration
PROJECT_SETTINGS_DEBUG = [
    ('ALWAYS_SEARCH_USER_PATHS', 'NO'),
    ('CLANG_ANALYZER_NONNULL', 'YES'),
    ('CLANG_ENABLE_MODULES', 'YES'),
    ('CLANG_ENABLE_OBJC_ARC', 'YES'),
    ('CLANG_CXX_LANGUAGE_STANDARD', '"gnu++20"'),
    ('CLANG_WARN_BOOL_CONVERSION', 'YES'),
    ('CLANG_WARN_CONSTANT_CONVERSION', 'YES'),
    ('CLANG_WARN_EMPTY_BODY', 'YES'),
    ('CLANG_WARN_ENUM_CONVERSION', 'YES'),
    ('CLANG_WARN_INFINITE_RECURSION', 'YES'),
    ('CLANG_WARN_INT_CONVERSION', 'YES'),
    ('CLANG_WARN_OBJC_ROOT_CLASS', 'YES_ERROR'),
    ('CLANG_WARN_RANGE_LOOP_ANALYSIS', 'YES'),
    ('CLANG_WARN_STRICT_PROTOTYPES', 'YES'),
    ('CLANG_WARN_SUSPICIOUS_MOVE', 'YES'),
    ('CLANG_WARN_UNGUARDED_AVAILABILITY', 'YES_AGGRESSIVE'),
    ('CLANG_WARN_UNREACHABLE_CODE', 'YES'),
    ('COPY_PHASE_STRIP', 'NO'),
    ('DEBUG_INFORMATION_FORMAT', 'dwarf'),
    ('ENABLE_STRICT_OBJC_MSGSEND', 'YES'),
    ('ENABLE_TESTABILITY', 'YES'),
    ('ENABLE_USER_SCRIPT_SANDBOXING', 'YES'),
    ('GCC_C_LANGUAGE_STANDARD', 'gnu17'),
    ('GCC_DYNAMIC_NO_PIC', 'NO'),
    ('GCC_NO_COMMON_BLOCKS', 'YES'),
    ('GCC_OPTIMIZATION_LEVEL', '0'),
    ('GCC_PREPROCESSOR_DEFINITIONS', '("DEBUG=1", "$(inherited)", )'),
    ('GCC_WARN_64_TO_32_BIT_CONVERSION', 'YES'),
    ('GCC_WARN_ABOUT_RETURN_TYPE', 'YES_ERROR'),
    ('GCC_WARN_UNDECLARED_SELECTOR', 'YES'),
    ('GCC_WARN_UNINITIALIZED_AUTOS', 'YES_AGGRESSIVE'),
    ('GCC_WARN_UNUSED_FUNCTION', 'YES'),
    ('GCC_WARN_UNUSED_VARIABLE', 'YES'),
    ('IPHONEOS_DEPLOYMENT_TARGET', '17.0'),
    ('MTL_ENABLE_DEBUG_INFO', 'INCLUDE_SOURCE'),
    ('MTL_FAST_MATH', 'YES'),
    ('ONLY_ACTIVE_ARCH', 'YES'),
    ('SDKROOT', 'iphoneos'),
    ('SWIFT_ACTIVE_COMPILATION_CONDITIONS', '"DEBUG $(inherited)"'),
    ('SWIFT_OPTIMIZATION_LEVEL', '-Onone'),
]

PROJECT_SETTINGS_RELEASE = [
    ('ALWAYS_SEARCH_USER_PATHS', 'NO'),
    ('CLANG_ANALYZER_NONNULL', 'YES'),
    ('CLANG_ENABLE_MODULES', 'YES'),
    ('CLANG_ENABLE_OBJC_ARC', 'YES'),
    ('CLANG_CXX_LANGUAGE_STANDARD', '"gnu++20"'),
    ('CLANG_WARN_BOOL_CONVERSION', 'YES'),
    ('CLANG_WARN_CONSTANT_CONVERSION', 'YES'),
    ('CLANG_WARN_EMPTY_BODY', 'YES'),
    ('CLANG_WARN_ENUM_CONVERSION', 'YES'),
    ('CLANG_WARN_INFINITE_RECURSION', 'YES'),
    ('CLANG_WARN_INT_CONVERSION', 'YES'),
    ('CLANG_WARN_OBJC_ROOT_CLASS', 'YES_ERROR'),
    ('CLANG_WARN_RANGE_LOOP_ANALYSIS', 'YES'),
    ('CLANG_WARN_STRICT_PROTOTYPES', 'YES'),
    ('CLANG_WARN_SUSPICIOUS_MOVE', 'YES'),
    ('CLANG_WARN_UNGUARDED_AVAILABILITY', 'YES_AGGRESSIVE'),
    ('CLANG_WARN_UNREACHABLE_CODE', 'YES'),
    ('COPY_PHASE_STRIP', 'NO'),
    ('DEBUG_INFORMATION_FORMAT', '"dwarf-with-dsym"'),
    ('ENABLE_NS_ASSERTIONS', 'NO'),
    ('ENABLE_STRICT_OBJC_MSGSEND', 'YES'),
    ('ENABLE_USER_SCRIPT_SANDBOXING', 'YES'),
    ('GCC_C_LANGUAGE_STANDARD', 'gnu17'),
    ('GCC_NO_COMMON_BLOCKS', 'YES'),
    ('GCC_WARN_64_TO_32_BIT_CONVERSION', 'YES'),
    ('GCC_WARN_ABOUT_RETURN_TYPE', 'YES_ERROR'),
    ('GCC_WARN_UNDECLARED_SELECTOR', 'YES'),
    ('GCC_WARN_UNINITIALIZED_AUTOS', 'YES_AGGRESSIVE'),
    ('GCC_WARN_UNUSED_FUNCTION', 'YES'),
    ('GCC_WARN_UNUSED_VARIABLE', 'YES'),
    ('IPHONEOS_DEPLOYMENT_TARGET', '17.0'),
    ('MTL_ENABLE_DEBUG_INFO', 'NO'),
    ('MTL_FAST_MATH', 'YES'),
    ('SDKROOT', 'iphoneos'),
    ('SWIFT_COMPILATION_MODE', 'wholemodule'),
    ('SWIFT_OPTIMIZATION_LEVEL', '-O'),
    ('VALIDATE_PRODUCT', 'YES'),
]

TARGET_SETTINGS = [
    ('ASSETCATALOG_COMPILER_APPICON_NAME', 'AppIcon'),
    ('ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME', 'AccentColor'),
    ('CODE_SIGN_STYLE', 'Automatic'),
    ('CODE_SIGNING_ALLOWED', 'NO'),
    ('CURRENT_PROJECT_VERSION', '1'),
    ('ENABLE_PREVIEWS', 'YES'),
    ('GENERATE_INFOPLIST_FILE', 'NO'),
    ('INFOPLIST_FILE', 'Trousseau/Info.plist'),
    ('IPHONEOS_DEPLOYMENT_TARGET', '17.0'),
    ('LD_RUNPATH_SEARCH_PATHS', '("$(inherited)", "@executable_path/Frameworks", )'),
    ('MARKETING_VERSION', '2.0'),
    ('PRODUCT_BUNDLE_IDENTIFIER', 'com.ethereal.trousseau'),
    ('PRODUCT_NAME', '"$(TARGET_NAME)"'),
    ('SWIFT_EMIT_LOC_STRINGS', 'YES'),
    ('SWIFT_VERSION', '5.9'),
    ('TARGETED_DEVICE_FAMILY', '"1,2"'),
]

def emit_config(uuid_, name, settings):
    w(f"\t{uuid_} /* {name} */ = {{")
    w("\t\tisa = XCBuildConfiguration;")
    w("\t\tbuildSettings = {")
    for k, v in settings:
        w(f"\t\t\t{k} = {v};")
    w("\t\t};")
    w(f"\t\tname = {name};")
    w("\t};")

w("/* Begin XCBuildConfiguration section */")
emit_config(ID['CFG_PRJ_D'], 'Debug', PROJECT_SETTINGS_DEBUG)
emit_config(ID['CFG_PRJ_R'], 'Release', PROJECT_SETTINGS_RELEASE)
emit_config(ID['CFG_TGT_D'], 'Debug', TARGET_SETTINGS)
emit_config(ID['CFG_TGT_R'], 'Release', TARGET_SETTINGS)
w("/* End XCBuildConfiguration section */")

# XCConfigurationList
w("/* Begin XCConfigurationList section */")
w(f"\t{ID['CFG_LIST_PRJ']} /* Build configuration list for PBXProject \"Trousseau\" */ = {{")
w("\t\tisa = XCConfigurationList;")
w("\t\tbuildConfigurations = (")
w(f"\t\t\t{ID['CFG_PRJ_D']} /* Debug */,")
w(f"\t\t\t{ID['CFG_PRJ_R']} /* Release */,")
w("\t\t);")
w("\t\tdefaultConfigurationIsVisible = 0;")
w("\t\tdefaultConfigurationName = Release;")
w("\t};")
w(f"\t{ID['CFG_LIST_TGT']} /* Build configuration list for PBXNativeTarget \"Trousseau\" */ = {{")
w("\t\tisa = XCConfigurationList;")
w("\t\tbuildConfigurations = (")
w(f"\t\t\t{ID['CFG_TGT_D']} /* Debug */,")
w(f"\t\t\t{ID['CFG_TGT_R']} /* Release */,")
w("\t\t);")
w("\t\tdefaultConfigurationIsVisible = 0;")
w("\t\tdefaultConfigurationName = Release;")
w("\t};")
w("/* End XCConfigurationList section */")

w("\t};")
w(f"\trootObject = {ID['PROJECT']} /* Project object */;")
w("}")

# Write --------------------------------------------------------------------
xcodeproj = ROOT / "Trousseau.xcodeproj"
xcodeproj.mkdir(exist_ok=True)
(xcodeproj / "project.xcworkspace").mkdir(exist_ok=True)
(xcodeproj / "project.xcworkspace" / "contents.xcworkspacedata").write_text(
    '<?xml version="1.0" encoding="UTF-8"?>\n'
    '<Workspace version = "1.0">\n'
    '   <FileRef location = "self:"></FileRef>\n'
    '</Workspace>\n'
)
(xcodeproj / "project.pbxproj").write_text("\n".join(out) + "\n")
print(f"\n✓ Wrote {xcodeproj}")
print(f"  Open with: open {xcodeproj}")
