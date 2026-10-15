import Foundation

/// Clock-style time strings that honour the app's 12/24-hour setting
/// instead of the device locale.
enum TimeFormatting {
    /// "13:04", or "1:04" with `period` "PM" in 12-hour mode.
    static func parts(_ date: Date, in timeZone: TimeZone = .current, uses24Hour: Bool) -> (time: String, period: String?) {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0

        if uses24Hour {
            return (String(format: "%02d:%02d", hour, minute), nil)
        }
        let hour12 = hour % 12 == 0 ? 12 : hour % 12
        return (String(format: "%d:%02d", hour12, minute), hour >= 12 ? "PM" : "AM")
    }

    static func string(_ date: Date, in timeZone: TimeZone = .current, uses24Hour: Bool) -> String {
        let parts = parts(date, in: timeZone, uses24Hour: uses24Hour)
        return parts.period.map { "\(parts.time) \($0)" } ?? parts.time
    }

    /// "+5h 30m", "−9h", or "Same time" relative to the viewer's time zone.
    static func offsetDescription(for timeZone: TimeZone, at date: Date, relativeTo reference: TimeZone = .current) -> String {
        let seconds = timeZone.secondsFromGMT(for: date) - reference.secondsFromGMT(for: date)
        guard seconds != 0 else { return "Same time" }
        let sign = seconds > 0 ? "+" : "−"
        let hours = abs(seconds) / 3600
        let minutes = (abs(seconds) % 3600) / 60
        return minutes == 0 ? "\(sign)\(hours)h" : "\(sign)\(hours)h \(minutes)m"
    }

    /// "Today", "Tomorrow" or "Yesterday" for `date` as seen in `timeZone`, relative to the viewer's day.
    static func relativeDay(for date: Date, in timeZone: TimeZone, relativeTo reference: TimeZone = .current) -> String {
        var local = Calendar.current
        local.timeZone = reference
        var remote = Calendar.current
        remote.timeZone = timeZone
        let localDay = local.dateComponents([.year, .month, .day], from: date)
        let remoteDay = remote.dateComponents([.year, .month, .day], from: date)
        guard let localDate = Calendar.current.date(from: localDay),
              let remoteDate = Calendar.current.date(from: remoteDay) else { return "Today" }
        switch Calendar.current.dateComponents([.day], from: localDate, to: remoteDate).day ?? 0 {
        case 1: return "Tomorrow"
        case -1: return "Yesterday"
        default: return "Today"
        }
    }
}
