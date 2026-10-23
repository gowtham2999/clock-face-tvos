import SwiftUI

/// "Bold": heavy hours stacked over minutes, set as large as the screen allows,
/// with the day and date in small caps alongside.
struct BoldFace: WatchFace {
    let date: Date

    @Environment(AppSettings.self) private var settings
    @Environment(\.faceBackground) private var faceBackground

    init(date: Date) {
        self.date = date
    }

    var body: some View {
        let color = settings.color(for: .bold)?.primary ?? .white
        let time = FaceText.digits(date, uses24Hour: settings.uses24HourTime)

        GeometryReader { proxy in
            let unit = proxy.size.height

            ZStack {
                faceBackground ?? .black

                HStack(alignment: .center, spacing: unit * 0.07) {
                    VStack(alignment: .leading, spacing: -unit * 0.15) {
                        Text(time.hours)
                        Text(time.minutes)
                    }
                    .font(.system(size: unit * 0.5, weight: .black))
                    .tracking(-unit * 0.012)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(color)

                    VStack(alignment: .leading, spacing: unit * 0.018) {
                        TrackedCaption(text: FaceText.weekday(date), size: unit * 0.036)
                        TrackedCaption(text: FaceText.monthDay(date), size: unit * 0.036)
                        if let period = time.period {
                            TrackedCaption(text: period, size: unit * 0.036, opacity: 0.45)
                                .padding(.top, unit * 0.02)
                        }
                    }
                    .foregroundStyle(.white)
                    .offset(y: -unit * 0.02)
                }
                .animation(.snappy, value: time.hours + time.minutes)
            }
        }
    }
}

#Preview {
    BoldFace(date: .now)
        .environment(AppSettings())
}
