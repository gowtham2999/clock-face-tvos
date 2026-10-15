import Foundation

struct GeoCoordinate: Equatable {
    var latitude: Double
    var longitude: Double

    /// A rough stand-in when location isn't available: longitude from the time
    /// zone's offset (15° per hour) and a mid-northern latitude.
    static func approximate(for timeZone: TimeZone, at date: Date = .now) -> GeoCoordinate {
        let standardOffset = Double(timeZone.secondsFromGMT(for: date)) - timeZone.daylightSavingTimeOffset(for: date)
        return GeoCoordinate(latitude: 35, longitude: standardOffset / 240)
    }
}

/// Sun position and event times using NOAA's solar position equations
/// (accurate to about a minute for dates in this century). Fully offline.
enum SolarCalculator {
    struct Position {
        /// Degrees above the horizon (geometric).
        let elevation: Double
        /// Degrees clockwise from north.
        let azimuth: Double
    }

    static func position(at date: Date, coordinate: GeoCoordinate) -> Position {
        let (declination, equationOfTime) = sunParameters(at: date)
        let minutesUTC = date.timeIntervalSince1970.truncatingRemainder(dividingBy: 86_400) / 60
        var trueSolarTime = (minutesUTC + equationOfTime + 4 * coordinate.longitude).truncatingRemainder(dividingBy: 1440)
        if trueSolarTime < 0 { trueSolarTime += 1440 }
        let hourAngle = trueSolarTime / 4 - 180

        let latitude = radians(coordinate.latitude)
        let decl = radians(declination)
        let cosZenith = clamp(sin(latitude) * sin(decl) + cos(latitude) * cos(decl) * cos(radians(hourAngle)))
        let zenith = acos(cosZenith)

        let azimuth: Double
        let denominator = cos(latitude) * sin(zenith)
        if abs(denominator) > 1e-9 {
            let base = degrees(acos(clamp((sin(latitude) * cos(zenith) - sin(decl)) / denominator)))
            azimuth = hourAngle > 0
                ? (base + 180).truncatingRemainder(dividingBy: 360)
                : (540 - base).truncatingRemainder(dividingBy: 360)
        } else {
            azimuth = coordinate.latitude > 0 ? 180 : 0
        }
        return Position(elevation: 90 - degrees(zenith), azimuth: azimuth)
    }

    /// Solar noon for the calendar day containing `date` in `timeZone`.
    static func solarNoon(on date: Date, coordinate: GeoCoordinate, timeZone: TimeZone) -> Date {
        var local = Calendar(identifier: .gregorian)
        local.timeZone = timeZone
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let day = local.dateComponents([.year, .month, .day], from: date)
        let utcMidnight = utc.date(from: day) ?? date

        // Two passes: the equation of time barely changes within a day.
        var noon = utcMidnight.addingTimeInterval((720 - 4 * coordinate.longitude) * 60)
        for _ in 0..<2 {
            let equationOfTime = sunParameters(at: noon).equationOfTime
            noon = utcMidnight.addingTimeInterval((720 - 4 * coordinate.longitude - equationOfTime) * 60)
        }
        return noon
    }

    /// Every event of the solar day centred on that calendar day's solar noon.
    /// Events the sun never reaches (e.g. polar summer nights) are left out.
    static func events(on date: Date, coordinate: GeoCoordinate, timeZone: TimeZone) -> [SolarEventTime] {
        let noon = solarNoon(on: date, coordinate: coordinate, timeZone: timeZone)
        let nadir = noon.addingTimeInterval(-12 * 3600)
        let nextNadir = noon.addingTimeInterval(12 * 3600)

        var results = [SolarEventTime(event: .nadir, date: nadir), SolarEventTime(event: .solarNoon, date: noon)]
        for event in SolarEvent.allCases {
            guard let threshold = event.elevation else { continue }
            let window = event.isMorning ? (nadir, noon) : (noon, nextNadir)
            if let time = crossing(of: threshold, from: window.0, to: window.1, rising: event.isMorning, coordinate: coordinate) {
                results.append(SolarEventTime(event: event, date: time))
            }
        }
        return results.sorted { ($0.date, $0.event) < ($1.date, $1.event) }
    }

