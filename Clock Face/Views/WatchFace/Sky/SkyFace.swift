import CoreLocation
import SwiftUI

/// "Sky": a digital clock on a sky that follows the real sun — night, every twilight,
/// blue hour, golden hour and day — computed from the sun's elevation at the TV's
/// location, so the colours always match what's outside the window.
struct SkyFace: WatchFace {
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
        let timeline = SolarCalculator.eventTimeline(around: date, coordinate: coordinate, timeZone: .current)

        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                LinearGradient(gradient: sky.gradient, startPoint: .top, endPoint: .bottom)

                StarField(visibility: Self.starVisibility(elevation: sun.elevation), date: date)

                SunGlow(sun: sun, sky: sky, size: size)

                clockText(size: size, sun: sun, isRising: isRising, timeline: timeline)
                    .position(x: size.width / 2, y: size.height * 0.44)

                DayStrip(date: date, coordinate: coordinate, timeline: timeline, uses24Hour: settings.uses24HourTime)
                    .frame(width: size.width * 0.62, height: size.height * 0.08)
                    .position(x: size.width / 2, y: size.height * 0.89)
            }
            // The face is redrawn once a second; easing each step keeps the sky gliding.
            .animation(.linear(duration: 1), value: sun.elevation)
        }
    }

    private var currentCoordinate: GeoCoordinate {
        if let location = weather.location {
            return GeoCoordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        }
        return .approximate(for: .current, at: date)
    }

    // MARK: - Text

    private func clockText(size: CGSize, sun: SolarCalculator.Position, isRising: Bool, timeline: [SolarEventTime]) -> some View {
        let unit = size.height
        let time = TimeFormatting.parts(date, uses24Hour: settings.uses24HourTime)
        let next = timeline.first { $0.date > date }

        return VStack(spacing: unit * 0.012) {
            Text(date.formatted(.dateTime.weekday(.wide).day().month(.wide)).uppercased())
                .font(.system(size: unit * 0.024, weight: .semibold))
                .tracking(unit * 0.004)
                .opacity(0.75)

            HStack(alignment: .firstTextBaseline, spacing: unit * 0.012) {
                Text(time.time)
                    .font(.system(size: unit * 0.25, weight: .thin))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                if let period = time.period {
                    Text(period)
                        .font(.system(size: unit * 0.04, weight: .light))
                }
            }

            Text(SolarEvent.phaseName(elevation: sun.elevation, isRising: isRising).uppercased())
                .font(.system(size: unit * 0.028, weight: .semibold))
                .tracking(unit * 0.006)
                .accessibilityIdentifier("skyPhase")

            if let next {
                Text("\(next.event.displayName) · \(TimeFormatting.string(next.date, uses24Hour: settings.uses24HourTime))")
                    .font(.system(size: unit * 0.024, weight: .regular))
                    .opacity(0.72)
                    .accessibilityIdentifier("skyNextEvent")
            }
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.22), radius: unit * 0.012)
        .animation(.snappy, value: time.time)
    }

    /// Stars fade in from blue hour and are fully out by astronomical night.
    static func starVisibility(elevation: Double) -> Double {
        let progress = min(1, max(0, (-elevation - 4) / 14))
        return pow(progress, 1.5)
    }
}

// MARK: - Sun glow

/// A soft glow at the sun's position: warm and wide near the horizon, fading to a
/// faint white haze as it climbs. East is on the left of the screen, west on the right.
private struct SunGlow: View {
    let sun: SolarCalculator.Position
    let sky: SkyPalette.Sky
    let size: CGSize

    var body: some View {
        let azimuth = sun.azimuth * .pi / 180
        let x = size.width * (0.5 - 0.42 * sin(azimuth))
        let y = size.height * (0.97 - min(max(sun.elevation, -6), 60) / 60 * 0.8)

        let warmth = exp(-pow((sun.elevation - 0.5) / 6, 2))
        let haze = min(max(sun.elevation / 30, 0), 1) * 0.3
        let glowColor = sky.horizon.mixed(with: SkyColor(hex: 0xFFF1D6), by: 0.5).color
        let discOpacity = min(max((sun.elevation + 1) / 1.5, 0), 1) * min(max((15 - sun.elevation) / 5, 0), 1)

        ZStack {
            RadialGradient(
                colors: [glowColor.opacity(0.7 * warmth + haze), glowColor.opacity(0)],
                center: .center,
                startRadius: 0,
                endRadius: size.height * 0.6
            )
            .frame(width: size.height * 1.2, height: size.height * 1.2)

            Circle()
                .fill(Color(hex: 0xFFF6E2))
                .frame(width: size.height * 0.045, height: size.height * 0.045)
                .blur(radius: size.height * 0.004)
                .shadow(color: Color(hex: 0xFFE2B0), radius: size.height * 0.04)
                .opacity(discOpacity)
        }
        .position(x: x, y: y)
        .allowsHitTesting(false)
    }
}

