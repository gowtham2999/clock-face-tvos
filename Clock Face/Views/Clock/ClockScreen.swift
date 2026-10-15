import SwiftUI

/// The Clock tab: the current face, full screen. An invisible focusable canvas
/// takes the Siri Remote input while the top bar is hidden — swipe left/right
/// to change face, click to show or hide the top bar, press and hold to customise.
struct ClockScreen: View {
    @Binding var isChromeVisible: Bool
    var isCanvasFocused: FocusState<Bool>.Binding
    /// False while an overlay (the settings panel) owns the remote, so stray
    /// presses can't escape into the clock and change the face.
    var acceptsInput = true
    let onInteraction: () -> Void
    let onCustomize: () -> Void

    @Environment(AppSettings.self) private var settings
    @State private var tickPlayer = TickSoundPlayer()
    @State private var announcedFace: WatchFaceType?
    @State private var announcementTask: Task<Void, Never>?

    var body: some View {
        ZStack(alignment: .bottom) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let shift = settings.pixelShiftEnabled ? PixelShift.offset(at: context.date) : .zero
                FaceView(face: settings.faceType, date: DebugClock.adjusted(context.date))
                    .scaleEffect(settings.pixelShiftEnabled ? PixelShift.overscanScale : 1)
                    .offset(shift)
                    .animation(.easeInOut(duration: 2), value: shift)
                    .onChange(of: Calendar.current.component(.second, from: context.date)) {
                        guard settings.chimeSource != .mute else { return }
                        tickPlayer.tick(source: settings.chimeSource, volume: settings.volume)
                    }
            }
            .id(settings.faceType)
            .transition(.opacity)
            .ignoresSafeArea()

            canvas

            if let announcedFace {
                FaceAnnouncement(face: announcedFace, faces: settings.myFaces)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: settings.faceType)
        .animation(.easeInOut(duration: 0.25), value: announcedFace)
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
                default: isChromeVisible = true
                }
            }
            .onTapGesture {
                onInteraction()
                isChromeVisible.toggle()
            }
            .onLongPressGesture(minimumDuration: 0.8) {
                onInteraction()
                onCustomize()
            }
            .accessibilityElement()
            .accessibilityLabel("Clock face, \(settings.faceType.displayName)")
            .accessibilityHint("Swipe left or right to change face. Press and hold to customise.")
            .accessibilityIdentifier("clockCanvas")
            // Keep the focusable area below the top bar, so pressing Down from the bar lands here.
            .padding(.top, 150)
    }

    private func switchFace(by offset: Int) {
        let next = settings.face(offsetBy: offset)
        guard next != settings.faceType else { return }
        settings.faceType = next

        announcedFace = next
        announcementTask?.cancel()
        announcementTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            announcedFace = nil
        }
    }
}

/// Face name with a page indicator for My Faces, shown briefly after switching.
private struct FaceAnnouncement: View {
    let face: WatchFaceType
    let faces: [WatchFaceType]

    var body: some View {
        VStack(spacing: 14) {
            Text(face.displayName)
                .font(.system(size: 30, weight: .semibold))
                .accessibilityIdentifier("faceAnnouncement")
            HStack(spacing: 10) {
                ForEach(faces) { item in
                    Circle()
                        .fill(Color.ink.opacity(item == face ? 0.9 : 0.3))
                        .frame(width: 10, height: 10)
                }
            }
        }
        .foregroundStyle(Color.ink)
        .padding(.horizontal, 40)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial, in: Capsule())
    }
}
