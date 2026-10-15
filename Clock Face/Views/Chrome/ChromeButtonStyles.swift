import SwiftUI

extension Color {
    /// Accent for motorsport screens and reminders.
    static let racingRed = Color(hex: 0xE5383B)
}

/// A full-width row in a glass sidebar list.
struct SidebarRowButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        SidebarRowLabel(configuration: configuration, isSelected: isSelected)
    }
}

private struct SidebarRowLabel: View {
    let configuration: ButtonStyleConfiguration
    let isSelected: Bool
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        configuration.label
            .font(.system(size: 28, weight: .medium))
            .foregroundStyle(isFocused ? Color.inkInverse : Color.ink.opacity(isSelected ? 1 : 0.75))
            .padding(.horizontal, 24)
            .frame(height: 76)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isFocused ? Color.ink : Color.ink.opacity(isSelected ? 0.15 : 0))
            )
            .scaleEffect(isFocused ? 1.04 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: isFocused)
    }
}

/// A compact capsule button; `isOn` fills it with the racing accent.
struct ChipButtonStyle: ButtonStyle {
    var isOn = false

    func makeBody(configuration: Configuration) -> some View {
        ChipLabel(configuration: configuration, isOn: isOn)
    }
}

private struct ChipLabel: View {
    let configuration: ButtonStyleConfiguration
    let isOn: Bool
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        configuration.label
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(isFocused ? Color.inkInverse : (isOn ? .white : Color.ink))
            .padding(.horizontal, 24)
            .frame(height: 56)
            .background(Capsule().fill(isFocused ? Color.ink : (isOn ? Color.racingRed : Color.ink.opacity(0.1))))
            .scaleEffect(isFocused ? 1.08 : 1)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.15), value: isFocused)
    }
}
