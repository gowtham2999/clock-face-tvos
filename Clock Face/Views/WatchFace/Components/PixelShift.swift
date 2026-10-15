import CoreGraphics
import Foundation

/// Burn-in protection for OLED TVs: moves the face around a small circle,
/// one step per minute, so static marks never sit on the same pixels for long.
enum PixelShift {
    static let radius: CGFloat = 6
    static let steps = 8
    /// Scale applied alongside the shift so full-bleed backgrounds never reveal an edge.
    static let overscanScale: CGFloat = 1.015

    static func offset(at date: Date) -> CGSize {
        let minute = Int(date.timeIntervalSince1970 / 60)
        let angle = Double(minute % steps) / Double(steps) * 2 * .pi
        return CGSize(width: radius * CGFloat(cos(angle)), height: radius * CGFloat(sin(angle)))
    }
}
