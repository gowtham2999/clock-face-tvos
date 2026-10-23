import SwiftUI

/// "Circle": a ring of fine minute ticks where the passing seconds leave a
/// glowing trail in the accent colour, slim hands, and the date to the side.
struct CircleFace: WatchFace {
    let date: Date

    @Environment(AppSettings.self) private var settings
    @Environment(\.faceBackground) private var faceBackground

    init(date: Date) {
        self.date = date
    }

    /// How many ticks behind the second hand still glow.
    private static let trailLength = 20.0

    var body: some View {
        let accent = settings.color(for: .circle)?.primary ?? .orange
        let angles = ClockAngles(date: date)
        let second = Calendar.current.component(.second, from: date)

        GeometryReader { proxy in
            let size = proxy.size
            let unit = size.height
            let radius = unit * 0.4

            ZStack {
                faceBackground ?? .black

                ZStack {
                    Canvas { context, canvasSize in
                        drawTicks(in: &context, size: canvasSize, radius: radius, second: second, accent: accent)
                    }

                    AnalogHands(
                        angles: angles,
                        radius: radius,
                        handColor: .white,
                        secondColor: .white,
                        hourLength: 0.5,
                        minuteLength: 0.8,
                        handWidth: 0.022,
                        secondLength: 0.9,
                        secondTail: 0.14,
                        secondWidth: 0.005
                    )
                }
                .frame(width: radius * 2.2, height: radius * 2.2)
                .position(x: size.width * 0.42, y: size.height / 2)

                VStack(alignment: .leading, spacing: unit * 0.018) {
                    TrackedCaption(text: FaceText.weekday(date), size: unit * 0.034)
                    TrackedCaption(text: FaceText.monthDay(date), size: unit * 0.034)
                }
                .foregroundStyle(.white)
                .position(x: size.width * 0.42 + radius * 1.45, y: size.height / 2)
            }
        }
    }

    private func drawTicks(in context: inout GraphicsContext, size: CGSize, radius: CGFloat, second: Int, accent: Color) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        for index in 0..<60 {
            let angle = CGFloat(index) / 60 * 2 * .pi
            let isHour = index % 5 == 0
            // Ticks the second hand has just passed glow, fading with age.
            let age = Double((second - index + 60) % 60)
            let glow = age < Self.trailLength ? 1 - age / Self.trailLength : 0

            let inner = radius * (isHour ? 0.86 : 0.9)
            var tick = Path()
            tick.move(to: CGPoint(x: center.x + inner * sin(angle), y: center.y - inner * cos(angle)))
            tick.addLine(to: CGPoint(x: center.x + radius * sin(angle), y: center.y - radius * cos(angle)))

            let base = Color.white.opacity(isHour ? 0.85 : 0.4)
            let width = max(1, radius * (isHour ? 0.012 : 0.007))
            context.stroke(tick, with: .color(base), style: StrokeStyle(lineWidth: width, lineCap: .round))
            if glow > 0 {
                context.stroke(tick, with: .color(accent.opacity(pow(glow, 1.4))), style: StrokeStyle(lineWidth: width * 1.6, lineCap: .round))
            }
        }
    }
}

#Preview {
    CircleFace(date: .now)
        .environment(AppSettings())
}
