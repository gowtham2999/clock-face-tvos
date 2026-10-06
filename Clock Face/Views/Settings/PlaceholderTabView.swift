import SwiftUI

struct PlaceholderTabView: View {
    let title: String

    var body: some View {
        VStack(spacing: 14) {
            Text(title)
                .font(.system(size: 64, weight: .black, design: .rounded))
                .foregroundStyle(Color.ink.opacity(0.25))
            Text("Coming soon")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(Color.ink.opacity(0.4))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
