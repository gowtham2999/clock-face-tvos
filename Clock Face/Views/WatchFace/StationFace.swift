import SwiftUI

/// "Station": hour and minute marks running along the screen edges, and four
/// small dials for the date, running seconds, weather and a second city.
struct StationFace: WatchFace {
    let date: Date

    @Environment(AppSettings.self) private var settings
    @Environment(WeatherStore.self) private var weather

    init(date: Date) {
        self.date = date
    }

    var body: some View {
        let color = settings.color(for: .station) ?? WatchFaceType.station.palette[0]
        let ink = color.secondary
        let angles = ClockAngles(date: date)

        GeometryReader { proxy in
            let size = proxy.size
            let unit = size.height
            let subdialRadius = unit * 0.085

            ZStack {
                color.primary

                EdgeTicks(count: 60, length: unit * 0.028, inset: unit * 0.035, skipEvery: 5)
                    .stroke(ink.opacity(0.85), lineWidth: max(1, unit * 0.0025))
                EdgeTicks(count: 12, length: unit * 0.065, inset: unit * 0.035)
                    .stroke(ink, lineWidth: max(1.5, unit * 0.006))

                Subdial(radius: subdialRadius, ink: ink) { dateDial(radius: subdialRadius, ink: ink) }
                    .offset(y: -unit * 0.22)
                Subdial(radius: subdialRadius, ink: ink) { secondsDial(radius: subdialRadius, ink: ink, angle: angles.second) }
                    .offset(x: size.width * 0.22)
                Subdial(radius: subdialRadius, ink: ink) { weatherDial(radius: subdialRadius, ink: ink) }
                    .offset(y: unit * 0.22)
                Subdial(radius: subdialRadius, ink: ink) { cityDial(radius: subdialRadius, ink: ink) }
                    .offset(x: -size.width * 0.22)

                AnalogHands(
                    angles: angles,
                    radius: unit * 0.45,
                    handColor: ink,
                    secondColor: ink,
                    hourLength: 0.55,
                    minuteLength: 0.85,
                    handWidth: 0.045,
                    secondLength: 0.92,
                    secondTail: 0.15,
                    secondWidth: 0.005
                )
            }
        }
    }

    // MARK: - Subdial contents

    private func dateDial(radius: CGFloat, ink: Color) -> some View {
        VStack(spacing: 0) {
            Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                .font(.system(size: radius * 0.3, weight: .semibold))
            Text(date.formatted(.dateTime.day()))
                .font(.system(size: radius * 0.7, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(ink)
    }

    private func secondsDial(radius: CGFloat, ink: Color, angle: Double) -> some View {
        ZStack {
            RadialTicks(count: 12, innerRadius: radius * 0.76, outerRadius: radius * 0.9)
                .stroke(ink.opacity(0.8), lineWidth: max(1, radius * 0.03))
            Capsule()
                .fill(ink)
                .frame(width: max(1.5, radius * 0.05), height: radius * 0.72)
                .offset(y: -radius * 0.36)
                .rotationEffect(.degrees(angle))
            Circle()
                .fill(ink)
                .frame(width: radius * 0.14, height: radius * 0.14)
        }
    }

    private func weatherDial(radius: CGFloat, ink: Color) -> some View {
        VStack(spacing: radius * 0.06) {
            Image(systemName: weather.symbolName ?? "cloud")
                .font(.system(size: radius * 0.42))
            Text(weather.formattedTemperature ?? "--°")
                .font(.system(size: radius * 0.34, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(ink)
    }

    private func cityDial(radius: CGFloat, ink: Color) -> some View {
        let city = settings.worldCities.first
        let label = city?.name.uppercased() ?? "UTC"
        let timeZone = city?.timeZone ?? TimeZone(identifier: "UTC") ?? .current
        let time = TimeFormatting.parts(date, in: timeZone, uses24Hour: settings.uses24HourTime).time

        return VStack(spacing: radius * 0.04) {
            Text(label)
                .font(.system(size: radius * 0.22, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(width: radius * 1.5)
            Text(time)
                .font(.system(size: radius * 0.36, weight: .semibold, design: .rounded))
                .monospacedDigit()
        }
        .foregroundStyle(ink)
    }
}

private struct Subdial<Content: View>: View {
    let radius: CGFloat
    let ink: Color
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Circle()
                .stroke(ink.opacity(0.35), lineWidth: max(1, radius * 0.025))
            content
        }
        .frame(width: radius * 2, height: radius * 2)
    }
}

#Preview {
    StationFace(date: .now)
        .environment(AppSettings())
        .environment(WeatherStore())
}
