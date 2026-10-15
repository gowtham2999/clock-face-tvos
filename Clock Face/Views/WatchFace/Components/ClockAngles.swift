import Foundation

/// Hand angles in degrees, clockwise from 12, for a ticking (per-second) movement.
struct ClockAngles {
    let hour: Double
    let minute: Double
    let second: Double

    init(date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.hour, .minute, .second], from: date)
        let hours = Double((components.hour ?? 0) % 12)
        let minutes = Double(components.minute ?? 0)
        let seconds = Double(components.second ?? 0)
        hour = (hours + minutes / 60) * 30
        minute = (minutes + seconds / 60) * 6
        second = seconds * 6
    }
}
