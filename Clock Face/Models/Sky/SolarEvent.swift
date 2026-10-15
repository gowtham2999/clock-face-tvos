import Foundation

/// The day's named moments, each defined by the sun's elevation (degrees above the
/// horizon, apparent, including refraction) while rising or setting.
/// Order is chronological through one solar day, nadir to astronomical dusk.
enum SolarEvent: Int, CaseIterable, Comparable {
    case nadir
    case astronomicalDawn
    case amateurDawn
    case nauticalDawn
    case blueHourStartsMorning
    case civilDawn
    case blueHourEndsMorning
    case goldenHourStartsMorning
    case sunriseStarts
    case sunriseEnds
    case goldenHourEndsMorning
    case solarNoon
    case goldenHourStartsEvening
    case sunsetStarts
    case sunsetEnds
    case goldenHourEndsEvening
    case blueHourStartsEvening
    case civilDusk
    case blueHourEndsEvening
    case nauticalDusk
    case amateurDusk
    case astronomicalDusk

    static func < (lhs: SolarEvent, rhs: SolarEvent) -> Bool { lhs.rawValue < rhs.rawValue }

    /// Nil for nadir and solar noon, which are the lowest and highest points rather than thresholds.
    var elevation: Double? {
        switch self {
        case .nadir, .solarNoon: return nil
        case .astronomicalDawn, .astronomicalDusk: return -18
        case .amateurDawn, .amateurDusk: return -15
        case .nauticalDawn, .nauticalDusk: return -12
        case .blueHourStartsMorning, .blueHourEndsEvening: return -8
        case .civilDawn, .civilDusk: return -6
        case .blueHourEndsMorning, .goldenHourStartsMorning, .goldenHourEndsEvening, .blueHourStartsEvening: return -4
        // Upper limb on the horizon (−0.833°) and lower limb on the horizon (−0.3°).
        case .sunriseStarts, .sunsetEnds: return -0.833
        case .sunriseEnds, .sunsetStarts: return -0.3
        case .goldenHourEndsMorning, .goldenHourStartsEvening: return 6
        }
    }

    var isMorning: Bool { self < .solarNoon }

    var displayName: String {
        switch self {
        case .nadir: return "Nadir"
        case .astronomicalDawn: return "Astronomical Dawn"
        case .amateurDawn: return "Amateur Dawn"
        case .nauticalDawn: return "Nautical Dawn"
        case .blueHourStartsMorning, .blueHourStartsEvening: return "Blue Hour Starts"
        case .civilDawn: return "Civil Dawn"
        case .blueHourEndsMorning, .blueHourEndsEvening: return "Blue Hour Ends"
        case .goldenHourStartsMorning, .goldenHourStartsEvening: return "Golden Hour Starts"
        case .sunriseStarts: return "Sunrise Starts"
        case .sunriseEnds: return "Sunrise Ends"
        case .goldenHourEndsMorning, .goldenHourEndsEvening: return "Golden Hour Ends"
        case .solarNoon: return "Solar Noon"
        case .sunsetStarts: return "Sunset Starts"
        case .sunsetEnds: return "Sunset Ends"
        case .civilDusk: return "Civil Dusk"
        case .nauticalDusk: return "Nautical Dusk"
        case .amateurDusk: return "Amateur Dusk"
        case .astronomicalDusk: return "Astronomical Dusk"
        }
    }

    /// The name of the stretch of sky for a given sun elevation.
    static func phaseName(elevation: Double, isRising: Bool) -> String {
        switch elevation {
        case 6...: return "Daylight"
        case -0.3..<6: return "Golden Hour"
        case -0.833 ..< -0.3: return isRising ? "Sunrise" : "Sunset"
        case -4 ..< -0.833: return "Golden Hour"
        case -8 ..< -4: return "Blue Hour"
        case -12 ..< -8: return "Nautical Twilight"
        case -18 ..< -12: return "Astronomical Twilight"
        default: return "Night"
        }
    }
}

struct SolarEventTime: Equatable {
    let event: SolarEvent
    let date: Date
}
