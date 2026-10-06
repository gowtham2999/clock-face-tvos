import SwiftUI

enum AccentColorOption: String, CaseIterable, Identifiable {
    case white
    case black
    case green
    case yellow
    case blue

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .white: return .white
        case .black: return Color(white: 0.15)
        case .green: return Color(red: 0.55, green: 0.85, blue: 0.45)
        case .yellow: return Color(red: 0.98, green: 0.84, blue: 0.3)
        case .blue: return Color(red: 0.45, green: 0.65, blue: 0.98)
        }
    }
}
