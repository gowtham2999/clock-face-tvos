import SwiftUI

/// "Serif Modern": hours and minutes in Apple's New York serif, set large and
/// staggered — minutes stepped to the right and tucked under the hours — with
/// the day and date in small caps above a hairline rule.
struct SerifModernFace: WatchFace {
    let date: Date

    @Environment(AppSettings.self) private var settings
    @Environment(\.faceBackground) private var faceBackground

    init(date: Date) {
        self.date = date
    }

    var body: some View {
        let color = settings.color(for: .serifModern)?.primary ?? .white
        let time = FaceText.digits(date, uses24Hour: settings.uses24HourTime)

        GeometryReader { proxy in
            let unit = proxy.size.height

            ZStack {
                faceBackground ?? .black

                HStack(alignment: .center, spacing: unit * 0.08) {
                    VStack(alignment: .leading, spacing: -unit * 0.21) {
                        Text(time.hours)
                        Text(time.minutes)
                            .padding(.leading, unit * 0.12)
                    }
                    // New York: the system serif, free to use in apps.
                    .font(.system(size: unit * 0.46, weight: .regular, design: .serif))
                    .tracking(-unit * 0.008)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(color)

                    VStack(alignment: .leading, spacing: unit * 0.018) {
                        TrackedCaption(text: FaceText.weekday(date), size: unit * 0.032)
                        TrackedCaption(text: FaceText.monthDay(date), size: unit * 0.032)
                        Rectangle()
                            .fill(color.opacity(0.6))
                            .frame(width: unit * 0.08, height: max(1, unit * 0.0025))
                            .padding(.top, unit * 0.012)
                        if let period = time.period {
                            Text(period)
                                .font(.system(size: unit * 0.036, weight: .regular, design: .serif))
                                .italic()
                                .opacity(0.7)
                                .padding(.top, unit * 0.006)
                        }
                    }
                    .foregroundStyle(.white)
                    .offset(y: -unit * 0.16)
                }
                .animation(.snappy, value: time.hours + time.minutes)
            }
        }
    }
}

#Preview {
    SerifModernFace(date: .now)
        .environment(AppSettings())
}
