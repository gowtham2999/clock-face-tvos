import Foundation
import Observation
import UserNotifications

struct Reminder: Codable, Identifiable, Hashable {
    /// Same as the session ID, e.g. "f1-2026-18-race".
    let id: String
    let seriesName: String
    let eventName: String
    let sessionName: String
    let start: Date
    let weekendID: String
    var hasBeenPresented = false

    var alertDate: Date { start.addingTimeInterval(-ReminderStore.leadTime) }
}

/// tvOS notifications can only badge the app icon (no banner, text or sound),
/// so this is the only system-level part of a reminder. Behind a protocol for tests.
protocol ReminderBadgeScheduling {
    func schedule(_ reminder: Reminder)
    func cancel(reminderID: String)
    func clearBadge()
}

/// Session reminders. While the app is open, a due reminder is shown full screen
/// (`dueReminder(at:)`); otherwise the app icon is badged at alert time.
@Observable
final class ReminderStore {
    static let leadTime: TimeInterval = 15 * 60
    /// How long after the start a reminder that couldn't be shown still pops up.
    static let lateWindow: TimeInterval = 5 * 60
    static let appGroupID = "group.gowtham.Clock-Face"
    private static let storageKey = "reminders"

    private(set) var reminders: [Reminder] = []

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let scheduler: ReminderBadgeScheduling

    init(
        defaults: UserDefaults = UserDefaults(suiteName: ReminderStore.appGroupID) ?? .standard,
        scheduler: ReminderBadgeScheduling = BadgeNotificationScheduler(),
        now: Date = .now
    ) {
        self.defaults = defaults
        self.scheduler = scheduler
        if let data = defaults.data(forKey: Self.storageKey),
           let stored = try? JSONDecoder().decode([Reminder].self, from: data) {
            reminders = stored.filter { $0.start > now.addingTimeInterval(-24 * 60 * 60) }
        }
    }

    func isSet(for sessionID: String) -> Bool {
        reminders.contains { $0.id == sessionID }
    }

    func upcoming(after date: Date) -> [Reminder] {
        reminders.filter { $0.start > date }
    }

    /// Adds a reminder for a future session, or removes the existing one.
    func toggle(session: RaceSession, in weekend: RaceWeekend, seriesName: String, now: Date = .now) {
        if let index = reminders.firstIndex(where: { $0.id == session.id }) {
            reminders.remove(at: index)
            scheduler.cancel(reminderID: session.id)
        } else {
            guard session.start > now else { return }
            let reminder = Reminder(
                id: session.id,
                seriesName: seriesName,
                eventName: weekend.name,
                sessionName: session.kind.displayName,
                start: session.start,
                weekendID: weekend.id
            )
            reminders.append(reminder)
            reminders.sort { $0.start < $1.start }
            scheduler.schedule(reminder)
        }
        save()
    }

    /// The reminder to show full screen now, if any: within 15 minutes of the
    /// start (or up to 5 minutes late) and not already shown.
    func dueReminder(at date: Date) -> Reminder? {
        reminders.first {
            !$0.hasBeenPresented && date >= $0.alertDate && date < $0.start.addingTimeInterval(Self.lateWindow)
        }
    }

    func markPresented(_ reminder: Reminder) {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        reminders[index].hasBeenPresented = true
        save()
        scheduler.clearBadge()
    }

    func clearBadge() {
        scheduler.clearBadge()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(reminders) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }
}

struct BadgeNotificationScheduler: ReminderBadgeScheduling {
    func schedule(_ reminder: Reminder) {
        let alertDate = reminder.alertDate
        guard alertDate > .now else { return }
        Task {
            let center = UNUserNotificationCenter.current()
            guard (try? await center.requestAuthorization(options: [.badge])) == true else { return }
            let content = UNMutableNotificationContent()
            content.badge = 1
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: alertDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger))
        }
    }

    func cancel(reminderID: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderID])
    }

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0, withCompletionHandler: nil)
    }
}
