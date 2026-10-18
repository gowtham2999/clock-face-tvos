import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case clock
    case faces
    case sports
    case world

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .home: return "Home"
        case .clock: return "Clock"
        case .faces: return "Faces"
        case .sports: return "Sports"
        case .world: return "World"
        }
    }

    /// Screens meant to be left running, where the top bar hides itself when idle.
    var isAmbient: Bool { self == .home || self == .clock }
}
