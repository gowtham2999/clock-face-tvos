import Foundation

enum Sport: String, CaseIterable, Identifiable {
    case formula1
    case motoGP
    case endurance
    case football

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .formula1: return "Formula 1"
        case .motoGP: return "MotoGP"
        case .endurance: return "Endurance"
        case .football: return "Football"
        }
    }

    /// Generic symbols only — official series logos are trademarks.
    var symbolName: String {
        switch self {
        case .formula1: return "flag.checkered"
        case .motoGP: return "motorcycle"
        case .endurance: return "stopwatch"
        case .football: return "soccerball"
        }
    }

    var isAvailable: Bool { self == .formula1 }
}
