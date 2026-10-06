import SwiftUI

/// Two large rounded boxes, hours and minutes, in a tall condensed typeface,
/// with an AM/PM tag in the corner of the hours box when using 12-hour time.
struct FlipClockFace: WatchFace {
    let date: Date

    @Environment(AppSettings.self) private var settings

    private let boxSpacing: CGFloat = 50
    // Leaves room for the top bar above and the date pill below.
    private let topInset: CGFloat = 110
    private let bottomInset: CGFloat = 90

    init(date: Date) {
        self.date = date
    }

    var body: some View {
        let time = displayTime

        GeometryReader { proxy in
            let boxWidth = (proxy.size.width - boxSpacing) / 2
            let boxHeight = proxy.size.height
            let digitSize = min(boxHeight * 0.78, boxWidth * 1.05)

            HStack(spacing: boxSpacing) {
                box {
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

                box {
                    digits(time.minutes, size: digitSize)
                        .accessibilityIdentifier("flipMinutes")
                }
            }
        }
        .padding(.top, topInset)
        .padding(.bottom, bottomInset)
        .animation(.snappy(duration: 0.35), value: time.hours + time.minutes)
    }

    private func box<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        RoundedRectangle(cornerRadius: 50, style: .continuous)
            .fill(settings.theme.surface)
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

    // MARK: - Time

    private var displayTime: (hours: String, minutes: String, period: String?) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        var hour = components.hour ?? 0
        let minute = components.minute ?? 0

        var period: String?
        if !settings.uses24HourTime {
            period = hour >= 12 ? "PM" : "AM"
            hour = hour % 12 == 0 ? 12 : hour % 12
        }
        return (String(format: "%02d", hour), String(format: "%02d", minute), period)
    }
}

#Preview {
    FlipClockFace(date: .now)
        .environment(AppSettings())
        .background(Color(white: 0.085))
}
