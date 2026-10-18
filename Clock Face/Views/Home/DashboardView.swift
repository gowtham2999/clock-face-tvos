import SwiftUI

/// The Home tab: an ambient dashboard of the day — date, month, the current face,
/// weather, world clocks and the Moon. Like the Clock tab, an invisible canvas takes
/// the remote: click to open the face full screen, swipe left/right to change it,
/// press and hold to customise, swipe up for the top bar.
struct DashboardView: View {
    let isChromeVisible: Bool
    var isCanvasFocused: FocusState<Bool>.Binding
    /// False while the settings panel owns the remote.
    var acceptsInput = true
    let onInteraction: () -> Void
    let onShowChrome: () -> Void
    let onOpenClock: () -> Void
    let onCustomize: () -> Void

    @Environment(AppSettings.self) private var settings

    /// Tile sizes for the 1760×960 area inside the TV safe area.
    private enum Layout {
        static let spacing: CGFloat = 24
        static let sideColumn: CGFloat = 400
        static let weatherColumn: CGFloat = 520
        static let bottomRow: CGFloat = 250
        static let dateTile: CGFloat = 290
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let date = DebugClock.adjusted(context.date)
            let shift = settings.pixelShiftEnabled ? PixelShift.offset(at: context.date) : .zero

            grid(date: date)
                .offset(shift)
                .animation(.easeInOut(duration: 2), value: shift)
        }
        // Step back to make room for the top bar rather than sliding under it.
        .scaleEffect(isChromeVisible ? 0.86 : 1, anchor: .bottom)
        .animation(.easeInOut(duration: 0.3), value: isChromeVisible)
        .overlay { canvas.ignoresSafeArea() }
    }

    private func grid(date: Date) -> some View {
        VStack(spacing: Layout.spacing) {
            HStack(spacing: Layout.spacing) {
                VStack(spacing: Layout.spacing) {
                    DateTile(date: date)
                        .frame(height: Layout.dateTile)
                    MonthCalendarTile(date: date)
                }
                .frame(width: Layout.sideColumn)

                ClockTile(date: date, isHighlighted: isCanvasFocused.wrappedValue && isChromeVisible)

                WeatherTile(date: date)
                    .frame(width: Layout.weatherColumn)
            }

            HStack(spacing: Layout.spacing) {
                WorldClocksTile(date: date)
                MoonTile(date: date)
                    .frame(width: Layout.weatherColumn)
            }
            .frame(height: Layout.bottomRow)
        }
    }

    private var canvas: some View {
        Color.clear
            .contentShape(Rectangle())
            .focusable(acceptsInput)
            .focusEffectDisabled()
            .focused(isCanvasFocused)
            .onMoveCommand { direction in
                onInteraction()
                switch direction {
                case .left: switchFace(by: -1)
                case .right: switchFace(by: 1)
                default: onShowChrome()
                }
            }
            .onTapGesture {
                onInteraction()
                onOpenClock()
            }
            .onLongPressGesture(minimumDuration: 0.8) {
                onInteraction()
                onCustomize()
            }
            .accessibilityElement()
            .accessibilityLabel("Home, \(settings.faceType.displayName) clock")
            .accessibilityHint("Press to show the clock full screen. Swipe left or right to change face.")
            .accessibilityIdentifier("homeCanvas")
            // Keep the focusable area below the top bar, so pressing Down from the bar lands here.
            .padding(.top, 150)
    }

    private func switchFace(by offset: Int) {
        let next = settings.face(offsetBy: offset)
        guard next != settings.faceType else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            settings.faceType = next
        }
    }
}

// MARK: - Tile chrome

/// A rounded dashboard panel in the theme's tile colour.
struct DashboardTile<Content: View>: View {
    var padding: CGFloat = 36
    @ViewBuilder let content: Content

    @Environment(AppSettings.self) private var settings

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .foregroundStyle(Color.ink)
            .background(settings.theme.tile, in: RoundedRectangle(cornerRadius: 36, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .strokeBorder(Color.ink.opacity(0.06), lineWidth: 1)
            )
    }
}

// MARK: - Clock

/// The user's current face, live, filling the centre tile. Selecting it zooms the
/// same face to full screen.
private struct ClockTile: View {
    let date: Date
    let isHighlighted: Bool

    @Environment(AppSettings.self) private var settings

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 36, style: .continuous)

        FaceView(face: settings.faceType, date: date)
            .id(settings.faceType)
            .transition(.opacity)
            .environment(\.faceBackground, settings.theme.tile)
            .background(settings.theme.tile)
            .clipShape(shape)
            .overlay(shape.strokeBorder(Color.ink.opacity(isHighlighted ? 0.85 : 0.06), lineWidth: isHighlighted ? 4 : 1))
            .overlay(alignment: .bottom) {
                if isHighlighted {
                    Label("Press to expand", systemImage: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color.ink)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 24)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isHighlighted)
            .accessibilityIdentifier("dashboardClock")
    }
}

#Preview {
    @Previewable @FocusState var focused: Bool
    DashboardView(isChromeVisible: false, isCanvasFocused: $focused, onInteraction: {}, onShowChrome: {}, onOpenClock: {}, onCustomize: {})
        .environment(AppSettings())
        .environment(WeatherStore())
}
