import SwiftUI

/// A colour in OKLab, a perceptual colour space: blending two colours here moves
/// evenly in perceived lightness and hue, so twilight blue → dawn rose passes through
/// natural in-between tones instead of the muddy greys a plain RGB blend gives.
struct SkyColor: Equatable {
    var l: Double
    var a: Double
    var b: Double

    init(hex: UInt32) {
        func linear(_ channel: UInt32) -> Double {
            let value = Double(channel) / 255
            return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        let r = linear((hex >> 16) & 0xFF), g = linear((hex >> 8) & 0xFF), bl = linear(hex & 0xFF)
        let lms = (
            cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * bl),
            cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * bl),
            cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * bl)
        )
        l = 0.2104542553 * lms.0 + 0.7936177850 * lms.1 - 0.0040720468 * lms.2
        a = 1.9779984951 * lms.0 - 2.4285922050 * lms.1 + 0.4505937099 * lms.2
        b = 0.0259040371 * lms.0 + 0.7827717662 * lms.1 - 0.8086757660 * lms.2
    }

    private init(l: Double, a: Double, b: Double) {
        self.l = l
        self.a = a
        self.b = b
    }

    /// Same hue, lifted to at least `minimum` perceived lightness.
    func withLightness(atLeast minimum: Double) -> SkyColor {
        SkyColor(l: max(l, minimum), a: a, b: b)
    }

    func mixed(with other: SkyColor, by t: Double) -> SkyColor {
        SkyColor(l: l + (other.l - l) * t, a: a + (other.a - a) * t, b: b + (other.b - b) * t)
    }

    var color: Color {
        let l_ = l + 0.3963377774 * a + 0.2158037573 * b
        let m_ = l - 0.1055613458 * a - 0.0638541728 * b
        let s_ = l - 0.0894841775 * a - 1.2914855480 * b
        let (lc, mc, sc) = (l_ * l_ * l_, m_ * m_ * m_, s_ * s_ * s_)
        func encode(_ value: Double) -> Double {
            let clamped = min(1, max(0, value))
            return clamped <= 0.0031308 ? clamped * 12.92 : 1.055 * pow(clamped, 1 / 2.4) - 0.055
        }
        return Color(
            red: encode(4.0767416621 * lc - 3.3077115913 * mc + 0.2309699292 * sc),
            green: encode(-1.2684380046 * lc + 2.6097574011 * mc - 0.3413193965 * sc),
            blue: encode(-0.0041960863 * lc - 0.7034169117 * mc + 1.7076152328 * sc)
        )
    }
}

/// The sky's colours at any sun elevation, from deep night to high noon.
/// Keyframes sit on the same elevations as the named solar events, with separate
/// horizon colours for dawn (cooler rose and lavender) and dusk (warmer amber and coral).
enum SkyPalette {
    struct Sky {
        let zenith: SkyColor
        let middle: SkyColor
        let horizon: SkyColor

        /// Five stops, top to bottom, eased toward the horizon where the colour lives.
        var gradient: Gradient {
            Gradient(stops: [
                .init(color: zenith.color, location: 0),
                .init(color: zenith.mixed(with: middle, by: 0.55).color, location: 0.3),
                .init(color: middle.color, location: 0.58),
                .init(color: middle.mixed(with: horizon, by: 0.55).color, location: 0.8),
                .init(color: horizon.color, location: 1),
            ])
        }

        /// A single representative colour for the day strip. Night is lifted to a deep
        /// navy so the strip stays visible at night and isn't a harsh black bar by day.
        var summary: SkyColor { middle.mixed(with: horizon, by: 0.45).withLightness(atLeast: 0.34) }
    }

    private struct Keyframe {
        let elevation: Double
        let zenith: UInt32
        let middle: UInt32
        let dawnHorizon: UInt32
        let duskHorizon: UInt32
    }

    private static let keyframes: [Keyframe] = [
        Keyframe(elevation: -24, zenith: 0x02030A, middle: 0x050816, dawnHorizon: 0x0A0F24, duskHorizon: 0x0A0F24),     // night
        Keyframe(elevation: -18, zenith: 0x03040F, middle: 0x070B1F, dawnHorizon: 0x111737, duskHorizon: 0x141334),     // astronomical
        Keyframe(elevation: -15, zenith: 0x040719, middle: 0x0B1131, dawnHorizon: 0x1D2150, duskHorizon: 0x241B49),     // amateur
        Keyframe(elevation: -12, zenith: 0x060C27, middle: 0x141E4C, dawnHorizon: 0x353A72, duskHorizon: 0x3E2F68),     // nautical
        Keyframe(elevation: -8, zenith: 0x0B1742, middle: 0x243B82, dawnHorizon: 0x5D62AA, duskHorizon: 0x6C5096),      // blue hour edge
        Keyframe(elevation: -6, zenith: 0x10215A, middle: 0x31519C, dawnHorizon: 0x9C88BA, duskHorizon: 0xB27A9E),      // civil
        Keyframe(elevation: -4, zenith: 0x173070, middle: 0x4F6BAF, dawnHorizon: 0xE6A28E, duskHorizon: 0xE5846F),      // golden begins
        Keyframe(elevation: -0.833, zenith: 0x22468A, middle: 0x7C90C5, dawnHorizon: 0xFFBA80, duskHorizon: 0xFF9058), // sunrise / sunset
        Keyframe(elevation: 3, zenith: 0x2C5A9C, middle: 0x92A8D2, dawnHorizon: 0xFFD49C, duskHorizon: 0xFFB173),
        Keyframe(elevation: 6, zenith: 0x3467AC, middle: 0x92B5DD, dawnHorizon: 0xF3DEBA, duskHorizon: 0xF6CB98),      // golden ends
        Keyframe(elevation: 15, zenith: 0x2E66B6, middle: 0x76A7DF, dawnHorizon: 0xC8E1F5, duskHorizon: 0xCDE0F2),
        Keyframe(elevation: 40, zenith: 0x205FBF, middle: 0x5B9AE5, dawnHorizon: 0xAED6F6, duskHorizon: 0xAED6F6),     // high sun
    ]

    static func sky(elevation: Double, isRising: Bool) -> Sky {
        let clamped = min(max(elevation, keyframes.first!.elevation), keyframes.last!.elevation)
        let upperIndex = keyframes.firstIndex { $0.elevation >= clamped } ?? keyframes.count - 1
        let upper = keyframes[upperIndex]
        let lower = keyframes[max(0, upperIndex - 1)]

        let span = upper.elevation - lower.elevation
        let raw = span > 0 ? (clamped - lower.elevation) / span : 0
        // Smoothstep removes the visible "corner" where one keyframe hands over to the next.
        let t = raw * raw * (3 - 2 * raw)

        func blend(_ from: UInt32, _ to: UInt32) -> SkyColor {
            SkyColor(hex: from).mixed(with: SkyColor(hex: to), by: t)
        }
        return Sky(
            zenith: blend(lower.zenith, upper.zenith),
            middle: blend(lower.middle, upper.middle),
            horizon: isRising
                ? blend(lower.dawnHorizon, upper.dawnHorizon)
                : blend(lower.duskHorizon, upper.duskHorizon)
        )
    }
}
