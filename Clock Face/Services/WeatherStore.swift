import CoreLocation
import Foundation
import MapKit
import Observation
import WeatherKit

/// Weather for the TV's location, built to keep WeatherKit calls to a minimum:
/// one request returns current conditions plus an hourly and daily forecast, which
/// is saved on the TV and read hour by hour. A new request is made only when the
/// saved forecast is six hours old (or the TV has moved), so relaunching the app or
/// leaving it on all day costs at most four calls a day.
///
/// Every value is nil when there's no forecast (no permission, no network, or the
/// app isn't signed with the WeatherKit capability); the UI falls back to what it
/// can compute on device, like sun times.
@Observable
final class WeatherStore {
    private(set) var snapshot: WeatherSnapshot? {
        didSet { save() }
    }
    private(set) var attribution: WeatherAttribution?
    /// The TV's approximate location, kept even when WeatherKit itself is unavailable.
    private(set) var location: CLLocation?

    struct SunEvent: Equatable {
        let date: Date
        let isSunrise: Bool
    }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let locationProvider = LocationProvider()
    /// Failed fetches wait this long before trying again, so a missing network
    /// or capability doesn't turn into a request every few minutes.
    @ObservationIgnored private var lastFailedAttempt: Date?
    @ObservationIgnored private let retryInterval: TimeInterval = 30 * 60
    @ObservationIgnored private var isUsingSample = false

