import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case dark
    case light

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dark: return "Dark"
        case .light: return "Light"
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .dark: return .dark
        case .light: return .light
        }
    }

    var background: Color {
        switch self {
        case .dark: return Color(white: 0.085)
        case .light: return .white
        }
    }

    /// Fill for raised panels such as the flip clock's digit boxes.
    var surface: Color {
        switch self {
        case .dark: return Color(white: 0.12)
        case .light: return Color(white: 0.94)
        }
    }
}

extension Color {
    /// The main foreground color: white in the dark theme, black in the light theme.
    static let ink = Color(uiColor: UIColor { $0.userInterfaceStyle == .light ? .black : .white })
    /// The opposite of `ink`, for content drawn on top of an `ink` fill.
    static let inkInverse = Color(uiColor: UIColor { $0.userInterfaceStyle == .light ? .white : .black })
}
