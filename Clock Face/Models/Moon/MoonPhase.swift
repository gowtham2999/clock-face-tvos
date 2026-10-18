import Foundation

/// The Moon's phase at a moment, from Meeus's low-precision phase-angle formula
/// (Astronomical Algorithms, ch. 48): accurate to well under 1% illumination,
/// computed on device with no network.
struct MoonPhase: Equatable {
    /// Sun–Moon elongation in degrees, 0…360: 0 new, 90 first quarter, 180 full, 270 last quarter.
    let elongation: Double
    /// Illuminated fraction of the disc, 0…1.
    let illumination: Double

    var isWaxing: Bool { elongation < 180 }

    enum Name: String {
        case newMoon = "New Moon"
        case waxingCrescent = "Waxing Crescent"
        case firstQuarter = "First Quarter"
        case waxingGibbous = "Waxing Gibbous"
        case fullMoon = "Full Moon"
        case waningGibbous = "Waning Gibbous"
        case lastQuarter = "Last Quarter"
        case waningCrescent = "Waning Crescent"
    }

    /// The named phases (new, quarters, full) cover about a day either side of the exact moment.
    var name: Name {
        switch elongation {
        case ..<6, 354...: return .newMoon
        case ..<84: return .waxingCrescent
        case ..<96: return .firstQuarter
        case ..<174: return .waxingGibbous
        case ..<186: return .fullMoon
        case ..<264: return .waningGibbous
        case ..<276: return .lastQuarter
        default: return .waningCrescent
        }
    }

    init(at date: Date) {
        let julianDay = date.timeIntervalSince1970 / 86_400 + 2_440_587.5
        let t = (julianDay - 2_451_545) / 36_525

        func normalized(_ degrees: Double) -> Double {
            let value = degrees.truncatingRemainder(dividingBy: 360)
            return value < 0 ? value + 360 : value
        }
        func sin(_ degrees: Double) -> Double { Foundation.sin(degrees * .pi / 180) }

        let d = normalized(297.8501921 + 445_267.1114034 * t)   // mean elongation
        let m = normalized(357.5291092 + 35_999.0502909 * t)    // Sun's mean anomaly
        let mPrime = normalized(134.9633964 + 477_198.8675055 * t) // Moon's mean anomaly

        let phaseAngle = 180 - d
            - 6.289 * sin(mPrime)
            + 2.100 * sin(m)
            - 1.274 * sin(2 * d - mPrime)
            - 0.658 * sin(2 * d)
            - 0.214 * sin(2 * mPrime)
            - 0.110 * sin(d)

        illumination = (1 + cos(phaseAngle * .pi / 180)) / 2
        elongation = normalized(180 - phaseAngle)
    }

    /// The next moment after `date` when the Moon is full (or new), to within a minute.
    static func next(_ target: Name, after date: Date) -> Date? {
        let targetElongation: Double = target == .fullMoon ? 180 : 0
        // Signed distance still to travel to the target, in degrees (0…360).
        func remaining(_ moment: Date) -> Double {
            let value = (targetElongation - MoonPhase(at: moment).elongation).truncatingRemainder(dividingBy: 360)
            return value < 0 ? value + 360 : value
        }

        // Step in 6-hour hops until the target is passed (remaining wraps from ~0 to ~360).
        var low = date
        var previous = remaining(low)
        for _ in 0..<(31 * 4) {
            let high = low.addingTimeInterval(6 * 3600)
            let current = remaining(high)
            if current > previous {
                var a = low, b = high
                while b.timeIntervalSince(a) > 60 {
                    let mid = a.addingTimeInterval(b.timeIntervalSince(a) / 2)
                    if remaining(mid) > remaining(a) { b = mid } else { a = mid }
                }
                return b
            }
            low = high
            previous = current
        }
        return nil
    }
}
