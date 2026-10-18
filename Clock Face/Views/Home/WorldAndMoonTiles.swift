import CoreLocation
import SwiftUI

// MARK: - World clocks

/// Up to four of the World tab's cities, skipping the TV's own time zone.
struct WorldClocksTile: View {
    let date: Date

    @Environment(AppSettings.self) private var settings

    private var cities: [WorldCity] {
        let current = TimeZone.current
        return Array(settings.worldCities.filter {
            $0.timeZone.secondsFromGMT(for: date) != current.secondsFromGMT(for: date)
        }.prefix(4))
    }

    var body: some View {
        DashboardTile(padding: 30) {
            VStack(alignment: .leading, spacing: 18) {
                SettingsSectionLabel(text: "World Clocks")
                    .padding(.leading, 6)

                if cities.isEmpty {
                    Text("Add cities on the World tab")
                        .font(.system(size: 26))
                        .opacity(0.6)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    HStack(spacing: 0) {
                        ForEach(cities) { city in
                            cityView(city)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
        }
    }

    private func cityView(_ city: WorldCity) -> some View {
        let time = TimeFormatting.parts(date, in: city.timeZone, uses24Hour: settings.uses24HourTime)

        return HStack(spacing: 16) {
            MiniDial(date: date, timeZone: city.timeZone, isDaytime: city.isDaytime(at: date))
                .frame(width: 100, height: 100)
            VStack(alignment: .leading, spacing: 2) {
                Text(city.name)
                    .font(.system(size: 25, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(time.time)
                        .font(.system(size: 40, weight: .medium))
                        .monospacedDigit()
                    if let period = time.period {
                        Text(period)
                            .font(.system(size: 20, weight: .semibold))
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                Text("\(TimeFormatting.relativeDay(for: date, in: city.timeZone)) \(TimeFormatting.offsetDescription(for: city.timeZone, at: date))")
                    .font(.system(size: 20))
                    .opacity(0.55)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// A small analog dial for a time zone: twelve ticks, hour and minute hands.
/// White with black hands during the city's day, black with white hands at night.
struct MiniDial: View {
    let date: Date
    let timeZone: TimeZone
    let isDaytime: Bool

    var body: some View {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        let angles = ClockAngles(date: date, calendar: calendar)

        return Canvas { context, size in
            let radius = min(size.width, size.height) / 2
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let foreground: Color = isDaytime ? .black : .white
            let ink = GraphicsContext.Shading.color(foreground)
            let face = Path(ellipseIn: CGRect(x: 1, y: 1, width: size.width - 2, height: size.height - 2))

            context.fill(face, with: .color(isDaytime ? .white : .black))
            context.stroke(face, with: .color(Color.ink.opacity(0.25)), lineWidth: 1.5)

            for index in 0..<12 {
                let angle = Double(index) / 12 * 2 * .pi
                let isQuarter = index % 3 == 0
                let outer = radius * 0.86
                let inner = radius * (isQuarter ? 0.68 : 0.76)
                var tick = Path()
                tick.move(to: point(center, radius: inner, angle: angle))
                tick.addLine(to: point(center, radius: outer, angle: angle))
                context.stroke(tick, with: .color(foreground.opacity(isQuarter ? 0.8 : 0.4)), style: StrokeStyle(lineWidth: isQuarter ? 2.5 : 1.5, lineCap: .round))
            }

            for (degrees, length, width) in [(angles.hour, 0.45, 4.0), (angles.minute, 0.7, 3.0)] {
                var hand = Path()
                hand.move(to: center)
                hand.addLine(to: point(center, radius: radius * length, angle: degrees * .pi / 180))
                context.stroke(hand, with: ink, style: StrokeStyle(lineWidth: width, lineCap: .round))
            }
            context.fill(Path(ellipseIn: CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8)), with: ink)
        }
        .accessibilityHidden(true)
    }

    /// A point `radius` from `center`, `angle` radians clockwise from 12 o'clock.
    private func point(_ center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
        CGPoint(x: center.x + radius * CGFloat(sin(angle)), y: center.y - radius * CGFloat(cos(angle)))
    }
}

// MARK: - Moon

/// Tonight's Moon: its lit shape, phase name, illumination and the next full or new moon.
struct MoonTile: View {
    let date: Date

    @Environment(WeatherStore.self) private var weather

    var body: some View {
        // The phase changes slowly; recompute per minute rather than per second.
        let minute = Date(timeIntervalSinceReferenceDate: (date.timeIntervalSinceReferenceDate / 60).rounded(.down) * 60)
        let phase = MoonPhase(at: minute)
        let upcoming: MoonPhase.Name = phase.elongation < 180 ? .fullMoon : .newMoon
        let upcomingDate = MoonPhase.next(upcoming, after: minute)
        let isSouthern = (weather.location?.coordinate.latitude ?? 1) < 0

        DashboardTile(padding: 30) {
            HStack(spacing: 34) {
                MoonView(phase: phase, isSouthernHemisphere: isSouthern)
                    .frame(width: 170, height: 170)

                VStack(alignment: .leading, spacing: 4) {
                    Text(phase.name.rawValue)
                        .font(.system(size: 26, weight: .semibold))
                        .accessibilityIdentifier("moonPhase")
                    Text(phase.illumination.formatted(.percent.precision(.fractionLength(0))))
                        .font(.system(size: 64, weight: .medium))
                        .monospacedDigit()
                    Text("Illuminated")
                        .font(.system(size: 21))
                        .opacity(0.55)
                    if let upcomingDate {
                        Text("\(upcoming == .fullMoon ? "Full" : "New") moon \(upcomingDate.formatted(.dateTime.month(.abbreviated).day()))")
                            .font(.system(size: 21, weight: .medium))
                            .opacity(0.75)
                            .padding(.top, 6)
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .accessibilityElement(children: .combine)
    }
}

/// The Moon's disc drawn from its phase: a faint earthshine disc with the lit
/// part on top, softly shaded and mottled with a few maria. Lit from the right
/// while waxing (left in the southern hemisphere).
struct MoonView: View {
    let phase: MoonPhase
    var isSouthernHemisphere = false

    /// Approximate positions of the main maria on the near side, in unit-disc coordinates.
    private static let maria: [(x: Double, y: Double, r: Double)] = [
        (-0.32, -0.38, 0.22), (-0.05, -0.28, 0.18), (0.18, -0.35, 0.14), (0.42, -0.22, 0.12),
        (-0.48, 0.05, 0.25), (-0.12, 0.08, 0.16), (0.12, 0.05, 0.12), (-0.25, 0.42, 0.14),
    ]

    var body: some View {
        Canvas { context, size in
            let radius = min(size.width, size.height) / 2
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let disc = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))

            // Earthshine: the dark side stays just visible.
            context.fill(disc, with: .radialGradient(
                Gradient(colors: [Color(white: 0.2), Color(white: 0.09)]),
                center: center, startRadius: 0, endRadius: radius
            ))

            let lit = litPath(center: center, radius: radius)
            var litLayer = context
            litLayer.addFilter(.blur(radius: radius * 0.012))
            litLayer.clip(to: lit)
            litLayer.fill(disc, with: .radialGradient(
                Gradient(colors: [Color(white: 0.96), Color(white: 0.82), Color(white: 0.62)]),
                center: CGPoint(x: center.x - radius * 0.2, y: center.y - radius * 0.25), startRadius: 0, endRadius: radius * 1.25
            ))
            for mare in Self.maria {
                let rect = CGRect(
                    x: center.x + radius * (mare.x - mare.r), y: center.y + radius * (mare.y - mare.r),
                    width: radius * mare.r * 2, height: radius * mare.r * 2
                )
                var mareLayer = litLayer
                mareLayer.addFilter(.blur(radius: radius * 0.05))
                mareLayer.fill(Path(ellipseIn: rect), with: .color(Color(white: 0.45).opacity(0.45)))
            }
        }
        .shadow(color: .white.opacity(0.08 + 0.12 * phase.illumination), radius: 24)
        .accessibilityHidden(true)
    }

    /// The lit region: half the limb on the sunward side, closed by the terminator,
    /// an ellipse whose half-width is |1 − 2·illumination| of the radius.
    private func litPath(center: CGPoint, radius: CGFloat) -> Path {
        let litOnRight = phase.isWaxing != isSouthernHemisphere
        let side: CGFloat = litOnRight ? 1 : -1
        let terminatorWidth = radius * CGFloat(abs(1 - 2 * phase.illumination))
        // A crescent's terminator bulges toward the lit limb; a gibbous one away from it.
        let terminatorSide: CGFloat = phase.illumination < 0.5 ? side : -side
        let steps = 64

        var path = Path()
        for step in 0...steps {
            let theta = -Double.pi / 2 + Double.pi * Double(step) / Double(steps)
            let point = CGPoint(x: center.x + side * radius * CGFloat(cos(theta)), y: center.y + radius * CGFloat(sin(theta)))
            step == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        for step in 0...steps {
            let theta = Double.pi / 2 - Double.pi * Double(step) / Double(steps)
            path.addLine(to: CGPoint(
                x: center.x + terminatorSide * terminatorWidth * CGFloat(cos(theta)),
                y: center.y + radius * CGFloat(sin(theta))
            ))
        }
        path.closeSubpath()
        return path
    }
}
