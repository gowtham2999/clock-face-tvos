import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case watch
    case focus
    case worldTime

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .watch: return "Watch"
        case .focus: return "Focus"
        case .worldTime: return "World Time"
        }
    }
}
