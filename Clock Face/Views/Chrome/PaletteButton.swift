import SwiftUI

struct PaletteButton: View {
    @Binding var isSettingsOpen: Bool

    var body: some View {
        Button {
            isSettingsOpen.toggle()
        } label: {
            Image(systemName: "paintpalette.fill")
        }
        .accessibilityLabel("Settings")
        .buttonStyle(CircleChromeButtonStyle(isActive: isSettingsOpen))
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
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .font(.system(size: 26, weight: .semibold))
            .foregroundStyle(isFocused ? Color.inkInverse : Color.ink)
            .frame(width: 72, height: 72)
            .background(Circle().fill(background))
            .opacity(isEnabled ? 1 : 0.35)
            .scaleEffect(isFocused ? 1.1 : 1)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.15), value: isFocused)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }

    private var background: Color {
        if isFocused { return .ink }
        return isActive ? Color.ink.opacity(0.22) : Color.ink.opacity(0.08)
    }
}
