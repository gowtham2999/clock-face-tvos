import CoreLocation
import Foundation
import MapKit
import Observation
import WeatherKit

/// Current conditions, forecasts and sun times from WeatherKit for the TV's location.
/// Every property stays nil or empty when weather is unavailable (no permission, no
/// network, or the app isn't signed with the WeatherKit capability), and the UI
/// falls back to what it can compute on device.
@Observable
final class WeatherStore {
    private(set) var temperature: Measurement<UnitTemperature>?
    private(set) var symbolName: String?
    /// "Mostly Sunny", "Rain"…
    private(set) var conditionDescription: String?
    private(set) var todayHigh: Measurement<UnitTemperature>?
    private(set) var todayLow: Measurement<UnitTemperature>?
    /// The next few hours, starting with the current hour.
    private(set) var hourly: [HourForecast] = []
    /// The next few days, starting tomorrow.
    private(set) var daily: [DayForecast] = []
    /// Upcoming sunrises and sunsets, soonest first.
    private(set) var sunEvents: [SunEvent] = []
    private(set) var attribution: WeatherAttribution?
    /// The TV's approximate location, kept even when WeatherKit itself is unavailable.
    private(set) var location: CLLocation?
    /// The city the TV is in, e.g. "Mumbai".
    private(set) var placeName: String?

    struct SunEvent: Equatable {
        let date: Date
        let isSunrise: Bool
    }

    struct HourForecast: Equatable, Identifiable {
        let date: Date
        let symbolName: String
        let temperature: Measurement<UnitTemperature>
        var id: Date { date }
    }

    struct DayForecast: Equatable, Identifiable {
        let date: Date
        let symbolName: String
        let high: Measurement<UnitTemperature>
        let low: Measurement<UnitTemperature>
        var id: Date { date }
    }

    @ObservationIgnored private let locationProvider = LocationProvider()
    @ObservationIgnored private var lastRefresh: Date?
    @ObservationIgnored private let refreshInterval: TimeInterval = 30 * 60

    var hasForecast: Bool { temperature != nil }

    var formattedTemperature: String? {
        temperature.map { Self.format($0) }
    }

    /// "26°", in the unit the viewer's region uses.
    static func format(_ temperature: Measurement<UnitTemperature>) -> String {
        temperature.formatted(.measurement(
            width: .narrow, usage: .weather, hidesScaleName: true,
            numberFormatStyle: .number.precision(.fractionLength(0))
        ))
    }

    func nextSunEvent(after date: Date) -> SunEvent? {
        sunEvents.first { $0.date > date }
    }

    /// Fetches fresh weather unless the last successful fetch is under 30 minutes old.
    func refreshIfNeeded() async {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "UITestSampleWeather") {
            loadSample()
            return
        }
        #endif
        if let lastRefresh, Date().timeIntervalSince(lastRefresh) < refreshInterval { return }
        guard let location = await locationProvider.currentLocation() else { return }
        self.location = location
        if placeName == nil {
            placeName = await Self.placeName(for: location)
        }

        do {
            let (current, hours, days) = try await WeatherService.shared.weather(for: location, including: .current, .hourly, .daily)
            temperature = current.temperature
            symbolName = current.symbolName
            conditionDescription = current.condition.description

            let today = days.forecast.first { Calendar.current.isDateInToday($0.date) }
            todayHigh = today?.highTemperature
            todayLow = today?.lowTemperature

            let hourStart = Calendar.current.dateInterval(of: .hour, for: .now)?.start ?? .now
            hourly = hours.forecast
                .filter { $0.date >= hourStart }
                .prefix(6)
                .map { HourForecast(date: $0.date, symbolName: $0.symbolName, temperature: $0.temperature) }
            daily = days.forecast
                .filter { $0.date > (today?.date ?? .now) }
                .prefix(5)
                .map { DayForecast(date: $0.date, symbolName: $0.symbolName, high: $0.highTemperature, low: $0.lowTemperature) }

            sunEvents = days.forecast.prefix(3).flatMap { day -> [SunEvent] in
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

    private static func placeName(for location: CLLocation) async -> String? {
        guard let request = MKReverseGeocodingRequest(location: location) else { return nil }
        let items = try? await request.mapItems
        return items?.first?.addressRepresentations?.cityName
    }

    #if DEBUG
    /// A fixed forecast so screenshots and UI tests can show the full weather tile
    /// on a simulator that isn't signed for WeatherKit.
    private func loadSample() {
        let celsius = { (value: Double) in Measurement(value: value, unit: UnitTemperature.celsius) }
        let hourStart = Calendar.current.dateInterval(of: .hour, for: .now)?.start ?? .now
        let dayStart = Calendar.current.startOfDay(for: .now)

        placeName = "Mumbai"
        location = CLLocation(latitude: 19.076, longitude: 72.8777)
        temperature = celsius(29)
        symbolName = "sun.max.fill"
        conditionDescription = "Sunny"
        todayHigh = celsius(32)
        todayLow = celsius(24)
        hourly = zip([29, 30, 30, 29, 28, 27], ["sun.max.fill", "sun.max.fill", "cloud.sun.fill", "cloud.sun.fill", "cloud.fill", "cloud.moon.fill"])
            .enumerated()
            .map { index, entry in
                HourForecast(date: hourStart.addingTimeInterval(Double(index) * 3600), symbolName: entry.1, temperature: celsius(Double(entry.0)))
            }
        daily = [(31, 24, "cloud.sun.fill"), (30, 24, "cloud.drizzle.fill"), (29, 23, "cloud.rain.fill"), (31, 24, "sun.max.fill"), (32, 25, "sun.max.fill")]
            .enumerated()
            .map { index, entry in
                DayForecast(
                    date: dayStart.addingTimeInterval(Double(index + 1) * 86_400),
                    symbolName: entry.2, high: celsius(Double(entry.0)), low: celsius(Double(entry.1))
                )
            }
    }
    #endif
}
