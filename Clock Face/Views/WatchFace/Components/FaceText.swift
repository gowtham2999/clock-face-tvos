import SwiftUI

/// Time and date strings shared by the typographic faces.
enum FaceText {
    /// Two-digit hours and minutes for large stacked type ("09", "41"),
    /// with "AM"/"PM" in 12-hour mode.
    static func digits(_ date: Date, in timeZone: TimeZone = .current, uses24Hour: Bool) -> (hours: String, minutes: String, period: String?) {
        let parts = TimeFormatting.parts(date, in: timeZone, uses24Hour: uses24Hour)
        let pieces = parts.time.split(separator: ":").map(String.init)
        let hours = pieces.first.map { $0.count == 1 ? "0" + $0 : $0 } ?? "00"
        return (hours, pieces.last ?? "00", parts.period)
    }

    /// "SAT"
    static func weekday(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated)).uppercased()
    }

    /// "OCT 17"
    static func monthDay(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day()).uppercased()
    }

    /// "SAT, OCT 17"
    static func shortDate(_ date: Date) -> String {
        "\(weekday(date)), \(monthDay(date))"
    }
}

/// The small, widely tracked caps used for dates on the minimal faces.
struct TrackedCaption: View {
    let text: String
    let size: CGFloat
    var opacity: Double = 0.7

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .medium))
            .tracking(size * 0.28)
            .opacity(opacity)
            .lineLimit(1)
    }
}
