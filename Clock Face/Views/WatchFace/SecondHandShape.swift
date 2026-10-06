import SwiftUI

/// A straight vertical line spanning the rect. `AnalogClockFace` sizes and offsets it
/// so the pivot falls between a long end and a short counterbalance tail.
struct SecondHandShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}
