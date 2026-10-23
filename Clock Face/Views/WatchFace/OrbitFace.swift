import SwiftUI

/// "Orbit": the Sun and the six classical planets on evenly spaced orbits, each
/// at its real heliocentric longitude for today, beside the time.
struct OrbitFace: WatchFace {
    let date: Date

    @Environment(AppSettings.self) private var settings
    @Environment(\.faceBackground) private var faceBackground

    init(date: Date) {
        self.date = date
    }

    struct Planet {
        let name: String
        /// Mean longitude at J2000 and its daily motion, in degrees.
        let longitudeAtEpoch: Double
        let dailyMotion: Double
        /// Orbit radius and body radius as fractions of the screen height.
        let orbit: CGFloat
        let size: CGFloat
        let color: UInt32
        var hasRings = false

        /// Mean heliocentric longitude in degrees — within a few degrees of the true
        /// position, which is plenty at this scale.
        func longitude(at date: Date) -> Double {
            let days = date.timeIntervalSince1970 / 86_400 - 10_957.5
            return (longitudeAtEpoch + dailyMotion * days).truncatingRemainder(dividingBy: 360)
        }
    }

    static let planets: [Planet] = [
        Planet(name: "Mercury", longitudeAtEpoch: 252.25, dailyMotion: 4.09233, orbit: 0.12, size: 0.009, color: 0xB5ADA6),
        Planet(name: "Venus", longitudeAtEpoch: 181.98, dailyMotion: 1.60213, orbit: 0.19, size: 0.014, color: 0xE8C79A),
        Planet(name: "Earth", longitudeAtEpoch: 100.46, dailyMotion: 0.98561, orbit: 0.27, size: 0.015, color: 0x5B9BD5),
        Planet(name: "Mars", longitudeAtEpoch: 355.43, dailyMotion: 0.52403, orbit: 0.35, size: 0.011, color: 0xD9714E),
        Planet(name: "Jupiter", longitudeAtEpoch: 34.35, dailyMotion: 0.08309, orbit: 0.47, size: 0.03, color: 0xD8B08C),
        Planet(name: "Saturn", longitudeAtEpoch: 50.08, dailyMotion: 0.03346, orbit: 0.6, size: 0.024, color: 0xE3CF9F, hasRings: true),
    ]

    var body: some View {
        let time = TimeFormatting.parts(date, uses24Hour: settings.uses24HourTime)

        GeometryReader { proxy in
            let size = proxy.size
            let unit = size.height
            let sun = CGPoint(x: size.width * 0.27, y: size.height / 2)

            ZStack {
                faceBackground ?? .black

                Canvas { context, _ in
                    for planet in Self.planets {
                        let radius = unit * planet.orbit
                        context.stroke(
                            Path(ellipseIn: CGRect(x: sun.x - radius, y: sun.y - radius, width: radius * 2, height: radius * 2)),
                            with: .color(.white.opacity(0.14)), lineWidth: max(1, unit * 0.0012)
                        )
                    }
                    for planet in Self.planets {
                        draw(planet, around: sun, unit: unit, in: &context)
                    }
                }

                ZStack {
                    RadialGradient(colors: [Color(hex: 0xFFD9A0).opacity(0.35), .clear], center: .center, startRadius: 0, endRadius: unit * 0.18)
                    Circle()
                        .fill(RadialGradient(colors: [Color(hex: 0xFFFBF0), Color(hex: 0xFFE3B0)], center: .center, startRadius: 0, endRadius: unit * 0.05))
                        .frame(width: unit * 0.09, height: unit * 0.09)
                        .shadow(color: Color(hex: 0xFFCF80).opacity(0.8), radius: unit * 0.03)
                }
                .frame(width: unit * 0.36, height: unit * 0.36)
                .position(sun)

                VStack(alignment: .leading, spacing: unit * 0.02) {
                    HStack(alignment: .firstTextBaseline, spacing: unit * 0.015) {
                        Text(time.time)
                            .font(.system(size: unit * 0.13, weight: .light))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        if let period = time.period {
                            Text(period)
                                .font(.system(size: unit * 0.032))
                        }
                    }
                    TrackedCaption(text: FaceText.shortDate(date), size: unit * 0.03)
                }
                .foregroundStyle(.white)
                .position(x: size.width * 0.76, y: size.height / 2)
            }
        }
    }

    private func draw(_ planet: Planet, around sun: CGPoint, unit: CGFloat, in context: inout GraphicsContext) {
        let angle = planet.longitude(at: date) * .pi / 180
        let orbit = unit * planet.orbit
        // Counter-clockwise as seen from above the Sun's north pole.
        let center = CGPoint(x: sun.x + orbit * CGFloat(cos(angle)), y: sun.y - orbit * CGFloat(sin(angle)))
        let radius = unit * planet.size
        let color = Color(hex: planet.color)

        if planet.hasRings {
            let ring = CGRect(x: center.x - radius * 2.1, y: center.y - radius * 0.7, width: radius * 4.2, height: radius * 1.4)
            context.stroke(Path(ellipseIn: ring), with: .color(color.opacity(0.7)), lineWidth: max(1, radius * 0.18))
        }

        // Shade the night side: the lit half faces the Sun.
        let toSun = CGPoint(x: sun.x - center.x, y: sun.y - center.y)
        let distance = max(1, hypot(toSun.x, toSun.y))
        let highlight = CGPoint(x: center.x + toSun.x / distance * radius * 0.5, y: center.y + toSun.y / distance * radius * 0.5)
        context.fill(
            Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
            with: .radialGradient(Gradient(colors: [color, color.opacity(0.75), Color(white: 0.08)]), center: highlight, startRadius: 0, endRadius: radius * 2)
        )
    }
}

#Preview {
    OrbitFace(date: .now)
        .environment(AppSettings())
}