    /// Events for the day before, the day of and the day after `date`, in order —
    /// enough to find what came last and what comes next at any moment.
    static func eventTimeline(around date: Date, coordinate: GeoCoordinate, timeZone: TimeZone) -> [SolarEventTime] {
        [-1, 0, 1].flatMap { offset in
            events(on: date.addingTimeInterval(Double(offset) * 86_400), coordinate: coordinate, timeZone: timeZone)
        }
        .sorted { ($0.date, $0.event) < ($1.date, $1.event) }
    }

    /// Apparent elevation thresholds already include refraction, so compare them
    /// against geometric elevation directly (the convention used for sunrise at −0.833°).
    private static func crossing(of threshold: Double, from start: Date, to end: Date, rising: Bool, coordinate: GeoCoordinate) -> Date? {
        func elevation(_ date: Date) -> Double { position(at: date, coordinate: coordinate).elevation }

        let startElevation = elevation(start)
        let endElevation = elevation(end)
        let brackets = rising
            ? startElevation < threshold && endElevation >= threshold
            : startElevation >= threshold && endElevation < threshold
        guard brackets else { return nil }

        var low = start
        var high = end
        for _ in 0..<26 {
            let mid = low.addingTimeInterval(high.timeIntervalSince(low) / 2)
            let isAbove = elevation(mid) >= threshold
            if isAbove == rising { high = mid } else { low = mid }
        }
        return low.addingTimeInterval(high.timeIntervalSince(low) / 2)
    }

    // MARK: - NOAA sun parameters

    private static func sunParameters(at date: Date) -> (declination: Double, equationOfTime: Double) {
        let julianDay = date.timeIntervalSince1970 / 86_400 + 2_440_587.5
        let t = (julianDay - 2_451_545) / 36_525

        let meanLongitude = (280.46646 + t * (36000.76983 + t * 0.0003032)).truncatingRemainder(dividingBy: 360)
        let meanAnomaly = 357.52911 + t * (35999.05029 - 0.0001537 * t)
        let eccentricity = 0.016708634 - t * (0.000042037 + 0.0000001267 * t)
        let center = sin(radians(meanAnomaly)) * (1.914602 - t * (0.004817 + 0.000014 * t))
            + sin(radians(2 * meanAnomaly)) * (0.019993 - 0.000101 * t)
            + sin(radians(3 * meanAnomaly)) * 0.000289
        let omega = 125.04 - 1934.136 * t
        let apparentLongitude = meanLongitude + center - 0.00569 - 0.00478 * sin(radians(omega))
        let meanObliquity = 23 + (26 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60) / 60
        let obliquity = meanObliquity + 0.00256 * cos(radians(omega))

        let declination = degrees(asin(sin(radians(obliquity)) * sin(radians(apparentLongitude))))

        let y = pow(tan(radians(obliquity) / 2), 2)
        let l0 = radians(meanLongitude)
        let m = radians(meanAnomaly)
        let equationOfTime = 4 * degrees(
            y * sin(2 * l0)
            - 2 * eccentricity * sin(m)
            + 4 * eccentricity * y * sin(m) * cos(2 * l0)
            - 0.5 * y * y * sin(4 * l0)
            - 1.25 * eccentricity * eccentricity * sin(2 * m)
        )
        return (declination, equationOfTime)
    }

    private static func radians(_ degrees: Double) -> Double { degrees * .pi / 180 }
    private static func degrees(_ radians: Double) -> Double { radians * 180 / .pi }
    private static func clamp(_ value: Double) -> Double { min(1, max(-1, value)) }
}
