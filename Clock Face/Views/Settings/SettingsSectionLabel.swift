import SwiftUI

struct SettingsSectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 20, weight: .bold))
            .tracking(1.5)
            .foregroundStyle(Color.ink.opacity(0.45))
    }
}
