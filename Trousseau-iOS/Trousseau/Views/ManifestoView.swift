//
//  ManifestoView.swift
//  /readme — the Curator's Manifesto.
//

import SwiftUI

struct ManifestoView: View {
    @State private var showSettings = false
    @State private var showBackup = false

    var body: some View {
        ZStack {
            // PaperBackdrop lives *inside* the NavigationStack so it sits on
            // top of iOS 17's systemMaterial default.
            NavigationStack {
                ZStack {
                    PaperBackdrop()
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            Text("The Curator's Manifesto")
                                .font(.scriptTitle(48))
                                .foregroundColor(.ink)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.bottom, 16)

                            manifestoSection("I. The Purpose") {
                                Text("In an age of ephemeral data, **The Ethereal Trousseau** serves as a permanent digital sanctuary for textile artistry. It is designed to catalog, preserve, and display the silhouette of garments, stripping away the noise of the physical world to reveal the essence of the design.")
                            }

                            manifestoSection("II. The Mechanism") {
                                Text("This archive utilizes on-device neural processing via Apple's Vision framework. Upon the acquisition of a new image (Capture), the system autonomously isolates the subject from its surroundings (Segmentation), centers the geometry, and mounts it upon a standardized parchment canvas. No data leaves this device; privacy is absolute.")
                            }

                            manifestoSection("III. Usage Instructions") {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("**To Archive:** Tap the central \"+\" button on the navigation ribbon. Choose a photograph. The automated tailor will process the garment on-device in seconds.")
                                    Text("**To Observe:** Browse the Collection. Tap any specimen to view the Curator's detailed remarks, edit tags, and log a wear.")
                                }
                                .font(.serifBody(17))
                                .lineSpacing(6)
                            }

                            // — Paper Atelier entry —
                            Button { showSettings = true } label: {
                                HStack {
                                    Text("IV. Paper Atelier")
                                        .font(.serifHeadline(14))
                                        .tracking(2)
                                        .foregroundColor(.ink)
                                    Spacer()
                                    Text("→")
                                        .font(.serifItalic(15))
                                        .foregroundColor(.ink.opacity(0.6))
                                }
                                .padding(.top, 8)
                                .overlay(
                                    Rectangle().fill(Color.ink).frame(height: 1),
                                    alignment: .bottom
                                )
                            }
                            Text("Tune the warmth, depth and grain of the parchment to your taste. The change applies across every screen instantly.")
                                .font(.serifBody(17))
                                .lineSpacing(6)

                            // — Archives & Cipher entry —
                            Button { showBackup = true } label: {
                                HStack {
                                    Text("V. Archives & Cipher")
                                        .font(.serifHeadline(14))
                                        .tracking(2)
                                        .foregroundColor(.ink)
                                    Spacer()
                                    Text("→")
                                        .font(.serifItalic(15))
                                        .foregroundColor(.ink.opacity(0.6))
                                }
                                .padding(.top, 8)
                                .overlay(
                                    Rectangle().fill(Color.ink).frame(height: 1),
                                    alignment: .bottom
                                )
                            }
                            Text("Export the entire trousseau — every specimen, journal entry, packing list, and photo — into a single .json you can keep in Files, iCloud, or email to yourself. Or restore a previous export to overwrite the current collection.")
                                .font(.serifBody(17))
                                .lineSpacing(6)

                            Text("Est. 2024 — A Personal Collection")
                                .font(.serifItalic(15))
                                .foregroundColor(.ink.opacity(0.6))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 40)
                        }
                        .padding(24)
                    }
                }
                .navigationBarHidden(true)
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
                    .navigationTitle("Paper Atelier")
            }
        }
        .sheet(isPresented: $showBackup) {
            BackupView()
        }
        .onAppear {
            // Headless deep-link: consume the debug key to auto-open Backup.
            if UserDefaults.standard.bool(forKey: "debug.showBackup") {
                UserDefaults.standard.removeObject(forKey: "debug.showBackup")
                showBackup = true
            }
        }
    }

    @ViewBuilder
    private func manifestoSection<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.serifHeadline(14))
                .tracking(2)
                .foregroundColor(.ink)
                .overlay(
                    Rectangle().fill(Color.ink).frame(height: 1),
                    alignment: .bottom
                )
            content()
                .font(.serifBody(17))
                .lineSpacing(6)
        }
    }
}
