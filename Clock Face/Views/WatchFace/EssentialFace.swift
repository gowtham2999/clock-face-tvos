import SwiftUI

/// "Essential": a clean round dial with fine minute marks, and the date, weather,
/// next sunrise/sunset and a second city in the screen corners.
struct EssentialFace: WatchFace {
    let date: Date

    @Environment(AppSettings.self) private var settings
    @Environment(WeatherStore.self) private var weather

    init(date: Date) {
        self.date = date
    }

    var body: some View {
        let accent = settings.color(for: .essential)?.primary ?? .white

        GeometryReader { proxy in
            let size = proxy.size
            let radius = min(size.width, size.height) / 2 * 0.9

            ZStack {
                Color.black

                RadialTicks(count: 60, innerRadius: radius * 0.9, outerRadius: radius * 0.98, skipEvery: 5)
                    .stroke(Color.white.opacity(0.35), lineWidth: max(1, radius * 0.006))
                RadialTicks(count: 12, innerRadius: radius * 0.86, outerRadius: radius * 0.98)
                    .stroke(Color.white.opacity(0.75), lineWidth: max(1.5, radius * 0.01))
                RadialTicks(count: 12, innerRadius: radius * 0.6, outerRadius: radius * 0.74)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: radius * 0.022, lineCap: .round))

                AnalogHands(
                    angles: ClockAngles(date: date),
                    radius: radius,
                    handColor: .white,
                    secondColor: accent,
                    hourLength: 0.5,
                    minuteLength: 0.8,
                    handWidth: 0.05,
                    secondLength: 0.96,
                    secondTail: 0.16,
                    secondWidth: 0.006
                )

                corners(size: size, accent: accent)
            }
        }
    }

    // MARK: - Corner complications

    private func corners(size: CGSize, accent: Color) -> some View {
        let fontSize = size.height * 0.03

        return ZStack {
            complication(icon: "calendar", text: date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)).uppercased(),
                         accent: accent, fontSize: fontSize, alignment: .topLeading)

            if let temperature = weather.formattedTemperature {
                complication(icon: weather.symbolName ?? "thermometer.medium", text: temperature,
                             accent: accent, fontSize: fontSize, alignment: .topTrailing)
            }

            if let sunEvent = weather.nextSunEvent(after: date) {
                complication(icon: sunEvent.isSunrise ? "sunrise.fill" : "sunset.fill",
                             text: TimeFormatting.string(sunEvent.date, uses24Hour: settings.uses24HourTime),
                             accent: accent, fontSize: fontSize, alignment: .bottomLeading)
            }

            if let city = settings.worldCities.first {
                complication(icon: "globe",
                             text: "\(city.name.uppercased()) \(TimeFormatting.string(date, in: city.timeZone, uses24Hour: settings.uses24HourTime))",
                             accent: accent, fontSize: fontSize, alignment: .bottomTrailing)
            }
        }
        .padding(.horizontal, size.width * 0.05)
        .padding(.vertical, size.height * 0.07)
    }

    private func complication(icon: String, text: String, accent: Color, fontSize: CGFloat, alignment: Alignment) -> some View {
        HStack(spacing: fontSize * 0.4) {
            Image(systemName: icon)
                .symbolRenderingMode(.multicolor)
                .foregroundStyle(accent)
            Text(text)
                .foregroundStyle(.white.opacity(0.85))
        }
        .font(.system(size: fontSize, weight: .semibold, design: .rounded))
        .lineLimit(1)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    }
}

#Preview {
    EssentialFace(date: .now)
        .environment(AppSettings())
        .environment(WeatherStore())
}
