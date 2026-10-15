import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case clock
    case faces
    case sports
    case world

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .clock: return "Clock"
        case .faces: return "Faces"
        case .sports: return "Sports"
        case .world: return "World"
        }
    }
}
