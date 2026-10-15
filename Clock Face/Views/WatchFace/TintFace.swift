import SwiftUI

/// "Tint": a full-screen colour with simple white hands and the date above.
struct TintFace: WatchFace {
    let date: Date

    @Environment(AppSettings.self) private var settings

    init(date: Date) {
        self.date = date
    }

    var body: some View {
        let color = settings.color(for: .tint) ?? WatchFaceType.tint.palette[0]

        GeometryReader { proxy in
            let size = proxy.size
            let radius = min(size.width, size.height) / 2 * 0.86

            ZStack {
                color.primary

                // A soft vignette keeps the flat colour from looking like a blank screen.
                RadialGradient(
                    colors: [.white.opacity(0.07), .black.opacity(0.22)],
                    center: .center,
                    startRadius: 0,
                    endRadius: max(size.width, size.height) * 0.7
                )

                Text(date.formatted(.dateTime.weekday(.abbreviated).day()).uppercased())
                    .font(.system(size: size.height * 0.04, weight: .semibold, design: .rounded))
                    .tracking(size.height * 0.006)
                    .foregroundStyle(.white.opacity(0.85))
                    .position(x: size.width / 2, y: size.height * 0.075)

                AnalogHands(
                    angles: ClockAngles(date: date),
                    radius: radius,
                    handColor: .white,
                    secondColor: color.secondary,
                    hourLength: 0.5,
                    minuteLength: 0.85,
                    handWidth: 0.045,
                    secondLength: 0.95,
                    secondTail: 0.15,
                    secondWidth: 0.006,
                    shadowColor: .black.opacity(0.25),
                    shadowRadius: radius * 0.015
                )
            }
        }
    }
}

#Preview {
    TintFace(date: .now)
        .environment(AppSettings())
}
