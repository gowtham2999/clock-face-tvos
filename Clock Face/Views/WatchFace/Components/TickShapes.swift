import SwiftUI

/// Tick marks on a circle centred in the rect, between `innerRadius` and `outerRadius`.
/// `skipEvery` leaves out every nth tick (e.g. 5 to leave gaps for hour marks).
struct RadialTicks: Shape {
    var count: Int
    var innerRadius: CGFloat
    var outerRadius: CGFloat
    var skipEvery: Int? = nil

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        for index in 0..<count {
            if let skipEvery, index % skipEvery == 0 { continue }
            let angle = Double(index) / Double(count) * 2 * .pi
            let dx = CGFloat(sin(angle))
            let dy = CGFloat(-cos(angle))
            path.move(to: CGPoint(x: center.x + dx * innerRadius, y: center.y + dy * innerRadius))
            path.addLine(to: CGPoint(x: center.x + dx * outerRadius, y: center.y + dy * outerRadius))
        }
        return path
    }
}

/// Radial tick marks whose outer ends sit on the rect's edges (inset by `inset`),
/// so a face can fill the whole 16:9 screen instead of drawing a round dial.
struct EdgeTicks: Shape {
    var count: Int
    var length: CGFloat
    var inset: CGFloat
    var skipEvery: Int? = nil

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let halfWidth = rect.width / 2 - inset
        let halfHeight = rect.height / 2 - inset
        var path = Path()
        for index in 0..<count {
            if let skipEvery, index % skipEvery == 0 { continue }
            let angle = Double(index) / Double(count) * 2 * .pi
            let dx = CGFloat(sin(angle))
            let dy = CGFloat(-cos(angle))
            // Distance along the ray to the first edge it hits.
            let toSide = abs(dx) > 0.0001 ? halfWidth / abs(dx) : .greatestFiniteMagnitude
            let toTopOrBottom = abs(dy) > 0.0001 ? halfHeight / abs(dy) : .greatestFiniteMagnitude
            let outer = min(toSide, toTopOrBottom)
            let inner = max(0, outer - length)
            path.move(to: CGPoint(x: center.x + dx * inner, y: center.y + dy * inner))
            path.addLine(to: CGPoint(x: center.x + dx * outer, y: center.y + dy * outer))
        }
        return path
    }
}
