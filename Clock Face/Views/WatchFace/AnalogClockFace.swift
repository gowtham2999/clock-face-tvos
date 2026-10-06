import SwiftUI

struct AnalogClockFace: WatchFace {
    let date: Date

    @Environment(AppSettings.self) private var settings

    private var accentColor: Color { settings.accentColor.color }

    init(date: Date) {
        self.date = date
    }

    var body: some View {
        GeometryReader { proxy in
            let radius = min(proxy.size.width, proxy.size.height) / 2 * 0.95

            ZStack {
                ClockNumeralsView(radius: radius)

                hand(length: radius * 0.5, width: radius * 0.075, angle: angles.hour)
                hand(length: radius * 0.78, width: radius * 0.075, angle: angles.minute)
                secondHand(radius: radius)

                CenterPivotDot(color: accentColor, diameter: radius * 0.06)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    // MARK: - Hands

    private func hand(length: CGFloat, width: CGFloat, angle: Double) -> some View {
        HourMinuteHandShape()
            .fill(Color.ink)
            .frame(width: width, height: length)
            // Shift up so the hand's bottom (pivot) sits at the frame center,
            // which is where rotationEffect rotates around.
            .offset(y: -length / 2)
            .rotationEffect(.degrees(angle))
            .shadow(color: .black.opacity(0.35), radius: 6)
    }

    private func secondHand(radius: CGFloat) -> some View {
        let long = radius * 0.92
        let tail = radius * 0.2
        return SecondHandShape()
            .stroke(accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .frame(width: 3, height: long + tail)
            .offset(y: -(long - tail) / 2)
            .rotationEffect(.degrees(angles.second))
    }

    // MARK: - Time

    private var angles: (hour: Double, minute: Double, second: Double) {
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        let hours = Double((components.hour ?? 0) % 12)
        let minutes = Double(components.minute ?? 0)
        let seconds = Double(components.second ?? 0)
        return (
            hour: (hours + minutes / 60) * 30,
            minute: (minutes + seconds / 60) * 6,
            second: seconds * 6
        )
    }
}

#Preview {
    AnalogClockFace(date: .now)
        .environment(AppSettings())
        .background(Color.inkInverse)
}
