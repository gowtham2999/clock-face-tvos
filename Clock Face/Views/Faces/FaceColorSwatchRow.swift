import SwiftUI

struct FaceColorSwatchRow: View {
    let palette: [FaceColor]
    let selectedID: String?
    let onSelect: (FaceColor) -> Void

    var body: some View {
        HStack(spacing: 18) {
            ForEach(palette) { color in
                Button {
                    onSelect(color)
                } label: {
                    Circle().fill(color.primary)
                }
                .buttonStyle(SwatchButtonStyle(isSelected: color.id == selectedID))
                .accessibilityLabel(color.name)
                .accessibilityAddTraits(color.id == selectedID ? .isSelected : [])
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
            .frame(width: 56, height: 56)
            // Keeps a swatch visible when it matches the background.
            .overlay(Circle().stroke(Color.ink.opacity(0.2), lineWidth: 1))
            .padding(6)
            .overlay(Circle().stroke(Color.ink, lineWidth: isSelected ? 3 : 0))
            .scaleEffect(isFocused ? 1.18 : 1)
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .shadow(color: Color.ink.opacity(isFocused ? 0.35 : 0), radius: 10)
            .animation(.easeOut(duration: 0.15), value: isFocused)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
