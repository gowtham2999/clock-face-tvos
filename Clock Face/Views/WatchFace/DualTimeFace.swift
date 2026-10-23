import SwiftUI

/// "Dual Time": local hours stacked over minutes in thin type, beside the time
/// in up to four of the World tab's cities.
struct DualTimeFace: WatchFace {
    let date: Date

    @Environment(AppSettings.self) private var settings
    @Environment(\.faceBackground) private var faceBackground

    init(date: Date) {
        self.date = date
    }

    private var cities: [WorldCity] {
        let local = TimeZone.current.secondsFromGMT(for: date)
        return Array(settings.worldCities.filter { $0.timeZone.secondsFromGMT(for: date) != local }.prefix(4))
    }

    var body: some View {
        let color = settings.color(for: .dualTime)?.primary ?? .white
        let time = FaceText.digits(date, uses24Hour: settings.uses24HourTime)

        GeometryReader { proxy in
            let unit = proxy.size.height

            ZStack {
                faceBackground ?? .black

                HStack(alignment: .center, spacing: unit * 0.14) {
                    VStack(alignment: .leading, spacing: -unit * 0.1) {
                        Text(time.hours)
                        Text(time.minutes)
                    }
                    .font(.system(size: unit * 0.4, weight: .thin))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(color)
                    .overlay(alignment: .bottomTrailing) {
                        if let period = time.period {
                            Text(period)
                                .font(.system(size: unit * 0.04, weight: .light))
                                .foregroundStyle(color)
                                .offset(x: unit * 0.07, y: -unit * 0.07)
                        }
                    }

                    Grid(alignment: .leading, horizontalSpacing: unit * 0.06, verticalSpacing: unit * 0.035) {
                        ForEach(cities) { city in
                            GridRow {
                                Text(city.name)
                                    .opacity(0.75)
                                Text(TimeFormatting.string(date, in: city.timeZone, uses24Hour: settings.uses24HourTime))
                                    .monospacedDigit()
                            }
                        }
                    }
                    .font(.system(size: unit * 0.036, weight: .regular))
                    .lineLimit(1)
                    .foregroundStyle(.white)
                }
                .animation(.snappy, value: time.hours + time.minutes)
            }
        }
    }
}

#Preview {
    DualTimeFace(date: .now)
        .environment(AppSettings())
}