// MARK: - Stars

private struct StarField: View {
    let visibility: Double
    let date: Date

    private struct Star {
        let x: Double
        let y: Double
        let radius: Double
        let phase: Double
    }

    /// Fixed, evenly scattered stars (a seeded generator keeps them in place between frames).
    private static let stars: [Star] = {
        var seed: UInt64 = 0x5EED_C10C
        func next() -> Double {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Double(seed >> 11) / Double(1 << 53)
        }
        return (0..<170).map { _ in
            Star(x: next(), y: pow(next(), 1.4) * 0.8, radius: 0.6 + pow(next(), 3) * 1.6, phase: next() * 2 * .pi)
        }
    }()

    var body: some View {
        if visibility > 0.001 {
            Canvas { context, size in
                let scale = size.height / 1080
                // Real time, not the face's date, so stars don't strobe during "Play a Day".
                let seconds = Date.now.timeIntervalSinceReferenceDate
                for star in Self.stars {
                    // Fade toward the horizon, where the sky glow washes stars out.
                    let horizonFade = 1 - star.y / 0.8 * 0.6
                    let twinkle = 0.75 + 0.25 * sin(seconds * 0.9 + star.phase)
                    let radius = star.radius * scale * 1.5
                    let rect = CGRect(x: star.x * size.width - radius, y: star.y * size.height - radius, width: radius * 2, height: radius * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(visibility * horizonFade * twinkle)))
                }
            }
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Day strip

/// The whole local day's sky as a thin band, with a marker for now and the
/// sunrise and sunset times beneath.
private struct DayStrip: View {
    let date: Date
    let coordinate: GeoCoordinate
    let timeline: [SolarEventTime]
    let uses24Hour: Bool

    private static let samples = 72

    var body: some View {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        let length = end.timeIntervalSince(start)

        GeometryReader { proxy in
            let size = proxy.size
            let barHeight = max(4, size.height * 0.1)
            let barY = size.height * 0.3
            let xPosition = { (moment: Date) -> CGFloat in
                CGFloat(moment.timeIntervalSince(start) / length) * size.width
            }

            ZStack(alignment: .topLeading) {
                Capsule()
                    .fill(LinearGradient(stops: stops(start: start, length: length), startPoint: .leading, endPoint: .trailing))
                    .frame(width: size.width, height: barHeight)
                    .overlay(Capsule().stroke(.white.opacity(0.25), lineWidth: 1))
                    .position(x: size.width / 2, y: barY)

                Circle()
                    .fill(.white)
                    .frame(width: barHeight * 2.6, height: barHeight * 2.6)
                    .shadow(color: .white.opacity(0.8), radius: barHeight * 1.5)
                    .position(x: xPosition(date), y: barY)

                ForEach(markers(start: start, end: end), id: \.event) { marker in
                    Label(TimeFormatting.string(marker.date, uses24Hour: uses24Hour),
                          systemImage: marker.event == .sunriseStarts ? "sunrise.fill" : "sunset.fill")
                        .font(.system(size: size.height * 0.3, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .shadow(color: .black.opacity(0.25), radius: 4)
                        .fixedSize()
                        .position(x: xPosition(marker.date), y: size.height * 0.75)
                }
            }
        }
    }

    private func stops(start: Date, length: TimeInterval) -> [Gradient.Stop] {
        (0...Self.samples).map { index in
            let fraction = Double(index) / Double(Self.samples)
            let moment = start.addingTimeInterval(fraction * length)
            let elevation = SolarCalculator.position(at: moment, coordinate: coordinate).elevation
            let isRising = SolarCalculator.position(at: moment.addingTimeInterval(60), coordinate: coordinate).elevation > elevation
            return Gradient.Stop(color: SkyPalette.sky(elevation: elevation, isRising: isRising).summary.color, location: fraction)
        }
    }

    private func markers(start: Date, end: Date) -> [SolarEventTime] {
        timeline.filter { ($0.event == .sunriseStarts || $0.event == .sunsetEnds) && $0.date >= start && $0.date < end }
    }
}

#Preview {
    SkyFace(date: .now)
        .environment(AppSettings())
        .environment(WeatherStore())
}
