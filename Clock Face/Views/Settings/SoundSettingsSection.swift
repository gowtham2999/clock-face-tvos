import SwiftUI

struct SoundSettingsSection: View {
    @Binding var chimeSource: ChimeSource
    @Binding var volume: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            PillSegmentedControl(options: ChimeSource.allCases, selection: $chimeSource) { $0.displayName }

            VolumeBar(volume: $volume)
                .disabled(chimeSource == .mute)
        }
    }
}

/// A remote-friendly volume control: focus it, then swipe or press left/right
/// to step the level. tvOS has no draggable Slider for the Siri Remote.
private struct VolumeBar: View {
    @Binding var volume: Double
    @FocusState private var isFocused: Bool
    @Environment(\.isEnabled) private var isEnabled

    private let step = 0.05
    private let width: CGFloat = 380
    private let height: CGFloat = 56

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.ink.opacity(isFocused ? 0.25 : 0.1))

            Capsule()
                .fill(Color.ink)
                .frame(width: max(height, width * volume))

            Text("\(Int((volume * 100).rounded()))%")
                .font(.system(size: 22, weight: .semibold).monospacedDigit())
                // The label sits at the far right, so only the fill reaches it near 100%.
                .foregroundStyle(volume > 0.9 ? Color.inkInverse : Color.ink)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 22)
        }
        .frame(width: width, height: height)
        .opacity(isEnabled ? 1 : 0.35)
        .scaleEffect(isFocused ? 1.04 : 1)
        .animation(.easeOut(duration: 0.15), value: isFocused)
        .animation(.easeOut(duration: 0.1), value: volume)
        .focusable(isEnabled)
        .focused($isFocused)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Volume")
        .accessibilityValue("\(Int((volume * 100).rounded()))%")
        .onMoveCommand { direction in
            switch direction {
            case .left: volume = max(0, ((volume - step) * 20).rounded() / 20)
            case .right: volume = min(1, ((volume + step) * 20).rounded() / 20)
            default: break
            }
        }
    }
}
