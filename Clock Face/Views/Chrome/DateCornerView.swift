import SwiftUI

struct DateCornerView: View {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM"
        return formatter
    }()

    var body: some View {
        TimelineView(.everyMinute) { context in
            Text(Self.formatter.string(from: context.date))
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color.ink.opacity(0.85))
                .padding(.horizontal, 26)
                .padding(.vertical, 14)
                .background(Capsule().fill(Color.ink.opacity(0.08)))
        }
    }
}
