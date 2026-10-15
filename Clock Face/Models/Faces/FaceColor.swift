import SwiftUI

/// One colour choice in a face's palette. `primary` is the face's main colour
/// (the dial, or the accent on faces with a neutral dial); `secondary` is a
/// companion colour each face uses its own way (hand colour, gradient stop).
struct FaceColor: Identifiable, Equatable {
    let id: String
    let name: String
    let primary: Color
    var secondary: Color = .white
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
