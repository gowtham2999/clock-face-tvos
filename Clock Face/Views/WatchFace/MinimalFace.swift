import SwiftUI

/// "Minimal": the time in one thin line across the screen, the date beneath.
struct MinimalFace: WatchFace {
    let date: Date

    @Environment(AppSettings.self) private var settings
    @Environment(\.faceBackground) private var faceBackground

    init(date: Date) {
        self.date = date
    }

    var body: some View {
        let color = settings.color(for: .minimal)?.primary ?? .white
        let time = TimeFormatting.parts(date, uses24Hour: settings.uses24HourTime)

        GeometryReader { proxy in
            let unit = proxy.size.height

            ZStack {
                faceBackground ?? .black

                VStack(spacing: unit * 0.035) {
                    HStack(alignment: .firstTextBaseline, spacing: unit * 0.02) {
                        Text(time.time)
                            .font(.system(size: unit * 0.34, weight: .ultraLight))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        if let period = time.period {
                            Text(period)
                                .font(.system(size: unit * 0.045, weight: .light))
                        }
                    }
                    .foregroundStyle(color)

                    TrackedCaption(text: FaceText.shortDate(date), size: unit * 0.034)
                        .foregroundStyle(.white)
                }
                .animation(.snappy, value: time.time)
            }
        }
    }
}

#Preview {
    MinimalFace(date: .now)
        .environment(AppSettings())
}