    private static let snapshotKey = "weatherSnapshot"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        snapshot = defaults.data(forKey: Self.snapshotKey).flatMap { try? JSONDecoder().decode(WeatherSnapshot.self, from: $0) }
    }

    // MARK: - Reading

    /// Conditions for the hour containing `date`, from the saved forecast.
    func conditions(at date: Date = .now) -> WeatherSnapshot.Hour? {
        snapshot?.hour(at: date)
    }

    /// The forecast for the day containing `date`.
    func today(at date: Date = .now) -> WeatherSnapshot.Day? {
        snapshot?.day(at: date)
    }

    var hasForecast: Bool { conditions() != nil }

    var placeName: String? { snapshot?.placeName }

    var temperature: Measurement<UnitTemperature>? {
        conditions().map { Measurement(value: $0.temperature, unit: .celsius) }
    }

    var symbolName: String? { conditions()?.symbolName }

    /// "Mostly Sunny", "Rain"…
    var conditionDescription: String? { conditions()?.condition }

    var todayHigh: Measurement<UnitTemperature>? {
        today().map { Measurement(value: $0.high, unit: .celsius) }
    }

    var todayLow: Measurement<UnitTemperature>? {
        today().map { Measurement(value: $0.low, unit: .celsius) }
    }

    var formattedTemperature: String? {
        temperature.map { Self.format($0) }
    }

    /// Upcoming sunrises and sunsets, soonest first.
    var sunEvents: [SunEvent] {
        (snapshot?.days ?? []).flatMap { day -> [SunEvent] in
            [
                day.sunrise.map { SunEvent(date: $0, isSunrise: true) },
                day.sunset.map { SunEvent(date: $0, isSunrise: false) },
            ].compactMap { $0 }
        }
    }

    func nextSunEvent(after date: Date) -> SunEvent? {
        sunEvents.first { $0.date > date }
    }

    /// "26°", in the unit the viewer's region uses.
    static func format(_ temperature: Measurement<UnitTemperature>) -> String {
        temperature.formatted(.measurement(
            width: .narrow, usage: .weather, hidesScaleName: true,
            numberFormatStyle: .number.precision(.fractionLength(0))
        ))
    }

    /// Pressure as a number and unit in the viewer's convention: ("1012", "hPa") or ("29.92", "inHg").
    static func formatPressure(hectopascals: Double, locale: Locale = .current) -> (value: String, unit: String) {
        if locale.measurementSystem == .us {
            let inches = Measurement(value: hectopascals, unit: UnitPressure.hectopascals).converted(to: .inchesOfMercury).value
            return (inches.formatted(.number.precision(.fractionLength(2))), "inHg")
        }
        return (hectopascals.formatted(.number.precision(.fractionLength(0)).grouping(.never)), "hPa")
    }

    // MARK: - Fetching

    /// Fetches a new forecast only when the saved one is due for a refresh, was taken
    /// somewhere else, or doesn't exist. Cheap to call often: it returns early otherwise.
    func refreshIfNeeded(now: Date = .now) async {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "UITestSampleWeather") {
            loadSample(now: now)
            return
        }
        #endif
        if let snapshot, location != nil, !snapshot.needsRefresh(at: now) { return }
        if let lastFailedAttempt, now.timeIntervalSince(lastFailedAttempt) < retryInterval { return }

        guard let location = await locationProvider.currentLocation() else { return }
        self.location = location
        let coordinate = location.coordinate

        if let snapshot, !snapshot.needsRefresh(at: now),
           snapshot.isNear(latitude: coordinate.latitude, longitude: coordinate.longitude) {
            await loadAttributionIfNeeded()
            return
        }

        do {
            let (current, hours, days) = try await WeatherService.shared.weather(for: location, including: .current, .hourly, .daily)
            // Keep the known city name unless the TV has moved; looking it up again costs a request.
            var placeName = snapshot?.isNear(latitude: coordinate.latitude, longitude: coordinate.longitude) == true
                ? snapshot?.placeName : nil
            if placeName == nil {
                placeName = await Self.placeName(for: location)
            }
            snapshot = Self.makeSnapshot(current: current, hours: hours, days: days, at: location, placeName: placeName)
            lastFailedAttempt = nil
        } catch {
            lastFailedAttempt = now
            return
        }
        await loadAttributionIfNeeded()
    }

    private func loadAttributionIfNeeded() async {
        if attribution == nil {
            attribution = try? await WeatherService.shared.attribution
        }
    }

    private static func makeSnapshot(
        current: CurrentWeather, hours: Forecast<HourWeather>, days: Forecast<DayWeather>,
        at location: CLLocation, placeName: String?
    ) -> WeatherSnapshot {
        let currentHourStart = Calendar.current.dateInterval(of: .hour, for: current.date)?.start ?? current.date
        var hourly = hours.forecast
            .filter { $0.date >= currentHourStart }
            .map { hour in
                WeatherSnapshot.Hour(
                    date: hour.date,
                    temperature: hour.temperature.converted(to: .celsius).value,
                    symbolName: hour.symbolName,
                    condition: hour.condition.description,
                    humidity: hour.humidity,
                    pressure: hour.pressure.converted(to: .hectopascals).value,
                    uvIndex: hour.uvIndex.value,
                    precipitationChance: hour.precipitationChance
                )
            }
        // The current hour shows what was actually observed, not what was forecast.
        let observed = WeatherSnapshot.Hour(
            date: currentHourStart,
            temperature: current.temperature.converted(to: .celsius).value,
            symbolName: current.symbolName,
            condition: current.condition.description,
            humidity: current.humidity,
            pressure: current.pressure.converted(to: .hectopascals).value,
            uvIndex: current.uvIndex.value,
            precipitationChance: hourly.first?.precipitationChance ?? 0
        )
        if hourly.first?.date == currentHourStart {
            hourly[0] = observed
        } else {
            hourly.insert(observed, at: 0)
        }

        return WeatherSnapshot(
            fetchedAt: current.date,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            placeName: placeName,
            hours: hourly,
            days: days.forecast.map { day in
                WeatherSnapshot.Day(
                    date: day.date,
                    high: day.highTemperature.converted(to: .celsius).value,
                    low: day.lowTemperature.converted(to: .celsius).value,
                    symbolName: day.symbolName,
                    precipitationChance: day.precipitationChance,
                    uvIndex: day.uvIndex.value,
                    sunrise: day.sun.sunrise,
                    sunset: day.sun.sunset
                )
            }
        )
    }

    private static func placeName(for location: CLLocation) async -> String? {
        guard let request = MKReverseGeocodingRequest(location: location) else { return nil }
        let items = try? await request.mapItems
        return items?.first?.addressRepresentations?.cityName
    }

    private func save() {
        guard !isUsingSample else { return }
        if let snapshot, let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: Self.snapshotKey)
        } else {
            defaults.removeObject(forKey: Self.snapshotKey)
        }
    }

    #if DEBUG
    /// A fixed forecast so screenshots and UI tests can show the full weather tile
    /// on a simulator that isn't signed for WeatherKit. Never saved.
    private func loadSample(now: Date) {
        guard location == nil else { return }
        let hourStart = Calendar.current.dateInterval(of: .hour, for: now)?.start ?? now
        let dayStart = Calendar.current.startOfDay(for: now)
        location = CLLocation(latitude: 19.076, longitude: 72.8777)
        let temperatures: [Double] = [29, 30, 30, 29, 28, 27, 26, 26, 25, 25, 24, 24]
        let sample = WeatherSnapshot(
            fetchedAt: now, latitude: 19.076, longitude: 72.8777, placeName: "Mumbai",
            hours: temperatures.enumerated().map { index, temperature in
                WeatherSnapshot.Hour(
                    date: hourStart.addingTimeInterval(Double(index) * 3600), temperature: temperature,
                    symbolName: index < 3 ? "sun.max.fill" : "cloud.sun.fill", condition: index < 3 ? "Sunny" : "Partly Cloudy",
                    humidity: 0.68, pressure: 1012, uvIndex: 7, precipitationChance: 0.2
                )
            },
            days: [WeatherSnapshot.Day(
                date: dayStart, high: 32, low: 24, symbolName: "sun.max.fill", precipitationChance: 0.2, uvIndex: 9,
                sunrise: nil, sunset: nil
            )]
        )
        // The sample must never overwrite a real saved forecast.
        isUsingSample = true
        snapshot = sample
    }
    #endif
}
