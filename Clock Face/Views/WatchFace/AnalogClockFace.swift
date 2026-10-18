import SwiftUI

/// "Classic": oversized faint numerals at the quarters, chunky hands and an accent second hand.
struct AnalogClockFace: WatchFace {
    let date: Date

    @Environment(AppSettings.self) private var settings
    @Environment(\.faceBackground) private var faceBackground

    init(date: Date) {
        self.date = date
    }

    var body: some View {
        let accent = settings.color(for: .analogClassic)?.primary ?? .red

        GeometryReader { proxy in
            let radius = min(proxy.size.width, proxy.size.height) / 2 * 0.95

            ZStack {
                faceBackground ?? settings.theme.background

                ClockNumeralsView(radius: radius)

                AnalogHands(
                    angles: ClockAngles(date: date),
                    radius: radius,
                    handColor: .ink,
                    secondColor: accent,
                    hourLength: 0.5,
                    minuteLength: 0.78,
                    handWidth: 0.075,
                    secondLength: 0.92,
                    secondTail: 0.2,
                    secondWidth: 0.006,
                    shadowColor: .black.opacity(0.35),
                    shadowRadius: radius * 0.012
                )
            }
        }
    }
}

#Preview {
    AnalogClockFace(date: .now)
        .environment(AppSettings())
}
