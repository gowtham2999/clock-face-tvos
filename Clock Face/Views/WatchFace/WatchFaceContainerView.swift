import SwiftUI

struct WatchFaceContainerView: View {
    @Environment(AppSettings.self) private var settings
    @State private var tickPlayer = TickSoundPlayer()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            face(for: context.date)
                .onChange(of: Calendar.current.component(.second, from: context.date)) {
                    guard settings.chimeSource != .mute else { return }
                    tickPlayer.tick(source: settings.chimeSource, volume: settings.volume)
                }
        }
    }

    @ViewBuilder
    private func face(for date: Date) -> some View {
        switch settings.faceType {
        case .analogClassic:
            AnalogClockFace(date: date)
        case .flip:
            FlipClockFace(date: date)
        }
    }
}
