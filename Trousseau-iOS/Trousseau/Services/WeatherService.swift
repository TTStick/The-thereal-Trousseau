//
//  WeatherService.swift
//  Local climate estimator. No network calls — the device's coordinates
//  + the calendar month are enough to produce a sensible "what to wear
//  today" suggestion without any external API or entitlement.
//
//  Temperature model: each calendar month carries a base C, which gets
//  nudged by latitude (cooler at the poles, warmer at the equator). The
//  model is intentionally rough — it's a wardrobe assistant, not a
//  forecast service.
//

import Foundation
import CoreLocation
import SwiftUI

@MainActor
final class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = WeatherService()

    @Published private(set) var snapshot: WeatherSnapshot?
    @Published private(set) var authStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()
    private var pending: ((WeatherSnapshot) -> Void)?

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    /// Asks for one-shot location, then resolves with a snapshot. If the
    /// user denies permission, falls back to a coordinate-less estimate
    /// using just the calendar month (treated as the temperate northern
    /// hemisphere).
    func refresh() async -> WeatherSnapshot {
        authStatus = manager.authorizationStatus
        return await withCheckedContinuation { cont in
            self.pending = { snap in
                cont.resume(returning: snap)
            }
            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .denied, .restricted:
                self.deliver(estimate(latitude: nil))
            @unknown default:
                self.deliver(estimate(latitude: nil))
            }
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        let lat = locations.first?.coordinate.latitude
        Task { @MainActor in
            self.deliver(self.estimate(latitude: lat))
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: Error) {
        Task { @MainActor in
            self.deliver(self.estimate(latitude: nil))
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authStatus = status
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .denied, .restricted:
                self.deliver(self.estimate(latitude: nil))
            default:
                break
            }
        }
    }

    // MARK: - Estimator

    private func deliver(_ snap: WeatherSnapshot) {
        snapshot = snap
        pending?(snap)
        pending = nil
    }

    private func estimate(latitude: Double?) -> WeatherSnapshot {
        let month = Calendar.current.component(.month, from: Date())
        let baseTemp = WeatherModel.baseTemp(forMonth: month)
        let latDelta = WeatherModel.latitudeDelta(latitude: latitude, month: month)
        let tempC = baseTemp + latDelta
        let condition = WeatherModel.condition(forC: tempC)
        let suggestion = WeatherModel.suggestion(for: condition, tempC: tempC)
        return WeatherSnapshot(
            condition: condition,
            tempC: tempC,
            suggestion: suggestion,
            latitude: latitude
        )
    }
}

// MARK: - Public types

enum WeatherCondition: String {
    case frigid, cold, cool, mild, warm, hot

    var label: String {
        switch self {
        case .frigid: return "Frigid"
        case .cold:   return "Cold"
        case .cool:   return "Cool"
        case .mild:   return "Mild"
        case .warm:   return "Warm"
        case .hot:    return "Hot"
        }
    }

    var symbol: String {
        switch self {
        case .frigid: return "❄︎"
        case .cold:   return "☁︎"
        case .cool:   return "☁︎"
        case .mild:   return "☀︎"
        case .warm:   return "☀︎"
        case .hot:    return "☀︎"
        }
    }
}

struct WeatherSnapshot: Equatable {
    let condition: WeatherCondition
    let tempC: Double
    let suggestion: String
    let latitude: Double?
}

// MARK: - Pure-function climate model

private enum WeatherModel {
    /// Average temperature for a temperate northern hemisphere month.
    static func baseTemp(forMonth m: Int) -> Double {
        // 1=Jan, 12=Dec. Approximated as a sinusoid around 12°C.
        let avg: Double = 12
        let amp: Double = 13
        let phase = Double(m - 4) * .pi / 6   // peak in July (m=7)
        return avg + amp * cos(phase)
    }

    /// Latitude adjustment. Equator → +5°, mid-lat → 0, polar → -10°.
    /// Flipped in southern hemisphere winter months (Apr–Sep).
    static func latitudeDelta(latitude: Double?, month: Int) -> Double {
        guard let lat = latitude else { return 0 }
        let absLat = min(abs(lat), 80)
        let mag = (absLat - 45) / 4.0   // 0 at 45°, ±10 at equator/poles
        let isSouthernWinter = (4...9).contains(month)
        let sign: Double = (lat < 0) == isSouthernWinter ? -1 : 1
        return -mag * sign
    }

    static func condition(forC c: Double) -> WeatherCondition {
        switch c {
        case ..<0:   return .frigid
        case 0..<8:  return .cold
        case 8..<14: return .cool
        case 14..<20: return .mild
        case 20..<27: return .warm
        default:     return .hot
        }
    }

    static func suggestion(for cond: WeatherCondition, tempC: Double) -> String {
        switch cond {
        case .frigid: return L10n.weatherFrigid
        case .cold:   return L10n.weatherCold
        case .cool:   return L10n.weatherCool
        case .mild:   return L10n.weatherMild
        case .warm:   return L10n.weatherWarm
        case .hot:    return L10n.weatherHot
        }
    }
}