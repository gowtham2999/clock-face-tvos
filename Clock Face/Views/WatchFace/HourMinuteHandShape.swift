import SwiftUI

/// A chunky rounded hand drawn pivot-at-bottom: a narrow stem leaves the pivot,
/// then widens into the full-width rounded body. The narrow stem is the "notch"
/// that keeps the center point readable where the hands overlap.
struct HourMinuteHandShape: Shape {
    /// Fraction of the hand's length taken up by the narrow stem.
    var stemFraction: CGFloat = 0.14
    /// Stem width as a fraction of the body width.
    var stemWidthFraction: CGFloat = 0.38

    func path(in rect: CGRect) -> Path {
        let stemLength = rect.height * stemFraction
        let stemWidth = rect.width * stemWidthFraction

        var path = Path()
        path.addRoundedRect(
            in: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - stemLength),
            cornerSize: CGSize(width: rect.width / 2, height: rect.width / 2)
        )
        // Overlaps the body slightly so the two pieces read as one shape.
        path.addRoundedRect(
            in: CGRect(
                x: rect.midX - stemWidth / 2,
                y: rect.maxY - stemLength - rect.width / 2,
                width: stemWidth,
                height: stemLength + rect.width / 2
            ),
            cornerSize: CGSize(width: stemWidth / 2, height: stemWidth / 2)
        )
        return path
    }
}
