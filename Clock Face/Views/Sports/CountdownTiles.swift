import SwiftUI

/// Days, hours, minutes and seconds until `target`, in the Flip face's tile style.
struct CountdownTiles: View {
    let target: Date
    let now: Date
    var digitSize: CGFloat = 112

    @Environment(AppSettings.self) private var settings

    var body: some View {
        let parts = Self.parts(until: target, from: now)

        HStack(alignment: .top, spacing: 18) {
            tile(parts.days, label: "DAYS")
            tile(parts.hours, label: "HRS")
            tile(parts.minutes, label: "MIN")
            tile(parts.seconds, label: "SEC")
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(parts.days) days, \(parts.hours) hours, \(parts.minutes) minutes, \(parts.seconds) seconds")
        .accessibilityIdentifier("countdown")
    }

    private func tile(_ value: Int, label: String) -> some View {
        VStack(spacing: 12) {
            Text(String(format: "%02d", value))
                .font(.system(size: digitSize, weight: .semibold).width(.compressed))
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
                .foregroundStyle(Color.ink)
                .frame(minWidth: digitSize * 1.05)
                .padding(.horizontal, digitSize * 0.15)
                .padding(.vertical, digitSize * 0.08)
                .background(settings.theme.surface, in: RoundedRectangle(cornerRadius: digitSize * 0.22, style: .continuous))
            Text(label)
                .font(.system(size: 18, weight: .bold))
                .tracking(2)
                .foregroundStyle(Color.ink.opacity(0.5))
        }
        .animation(.snappy(duration: 0.3), value: value)
    }

    static func parts(until target: Date, from now: Date) -> (days: Int, hours: Int, minutes: Int, seconds: Int) {
        let total = max(0, Int(target.timeIntervalSince(now).rounded(.down)))
        return (total / 86_400, (total % 86_400) / 3600, (total % 3600) / 60, total % 60)
    }
}
