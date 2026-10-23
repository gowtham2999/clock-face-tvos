import SwiftUI

/// "Weather": current conditions with today's high and low on the left, a clean
/// dial on the right. Without weather data the left side shows the date and sun times.
struct WeatherFace: WatchFace {
    let date: Date

    @Environment(AppSettings.self) private var settings
    @Environment(WeatherStore.self) private var weather
    @Environment(\.faceBackground) private var faceBackground

    init(date: Date) {
        self.date = date
    }

    var body: some View {
        let accent = settings.color(for: .weather)?.primary ?? .orange

        GeometryReader { proxy in
            let size = proxy.size
            let unit = size.height
            let radius = unit * 0.36

            ZStack {
                faceBackground ?? .black

                conditions(unit: unit)
                    .frame(width: size.width * 0.4, alignment: .leading)
                    .position(x: size.width * 0.29, y: size.height / 2)

                ZStack {
                    RadialTicks(count: 60, innerRadius: radius * 0.92, outerRadius: radius, skipEvery: 5)
                        .stroke(Color.white.opacity(0.4), lineWidth: max(1, radius * 0.007))
                    RadialTicks(count: 12, innerRadius: radius * 0.8, outerRadius: radius)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: max(1.5, radius * 0.018), lineCap: .round))
                    AnalogHands(
                        angles: ClockAngles(date: date),
                        radius: radius,
                        handColor: .white,
                        secondColor: accent,
                        hourLength: 0.5,
                        minuteLength: 0.82,
                        handWidth: 0.03,
                        secondLength: 0.92,
                        secondTail: 0.16,
                        secondWidth: 0.007
                    )
                }
                .frame(width: radius * 2, height: radius * 2)
                .position(x: size.width * 0.72, y: size.height / 2)
            }
            .foregroundStyle(.white)
        }
    }

    @ViewBuilder
    private func conditions(unit: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: unit * 0.01) {
            if let place = weather.placeName {
                HStack(spacing: unit * 0.014) {
                    Text(place)
                    Image(systemName: "location.fill")
                        .font(.system(size: unit * 0.028))
                }
                .font(.system(size: unit * 0.045, weight: .medium))
                .lineLimit(1)
            }

            if let temperature = weather.formattedTemperature {
                HStack(alignment: .center, spacing: unit * 0.03) {
                    Text(temperature)
                        .font(.system(size: unit * 0.2, weight: .regular))
                        .monospacedDigit()
                    Image(systemName: weather.symbolName ?? "cloud")
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: unit * 0.08))
                }
                if let condition = weather.conditionDescription {
                    Text(condition)
                        .font(.system(size: unit * 0.045))
                }
                if let high = weather.todayHigh, let low = weather.todayLow {
                    Text("H:\(WeatherStore.format(high))  L:\(WeatherStore.format(low))")
                        .font(.system(size: unit * 0.04))
                        .opacity(0.7)
                }
            } else {
                Text(date.formatted(.dateTime.weekday(.wide)))
                    .font(.system(size: unit * 0.06, weight: .medium))
                Text(date.formatted(.dateTime.month(.wide).day()))
                    .font(.system(size: unit * 0.09, weight: .regular))
                if let next = weather.nextSunEvent(after: date) {
                    Label(TimeFormatting.string(next.date, uses24Hour: settings.uses24HourTime),
                          systemImage: next.isSunrise ? "sunrise.fill" : "sunset.fill")
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: unit * 0.04))
                        .opacity(0.8)
                        .padding(.top, unit * 0.02)
                }
            }
        }
    }
}

#Preview {
    WeatherFace(date: .now)
        .environment(AppSettings())
        .environment(WeatherStore())
}
