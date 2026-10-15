import SwiftUI

/// "Daylight": a luminous dial lit by a soft beam that follows the sun around the
/// screen through the day — east (left) at dawn, top at noon, west (right) at dusk —
/// and dims overnight.
struct DaylightFace: WatchFace {
    let date: Date

    @Environment(AppSettings.self) private var settings

    init(date: Date) {
        self.date = date
    }

    var body: some View {
        let color = settings.color(for: .daylight) ?? WatchFaceType.daylight.palette[0]
        let light = sunlight

        GeometryReader { proxy in
            let size = proxy.size
            let reach = hypot(size.width, size.height) / 2

            ZStack {
                RadialGradient(
                    colors: [color.primary.mix(with: color.secondary, by: 0.2), color.primary],
                    center: .center,
                    startRadius: 0,
                    endRadius: max(size.width, size.height) * 0.75
                )

                beam(color: color.secondary, width: size.width * 0.45, reach: reach,
                     opacity: 0.18 * light.intensity, blur: size.width * 0.06, angle: light.angle)
                beam(color: color.secondary, width: size.width * 0.14, reach: reach,
                     opacity: 0.6 * light.intensity, blur: size.width * 0.022, angle: light.angle)

                EdgeTicks(count: 60, length: size.height * 0.03, inset: size.height * 0.03, skipEvery: 5)
                    .stroke(color.secondary.opacity(0.45), lineWidth: max(1, size.height * 0.002))
                EdgeTicks(count: 12, length: size.height * 0.2, inset: size.height * 0.03)
                    .stroke(color.secondary.opacity(0.7), lineWidth: max(1, size.height * 0.004))

                AnalogHands(
                    angles: ClockAngles(date: date),
                    radius: size.height * 0.46,
                    handColor: .white,
                    secondColor: color.secondary,
                    hourLength: 0.45,
                    minuteLength: 0.8,
                    handWidth: 0.035,
                    secondLength: 0.95,
                    secondTail: 0.15,
                    secondWidth: 0.005,
                    shadowColor: color.secondary.opacity(0.9),
                    shadowRadius: size.height * 0.012
                )
            }
        }
    }

    /// A band of light from the centre towards the sun's direction, brightest at the edge.
    private func beam(color: Color, width: CGFloat, reach: CGFloat, opacity: Double, blur: CGFloat, angle: Double) -> some View {
        Rectangle()
            .fill(LinearGradient(
                colors: [color.opacity(opacity * 0.15), color.opacity(opacity)],
                startPoint: .bottom,
                endPoint: .top
            ))
            .frame(width: width, height: reach)
            .offset(y: -reach / 2)
            .rotationEffect(.degrees(angle))
            .blur(radius: blur)
    }

    /// Direction of the light (degrees clockwise from 12) and its strength (0.35 at night, 1 at noon).
    private var sunlight: (angle: Double, intensity: Double) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hourOfDay = Double(components.hour ?? 0) + Double(components.minute ?? 0) / 60
        let daylight = max(0, sin((hourOfDay - 6) / 12 * .pi))
        return (hourOfDay / 24 * 360 + 180, 0.35 + 0.65 * daylight)
    }
}

#Preview {
    DaylightFace(date: .now)
        .environment(AppSettings())
}
