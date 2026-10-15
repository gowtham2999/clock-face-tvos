import Foundation

/// Shifts the Clock tab's time in Debug builds only, so screenshots and UI tests can
/// show a chosen moment: launch with `-UITestStartTime 2026-10-15T18:10:00+05:30`
/// and the clock starts there, then keeps running normally.
enum DebugClock {
    static func adjusted(_ date: Date) -> Date {
        #if DEBUG
        return date.addingTimeInterval(offset)
        #else
        return date
        #endif
    }

    #if DEBUG
    private static let offset: TimeInterval = {
        guard let string = UserDefaults.standard.string(forKey: "UITestStartTime"),
              let start = try? Date(string, strategy: .iso8601) else { return 0 }
        return start.timeIntervalSinceNow
    }()
    #endif
}
