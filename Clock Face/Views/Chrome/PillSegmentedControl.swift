import SwiftUI

/// Capsule-shaped segmented control used for the top tab bar and the sound picker.
/// The selected segment keeps a soft capsule behind it; the remote-focused segment
/// is filled white and slightly enlarged, so both states read independently.
struct PillSegmentedControl<Value: Hashable>: View {
    let options: [Value]
    @Binding var selection: Value
    let title: (Value) -> String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                Button {
                    selection = option
                } label: {
                    Text(title(option))
                }
                .buttonStyle(PillSegmentButtonStyle(isSelected: option == selection))
            }
        }
        .padding(6)
        .background(Capsule().fill(Color.ink.opacity(0.08)))
        .focusSection()
    }
}

private struct PillSegmentButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        PillSegmentLabel(configuration: configuration, isSelected: isSelected)
    }
}

private struct PillSegmentLabel: View {
    let configuration: ButtonStyleConfiguration
    let isSelected: Bool
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        configuration.label
            .font(.system(size: 24, weight: .semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 26)
            .padding(.vertical, 12)
            .background(Capsule().fill(background))
            .scaleEffect(isFocused ? 1.06 : 1)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.15), value: isFocused)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }

    private var foreground: Color {
        if isFocused { return .inkInverse }
        return isSelected ? Color.ink : Color.ink.opacity(0.55)
    }

    private var background: Color {
        if isFocused { return .ink }
        return isSelected ? Color.ink.opacity(0.18) : .clear
    }
}
