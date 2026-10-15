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
        }
    }

    /// Faces that show weather or follow the sun; location is only requested once one is on screen.
    var usesLocation: Bool {
        self == .essential || self == .station || self == .sky
    }

    /// Faces whose look changes through the day, which get a "Play a Day" preview.
    var followsTheSun: Bool {
        self == .sky || self == .daylight
    }

    /// Shown on the detail screen for faces without a colour palette.
    var customizationNote: String? {
        switch self {
        case .sky: return "Colours follow the sun at your location, from night through every twilight to midday."
        case .flip: return "Follows the Light and Dark theme in Settings."
        default: return nil
        }
    }

    var collection: FaceCollection {
        switch self {
        case .analogClassic, .essential, .station: return .analog
        case .sky, .tint, .daylight: return .colourAndLight
        case .flip: return .digital
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
        case .sky, .flip:
            return []
        }
    }
}

enum FaceCollection: String, CaseIterable, Identifiable {
    case analog
    case colourAndLight
    case digital

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .analog: return "Analog"
        case .colourAndLight: return "Colour & Light"
        case .digital: return "Digital"
        }
    }

    var faces: [WatchFaceType] {
        WatchFaceType.allCases.filter { $0.collection == self }
    }
}
