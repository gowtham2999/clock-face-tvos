import SwiftUI

struct AccentColorSwatchRow: View {
    @Binding var selection: AccentColorOption

    var body: some View {
        HStack(spacing: 18) {
            ForEach(AccentColorOption.allCases) { option in
                Button {
                    selection = option
                } label: {
                    Circle().fill(option.color)
                }
                .buttonStyle(SwatchButtonStyle(isSelected: option == selection))
                .accessibilityLabel(option.rawValue.capitalized)
                .accessibilityAddTraits(option == selection ? .isSelected : [])
            }
        }
        .focusSection()
    }
}

private struct SwatchButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        SwatchLabel(configuration: configuration, isSelected: isSelected)
    }
}

private struct SwatchLabel: View {
    let configuration: ButtonStyleConfiguration
    let isSelected: Bool
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        configuration.label
            .frame(width: 52, height: 52)
            // Keeps a swatch visible when it matches the background (black on dark, white on light).
            .overlay(Circle().stroke(Color.ink.opacity(0.2), lineWidth: 1))
            .padding(6)
            .overlay(
                Circle().stroke(Color.ink, lineWidth: isSelected ? 3 : 0)
            )
            .scaleEffect(isFocused ? 1.18 : 1)
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .shadow(color: Color.ink.opacity(isFocused ? 0.35 : 0), radius: 10)
            .animation(.easeOut(duration: 0.15), value: isFocused)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
