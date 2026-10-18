import SwiftUI

/// "Flip": two large rounded tiles, hours and minutes, in a tall condensed typeface,
/// with an AM/PM tag in the corner of the hours tile when using 12-hour time.
struct FlipClockFace: WatchFace {
    let date: Date

    @Environment(AppSettings.self) private var settings
    @Environment(\.faceBackground) private var faceBackground

    init(date: Date) {
        self.date = date
    }

    var body: some View {
        let time = displayTime

        GeometryReader { proxy in
            let size = proxy.size
            // Proportions taken from a 1920×1080 layout: 80pt side margins,
            // 140pt top/bottom margins, 50pt gap, 50pt corner radius.
            let horizontalInset = size.width * 0.042
            let verticalInset = size.height * 0.13
            let spacing = size.width * 0.026
            let boxWidth = (size.width - horizontalInset * 2 - spacing) / 2
            let boxHeight = size.height - verticalInset * 2
            let digitSize = min(boxHeight * 0.78, boxWidth * 1.05)

            ZStack {
                faceBackground ?? settings.theme.background

                HStack(spacing: spacing) {
                    tile(cornerRadius: size.height * 0.046) {
                        digits(time.hours, size: digitSize)
                            .accessibilityIdentifier("flipHours")
                    }
                    .overlay(alignment: .bottomLeading) {
                        if let period = time.period {
                            Text(period)
                                .font(.system(size: boxHeight * 0.09, weight: .semibold).width(.compressed))
                                .foregroundStyle(Color.ink)
                                .padding(.leading, boxWidth * 0.1)
                                .padding(.bottom, boxHeight * 0.06)
                        }
                    }

                    tile(cornerRadius: size.height * 0.046) {
                        digits(time.minutes, size: digitSize)
                            .accessibilityIdentifier("flipMinutes")
                    }
                }
                .padding(.horizontal, horizontalInset)
                .padding(.vertical, verticalInset)
            }
        }
        .animation(.snappy(duration: 0.35), value: time.hours + time.minutes)
    }

    private func tile<Content: View>(cornerRadius: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            // Inside a dashboard tile the tile is already the surface colour, so lift the boxes.
            .fill(faceBackground == nil ? settings.theme.surface : Color.ink.opacity(0.07))
            .overlay(content())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func digits(_ text: String, size: CGFloat) -> some View {
        Text(text)
            .font(.system(size: size, weight: .semibold).width(.compressed))
            .monospacedDigit()
            .foregroundStyle(Color.ink)
            .contentTransition(.numericText())
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }

    private var displayTime: (hours: String, minutes: String, period: String?) {
        let parts = TimeFormatting.parts(date, uses24Hour: settings.uses24HourTime)
        let pieces = parts.time.split(separator: ":").map(String.init)
        let hours = pieces.first.map { $0.count == 1 ? "0" + $0 : $0 } ?? "00"
        return (hours, pieces.last ?? "00", parts.period)
    }
}

#Preview {
    FlipClockFace(date: .now)
        .environment(AppSettings())
}
