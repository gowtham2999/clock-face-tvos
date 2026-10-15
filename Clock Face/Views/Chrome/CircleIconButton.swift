import SwiftUI

/// A round, icon-only chrome button (e.g. the settings gear).
struct CircleIconButton: View {
    let systemName: String
    let accessibilityLabel: String
    var isActive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
        }
        .buttonStyle(CircleChromeButtonStyle(isActive: isActive))
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct CircleChromeButtonStyle: ButtonStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        CircleChromeLabel(configuration: configuration, isActive: isActive)
    }
}

private struct CircleChromeLabel: View {
    let configuration: ButtonStyleConfiguration
    let isActive: Bool
    @Environment(\.isFocused) private var isFocused
    @Environment(\.chromeActivity) private var chromeActivity
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .font(.system(size: 26, weight: .semibold))
            .foregroundStyle(isFocused ? Color.inkInverse : Color.ink)
            .frame(width: 72, height: 72)
            .background {
                if isFocused {
                    Circle().fill(Color.ink)
                } else {
                    Circle().fill(.ultraThinMaterial)
                        .overlay(Circle().fill(Color.ink.opacity(isActive ? 0.22 : 0)))
                }
            }
            .opacity(isEnabled ? 1 : 0.35)
            .scaleEffect(isFocused ? 1.1 : 1)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.15), value: isFocused)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: isFocused) { chromeActivity() }
    }
}
