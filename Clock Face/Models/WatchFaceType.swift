import Foundation

enum WatchFaceType: String, CaseIterable, Identifiable {
    case analogClassic
    case flip

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .analogClassic: return "Classic"
        case .flip: return "Flip"
        }
    }
}
