import SwiftUI

/// The faint 12 / 3 / 6 / 9 numerals at the compass points, pulled in toward
/// the center since the face has no bezel.
struct ClockNumeralsView: View {
    let radius: CGFloat

    private let numerals: [(text: String, angle: Double)] = [
        ("12", 0), ("3", 90), ("6", 180), ("9", 270)
    ]

    var body: some View {
        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            ForEach(numerals, id: \.text) { numeral in
                Text(numeral.text)
                    .font(.system(size: radius * 0.66, weight: .black, design: .rounded))
                    .foregroundStyle(Color.ink.opacity(0.12))
                    .fixedSize()
                    .position(position(for: numeral.angle, center: center))
            }
        }
    }

    private func position(for angleDegrees: Double, center: CGPoint) -> CGPoint {
        let distance = radius * 0.6
        let radians = CGFloat((angleDegrees - 90) * .pi / 180)
        return CGPoint(
            x: center.x + distance * cos(radians),
            y: center.y + distance * sin(radians)
        )
    }
}
