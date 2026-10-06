import Foundation

enum ChimeSource: String, CaseIterable, Identifiable {
    case mute
    case system
    case watch

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mute: return "Mute"
        case .system: return "System"
        case .watch: return "Watch"
        }
    }
}
