//
//  WeatherBanner.swift
//  A small strip above the Gallery search field that summarises the
//  current local climate and offers a wardrobe suggestion. Tap to
//  re-request (and to retry when location is denied).
//

import SwiftUI

struct WeatherBanner: View {
    @ObservedObject var weather = WeatherService.shared
    @State private var loading = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .light))
                .foregroundColor(.ink)
                .frame(width: 24)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                if let snap = weather.snapshot {
                    Text(snap.condition.label.uppercased() + " · " + "\(Int(snap.tempC.rounded()))°C")
                        .font(.serifHeadline(11))
                        .tracking(1.5)
                        .foregroundColor(.ink)
                    Text(snap.suggestion)
                        .font(.serifItalic(13))
                        .foregroundColor(.ink.opacity(0.7))
                        .lineLimit(2)
                } else if loading {
                    Text("Reading the local climate...")
                        .font(.serifItalic(13))
                        .foregroundColor(.ink.opacity(0.6))
                } else {
                    Text("Tap to read the local climate.")
                        .font(.serifItalic(13))
                        .foregroundColor(.ink.opacity(0.55))
                }
            }
            Spacer()
        }
        .padding(10)
        .overlay(Rectangle().stroke(Color.ink.opacity(0.5), lineWidth: 0.75))
        .contentShape(Rectangle())
        .onTapGesture { Task { await refresh() } }
        .task { await refresh() }
    }

    private var icon: String {
        switch weather.snapshot?.condition {
        case .frigid: return "snowflake"
        case .cold:   return "cloud.fill"
        case .cool:   return "cloud"
        case .mild:   return "cloud.sun"
        case .warm:   return "sun.max"
        case .hot:    return "sun.max.fill"
        case nil:     return "thermometer"
        }
    }

    private func refresh() async {
        loading = true
        defer { loading = false }
        _ = await weather.refresh()
    }
}