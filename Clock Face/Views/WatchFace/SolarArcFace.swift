import CoreLocation
import SwiftUI

/// "Solar Arc": the sun travels an arc over layered mountains from today's sunrise
/// to sunset, on a sky that follows the real sun. The time sits under the arc.
struct SolarArcFace: WatchFace {
    let date: Date

    @Environment(AppSettings.self) private var settings
    @Environment(WeatherStore.self) private var weather

    init(date: Date) {
        self.date = date
    }

    var body: some View {
        let coordinate = currentCoordinate
        let sun = SolarCalculator.position(at: date, coordinate: coordinate)
        let isRising = SolarCalculator.position(at: date.addingTimeInterval(60), coordinate: coordinate).elevation > sun.elevation
        let sky = SkyPalette.sky(elevation: sun.elevation, isRising: isRising)
        let events = SolarCalculator.events(on: date, coordinate: coordinate, timeZone: .current)
        let sunrise = events.first { $0.event == .sunriseStarts }?.date
        let sunset = events.first { $0.event == .sunsetEnds }?.date
        let progress = Self.dayProgress(date: date, sunrise: sunrise, sunset: sunset)

        GeometryReader { proxy in
            let size = proxy.size
            let unit = size.height
            let horizon = size.height * 0.76
            let arc = ArcGeometry(center: CGPoint(x: size.width / 2, y: horizon), radiusX: size.width * 0.36, radiusY: size.height * 0.62)

            ZStack {
                LinearGradient(gradient: sky.gradient, startPoint: .top, endPoint: .bottom)

                SunArc(geometry: arc, progress: progress, color: sky.horizon.mixed(with: SkyColor(hex: 0xFFE7B8), by: 0.6).color)

                if let progress {
                    let point = arc.point(at: progress)
                    SunDisc(unit: unit)
                        .position(point)
                }

                // Three ridges, each nearer one darker, for aerial perspective.
                // Cool silhouettes from the mid-sky colour with a touch of horizon glow
                // on the farthest ridge.
                Mountains(horizon: horizon, peak: unit * 0.2, seed: 0.4)
                    .fill(sky.middle.mixed(with: sky.horizon, by: 0.25).mixed(with: SkyColor(hex: 0x0A0C14), by: 0.6).color)
                Mountains(horizon: horizon + unit * 0.05, peak: unit * 0.16, seed: 2.2)
                    .fill(sky.middle.mixed(with: SkyColor(hex: 0x05060A), by: 0.8).color)
                Mountains(horizon: horizon + unit * 0.12, peak: unit * 0.12, seed: 4.1)
                    .fill(sky.zenith.mixed(with: SkyColor(hex: 0x020306), by: 0.88).color)

                VStack(spacing: unit * 0.02) {
                    let time = TimeFormatting.parts(date, uses24Hour: settings.uses24HourTime)
                    HStack(alignment: .firstTextBaseline, spacing: unit * 0.015) {
                        Text(time.time)
                            .font(.system(size: unit * 0.16, weight: .light))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        if let period = time.period {
                            Text(period)
                                .font(.system(size: unit * 0.035, weight: .regular))
                        }
                    }
                    TrackedCaption(text: FaceText.shortDate(date), size: unit * 0.03, opacity: 0.8)
                }
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.25), radius: unit * 0.012)
                .position(x: size.width / 2, y: size.height * 0.5)

                HStack {
                    sunLabel("sunrise.fill", sunrise, unit: unit)
                    Spacer()
                    sunLabel("sunset.fill", sunset, unit: unit)
                }
                .padding(.horizontal, size.width * 0.06)
                .position(x: size.width / 2, y: size.height * 0.92)
            }
            .animation(.linear(duration: 1), value: sun.elevation)
        }
    }

    private var currentCoordinate: GeoCoordinate {
        if let location = weather.location {
            return GeoCoordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        }
        return .approximate(for: .current, at: date)
    }

    @ViewBuilder
    private func sunLabel(_ symbol: String, _ moment: Date?, unit: CGFloat) -> some View {
        if let moment {
            Label(TimeFormatting.string(moment, uses24Hour: settings.uses24HourTime), systemImage: symbol)
                .font(.system(size: unit * 0.03, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    /// 0 at sunrise, 1 at sunset, nil while the sun is down.
    static func dayProgress(date: Date, sunrise: Date?, sunset: Date?) -> Double? {
        guard let sunrise, let sunset, date >= sunrise, date <= sunset else { return nil }
        return date.timeIntervalSince(sunrise) / sunset.timeIntervalSince(sunrise)
    }
}

/// Half an ellipse standing on the horizon; progress 0 is its left foot, 1 its right.
private struct ArcGeometry {
    let center: CGPoint
    let radiusX: CGFloat
    let radiusY: CGFloat

    func point(at progress: Double) -> CGPoint {
        let angle = Double.pi * (1 - progress)
        return CGPoint(x: center.x + radiusX * CGFloat(cos(angle)), y: center.y - radiusY * CGFloat(sin(angle)))
    }
}

/// The sun's path: a faint full arc, with the part already travelled today drawn brighter.
private struct SunArc: View {
    let geometry: ArcGeometry
    let progress: Double?
    let color: Color

    var body: some View {
        Canvas { context, size in
            let width = max(1.5, size.height * 0.0028)
            context.stroke(path(to: 1), with: .color(color.opacity(0.35)), lineWidth: width)
            if let progress, progress > 0 {
                context.stroke(path(to: progress), with: .color(color.opacity(0.9)), lineWidth: width * 1.2)
            }
        }
    }

    private func path(to end: Double) -> Path {
        var path = Path()
        let steps = 120
        for step in 0...steps {
            let point = geometry.point(at: end * Double(step) / Double(steps))
            step == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        return path
    }
}

private struct SunDisc: View {
    let unit: CGFloat

    var body: some View {
        ZStack {
            RadialGradient(colors: [Color(hex: 0xFFE2A8).opacity(0.55), .clear], center: .center, startRadius: 0, endRadius: unit * 0.22)
                .frame(width: unit * 0.44, height: unit * 0.44)
            Circle()
                .fill(Color(hex: 0xFFF6E2))
                .frame(width: unit * 0.045, height: unit * 0.045)
                .shadow(color: Color(hex: 0xFFD08A), radius: unit * 0.03)
        }
        .allowsHitTesting(false)
    }
}

/// A ridge line of peaks (folded sine waves give sharp summits and rounded valleys),
/// filled down to the bottom of the screen.
private struct Mountains: Shape {
    let horizon: CGFloat
    let peak: CGFloat
    let seed: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.maxY))
        let steps = 160
        for step in 0...steps {
            let x = Double(step) / Double(steps)
            let ridge = 0.6 * (1 - abs(sin(x * 4.3 + seed)))
                + 0.28 * (1 - abs(sin(x * 11.9 + seed * 2.3)))
                + 0.12 * sin(x * 37.1 + seed * 0.7)
            let height = peak * CGFloat(0.25 + 0.75 * ridge)
            path.addLine(to: CGPoint(x: rect.width * CGFloat(x), y: horizon - height))
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    SolarArcFace(date: .now)
        .environment(AppSettings())
        .environment(WeatherStore())
}
