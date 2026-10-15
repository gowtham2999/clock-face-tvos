import SwiftUI

/// Hour, minute and second hands plus the pivot cap, sized relative to `radius`.
/// Lengths and widths are fractions of the radius so every face scales from a
/// gallery thumbnail up to a full TV screen.
struct AnalogHands: View {
    let angles: ClockAngles
    let radius: CGFloat

    var handColor: Color = .white
    var secondColor: Color = .orange
    var hourLength: CGFloat = 0.5
    var minuteLength: CGFloat = 0.8
    var handWidth: CGFloat = 0.06
    var secondLength: CGFloat = 0.92
    var secondTail: CGFloat = 0.18
    var secondWidth: CGFloat = 0.008
    var shadowColor: Color = .clear
    var shadowRadius: CGFloat = 0

    var body: some View {
        ZStack {
            hand(length: radius * hourLength, angle: angles.hour)
            hand(length: radius * minuteLength, angle: angles.minute)

            secondHand

            CenterPivotDot(color: secondColor, diameter: radius * 0.05)
        }
    }

    private func hand(length: CGFloat, angle: Double) -> some View {
        HourMinuteHandShape()
            .fill(handColor)
            .frame(width: radius * handWidth, height: length)
            // Shift up so the hand's bottom (pivot) sits at the frame center,
            // which is where rotationEffect rotates around.
            .offset(y: -length / 2)
            .rotationEffect(.degrees(angle))
            .shadow(color: shadowColor, radius: shadowRadius)
    }

    private var secondHand: some View {
        let long = radius * secondLength
        let tail = radius * secondTail
        let width = max(1.5, radius * secondWidth)
        return SecondHandShape()
            .stroke(secondColor, style: StrokeStyle(lineWidth: width, lineCap: .round))
            .frame(width: width, height: long + tail)
            .offset(y: -(long - tail) / 2)
            .rotationEffect(.degrees(angles.second))
    }
}
