import CoreLocation
import Foundation
import Observation
import WeatherKit

/// Current conditions and sun times from WeatherKit for the TV's location.
/// Every property stays nil when weather is unavailable (no permission, no
/// network, or the app isn't signed with the WeatherKit capability), and the
/// UI simply hides weather in that case.
@Observable
final class WeatherStore {
    private(set) var temperature: Measurement<UnitTemperature>?
    private(set) var symbolName: String?
    /// Upcoming sunrises and sunsets, soonest first.
    private(set) var sunEvents: [SunEvent] = []
    private(set) var attribution: WeatherAttribution?
    /// The TV's approximate location, kept even when WeatherKit itself is unavailable.
    private(set) var location: CLLocation?

    struct SunEvent: Equatable {
        let date: Date
        let isSunrise: Bool
    }

    @ObservationIgnored private let locationProvider = LocationProvider()
    @ObservationIgnored private var lastRefresh: Date?
    @ObservationIgnored private let refreshInterval: TimeInterval = 30 * 60

    var formattedTemperature: String? {
        temperature.map {
            $0.formatted(.measurement(width: .narrow, usage: .weather, numberFormatStyle: .number.precision(.fractionLength(0))))
        }
    }

    func nextSunEvent(after date: Date) -> SunEvent? {
        sunEvents.first { $0.date > date }
    }

    /// Fetches fresh weather unless the last successful fetch is under 30 minutes old.
    func refreshIfNeeded() async {
        if let lastRefresh, Date().timeIntervalSince(lastRefresh) < refreshInterval { return }
        guard let location = await locationProvider.currentLocation() else { return }
        self.location = location

        do {
            let (current, daily) = try await WeatherService.shared.weather(for: location, including: .current, .daily)
            temperature = current.temperature
            symbolName = current.symbolName
            sunEvents = daily.forecast.prefix(3).flatMap { day -> [SunEvent] in
                [
                    day.sun.sunrise.map { SunEvent(date: $0, isSunrise: true) },
                    day.sun.sunset.map { SunEvent(date: $0, isSunrise: false) },
                ].compactMap { $0 }
            }
            .sorted { $0.date < $1.date }
            lastRefresh = .now
        } catch {
            return
        }

        if attribution == nil {
            attribution = try? await WeatherService.shared.attribution
        }
    }
}
