import SwiftUI

/// Every face in the app. `allCases` order is the order faces appear in the gallery.
/// Raw values are persisted, so never rename an existing one.
enum WatchFaceType: String, CaseIterable, Identifiable {
    case analogClassic
    case essential
    case station
    case sky
    case tint
    case daylight
    case flip
    case circle
    case bold
    case minimal
    case serifModern
    case dualTime
    case solarArc
    case calendar
    case weather
    case world
    case orbit

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .analogClassic: return "Classic"
        case .essential: return "Essential"
        case .station: return "Station"
        case .sky: return "Sky"
        case .tint: return "Tint"
        case .daylight: return "Daylight"
        case .flip: return "Flip"
        case .circle: return "Circle"
        case .bold: return "Bold"
        case .minimal: return "Minimal"
        case .serifModern: return "Serif Modern"
        case .dualTime: return "Dual Time"
        case .solarArc: return "Solar Arc"
        case .calendar: return "Calendar"
        case .weather: return "Weather"
        case .world: return "World"
        case .orbit: return "Orbit"
        }
    }

    var summary: String {
        switch self {
        case .analogClassic:
            return "Oversized numerals at the four quarters, with chunky hands and an accent second hand."
        case .essential:
            return "A clean dial with fine minute marks, plus the date, weather, sun times and a second city in the corners."
        case .station:
            return "Classic edge-to-edge hour marks with four small dials for the date, seconds, weather and a second city."
        case .sky:
            return "A digital clock on a sky that follows the sun — through every twilight, blue hour and golden hour."
        case .tint:
            return "A bold, full-screen colour with simple hands and the date above."
        case .daylight:
            return "A luminous dial whose light follows the sun across the day."
        case .flip:
            return "Big hours and minutes in two tiles, inspired by desk flip clocks."
        case .circle:
            return "A fine-ticked dial where the seconds sweep round as a glowing trail."
        case .bold:
            return "Heavy stacked hours and minutes, set large like a poster."
        case .minimal:
            return "Just the time in a single thin line, with the date beneath."
        case .serifModern:
            return "Elegant high-contrast serif numerals, staggered like a magazine cover."
        case .dualTime:
            return "Your time, stacked large, beside the time in four other cities."
        case .solarArc:
            return "The sun travels an arc over the mountains, from sunrise to sunset."
        case .calendar:
            return "Today's date in large type next to the month, with the time."
        case .weather:
            return "Current conditions and today's high and low beside a clean dial."
        case .world:
            return "A dotted world map lit by the sun, with the time in your cities."
        case .orbit:
            return "The planets on their orbits around the Sun, in today's real positions."
        }
    }

    /// Faces that show weather or follow the sun; location is only requested once one is on screen.
    var usesLocation: Bool {
        switch self {
        case .essential, .station, .sky, .solarArc, .weather: return true
        default: return false
        }
    }

    /// Faces whose look changes through the day, which get a "Play a Day" preview.
    var followsTheSun: Bool {
        switch self {
        case .sky, .daylight, .solarArc, .world: return true
        default: return false
        }
    }

    /// Shown on the detail screen for faces without a colour palette.
    var customizationNote: String? {
        switch self {
        case .sky: return "Colours follow the sun at your location, from night through every twilight to midday."
        case .flip: return "Follows the Light and Dark theme in Settings."
        case .solarArc: return "The sky and the sun's place on the arc follow the real sun at your location."
        case .orbit: return "Planet positions are calculated for today, so the scene slowly changes through the year."
        default: return nil
        }
    }

    var collection: FaceCollection {
        switch self {
        case .analogClassic, .essential, .station, .circle: return .analog
        case .flip, .bold, .minimal, .serifModern, .dualTime: return .digital
        case .sky, .tint, .daylight, .solarArc: return .colourAndLight
        case .calendar, .weather, .world: return .information
        case .orbit: return .space
        }
    }

    /// Colour choices offered when customising the face. Empty when the face
    /// only follows the app's light/dark theme.
    var palette: [FaceColor] {
        switch self {
        case .analogClassic:
            return [
                FaceColor(id: "red", name: "Red", primary: Color(hex: 0xE5484D)),
                FaceColor(id: "yellow", name: "Yellow", primary: Color(hex: 0xFAD64D)),
                FaceColor(id: "white", name: "White", primary: .white),
                FaceColor(id: "green", name: "Green", primary: Color(hex: 0x8CD973)),
                FaceColor(id: "blue", name: "Blue", primary: Color(hex: 0x73A6FA)),
            ]
        case .essential:
            return [
                FaceColor(id: "cream", name: "Cream", primary: Color(hex: 0xF2E6C9)),
                FaceColor(id: "orange", name: "Orange", primary: Color(hex: 0xFF9F0A)),
                FaceColor(id: "white", name: "White", primary: .white),
                FaceColor(id: "sky", name: "Sky", primary: Color(hex: 0x64D2FF)),
            ]
        case .station:
            // secondary = ink colour for marks and hands
            return [
                FaceColor(id: "gold", name: "Gold", primary: Color(hex: 0x8F7A4A), secondary: Color(hex: 0x111111)),
                FaceColor(id: "black", name: "Black", primary: Color(hex: 0x0E0E0E), secondary: Color(hex: 0xEDE6D6)),
                FaceColor(id: "navy", name: "Navy", primary: Color(hex: 0x1C2840), secondary: Color(hex: 0xE9E3D5)),
                FaceColor(id: "ivory", name: "Ivory", primary: Color(hex: 0xE9E3D5), secondary: Color(hex: 0x1A1A1A)),
            ]
        case .tint:
            // secondary = second hand colour
            return [
                FaceColor(id: "ochre", name: "Ochre", primary: Color(hex: 0x8F7A4A), secondary: Color(hex: 0xF5A243)),
                FaceColor(id: "olive", name: "Olive", primary: Color(hex: 0x6B7451), secondary: Color(hex: 0xF5A243)),
                FaceColor(id: "clay", name: "Clay", primary: Color(hex: 0x9E5A43), secondary: Color(hex: 0xF7D9A8)),
                FaceColor(id: "slate", name: "Slate", primary: Color(hex: 0x4D6A8C), secondary: Color(hex: 0xF5A243)),
                FaceColor(id: "plum", name: "Plum", primary: Color(hex: 0x6A4C6B), secondary: Color(hex: 0xF5A243)),
                FaceColor(id: "graphite", name: "Graphite", primary: Color(hex: 0x3A3A3C), secondary: Color(hex: 0xF5A243)),
            ]
        case .daylight:
            // primary = deep base, secondary = light colour
            return [
                FaceColor(id: "blue", name: "Blue", primary: Color(hex: 0x0B1D36), secondary: Color(hex: 0x9CCBF5)),
                FaceColor(id: "graphite", name: "Graphite", primary: Color(hex: 0x121417), secondary: Color(hex: 0xC9D1D9)),
                FaceColor(id: "dawn", name: "Dawn", primary: Color(hex: 0x2A1631), secondary: Color(hex: 0xF2B38A)),
            ]
        case .circle, .weather:
            // primary = accent (second hand, seconds trail)
            return [
                FaceColor(id: "orange", name: "Orange", primary: Color(hex: 0xFF9F0A)),
                FaceColor(id: "red", name: "Red", primary: Color(hex: 0xFF453A)),
                FaceColor(id: "mint", name: "Mint", primary: Color(hex: 0x66D4CF)),
                FaceColor(id: "blue", name: "Blue", primary: Color(hex: 0x64A8FF)),
            ]
        case .bold, .minimal, .dualTime:
            // primary = type colour
            return [
                FaceColor(id: "cream", name: "Cream", primary: Color(hex: 0xEDE6DA)),
                FaceColor(id: "white", name: "White", primary: .white),
                FaceColor(id: "orange", name: "Orange", primary: Color(hex: 0xFF9F0A)),
                FaceColor(id: "mint", name: "Mint", primary: Color(hex: 0x8CE0C4)),
                FaceColor(id: "rose", name: "Rose", primary: Color(hex: 0xFF8FA3)),
            ]
        case .serifModern:
            // primary = numeral colour
            return [
                FaceColor(id: "ivory", name: "Ivory", primary: Color(hex: 0xF3ECDF)),
                FaceColor(id: "white", name: "White", primary: .white),
                FaceColor(id: "gold", name: "Gold", primary: Color(hex: 0xD9B77E)),
                FaceColor(id: "rose", name: "Rose", primary: Color(hex: 0xE8B4A8)),
            ]
        case .calendar, .world:
            // primary = accent (today, city dots)
            return [
                FaceColor(id: "amber", name: "Amber", primary: Color(hex: 0xF5A243)),
                FaceColor(id: "red", name: "Red", primary: Color(hex: 0xFF453A)),
                FaceColor(id: "teal", name: "Teal", primary: Color(hex: 0x40C8E0)),
                FaceColor(id: "green", name: "Green", primary: Color(hex: 0x6CD67E)),
            ]
        case .sky, .flip, .solarArc, .orbit:
            return []
        }
    }
}

enum FaceCollection: String, CaseIterable, Identifiable {
    case analog
    case digital
    case colourAndLight
    case information
    case space

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .analog: return "Analog"
        case .colourAndLight: return "Colour & Light"
        case .digital: return "Digital"
        case .information: return "Information"
        case .space: return "Space"
        }
    }

    var faces: [WatchFaceType] {
        WatchFaceType.allCases.filter { $0.collection == self }
    }
}
