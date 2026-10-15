import SwiftUI

struct CenterPivotDot: View {
    let color: Color
    let diameter: CGFloat

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: diameter, height: diameter)
    }
}
