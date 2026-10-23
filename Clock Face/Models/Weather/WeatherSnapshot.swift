import Foundation

/// One WeatherKit fetch, saved on the TV and read hour by hour until the next one.
/// A single request returns an hourly forecast for the next day, so the display can
/// stay current for hours without asking WeatherKit again.
nonisolated struct WeatherSnapshot: Codable, Equatable {
    var fetchedAt: Date
    var latitude: Double
    var longitude: Double
    var placeName: String?
    /// Hourly conditions, oldest first. The hour of the fetch holds the observed
    /// current conditions rather than the forecast.
    var hours: [Hour]
    var days: [Day]

    struct Hour: Codable, Equatable {
        var date: Date
        var temperature: Double // °C
        var symbolName: String
        var condition: String
        var humidity: Double // 0…1
        var pressure: Double // hPa
        var uvIndex: Int
        var precipitationChance: Double // 0…1
    }

    struct Day: Codable, Equatable {
        var date: Date
        var high: Double // °C
        var low: Double // °C
        var symbolName: String
        var precipitationChance: Double // 0…1
        var uvIndex: Int // the day's peak
        var sunrise: Date?
        var sunset: Date?
    }

    /// How long a fetch is used before asking WeatherKit again.
    static let refreshInterval: TimeInterval = 6 * 3600
    /// Distance the TV can move before the saved forecast no longer applies.
    static let maximumDistance: Double = 25_000

    /// The hour containing `date`, or nil when the forecast doesn't reach it.
    func hour(at date: Date) -> Hour? {
        hours.last { $0.date <= date && date < $0.date.addingTimeInterval(3600) }
    }

    /// The forecast day containing `date`.
    func day(at date: Date, calendar: Calendar = .current) -> Day? {
        days.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    /// True once the fetch is six hours old, or sooner if the hourly forecast is about to run out.
    func needsRefresh(at date: Date) -> Bool {
        date.timeIntervalSince(fetchedAt) >= Self.refreshInterval
            || hour(at: date.addingTimeInterval(3600)) == nil
    }

    /// Whether this forecast was fetched within `maximumDistance` of the given point.
    func isNear(latitude: Double, longitude: Double) -> Bool {
        // Equirectangular approximation: plenty accurate at tens of kilometres.
        let meanLatitude = (latitude + self.latitude) / 2 * .pi / 180
        let x = (longitude - self.longitude) * .pi / 180 * cos(meanLatitude)
        let y = (latitude - self.latitude) * .pi / 180
        return (x * x + y * y).squareRoot() * 6_371_000 <= Self.maximumDistance
    }
}

/// The UV index bands used on weather reports.
nonisolated enum UVLevel: String {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case veryHigh = "Very High"
    case extreme = "Extreme"

    init(index: Int) {
        switch index {
        case ..<3: self = .low
        case 3..<6: self = .moderate
        case 6..<8: self = .high
        case 8..<11: self = .veryHigh
        default: self = .extreme
        }
    }
}
