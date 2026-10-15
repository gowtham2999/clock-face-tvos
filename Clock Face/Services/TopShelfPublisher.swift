import SwiftUI
import TVServices

/// One Top Shelf card. Mirrored by the Top Shelf extension
/// (Clock Face TopShelf/ContentProvider.swift), which decodes the same JSON.
struct TopShelfEntry: Codable, Equatable {
    let id: String
    let title: String
    let sectionTitle: String
    let imageFileName: String
    let url: String
}

/// Writes Top Shelf entries and their card images into the App Group container,
/// then asks tvOS to reload the Top Shelf. Shows upcoming reminders, or the
/// next race when there are none.
enum TopShelfPublisher {
    static let indexFileName = "entries.json"
    static let maxItems = 6

    static func publish(reminders: [Reminder], nextWeekend: RaceWeekend?, uses24Hour: Bool, now: Date = .now) {
        guard let directory = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: ReminderStore.appGroupID)?
            .appending(path: "TopShelf", directoryHint: .isDirectory) else { return }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let cards = makeCards(reminders: reminders, nextWeekend: nextWeekend, uses24Hour: uses24Hour, now: now)

        var entries: [TopShelfEntry] = []
        for (entry, card) in cards {
            let renderer = ImageRenderer(content: card.frame(width: 908, height: 512))
            renderer.scale = 2
            guard let png = renderer.uiImage?.pngData() else { continue }
            try? png.write(to: directory.appending(path: entry.imageFileName))
            entries.append(entry)
        }

        removeStaleImages(in: directory, keeping: Set(entries.map(\.imageFileName)))
        if let data = try? JSONEncoder().encode(entries) {
            try? data.write(to: directory.appending(path: indexFileName))
        }
        TVTopShelfContentProvider.topShelfContentDidChange()
    }

    private static func makeCards(reminders: [Reminder], nextWeekend: RaceWeekend?, uses24Hour: Bool, now: Date) -> [(TopShelfEntry, TopShelfCard)] {
        let upcoming = reminders.filter { $0.start > now }.prefix(maxItems)

        if upcoming.isEmpty {
            guard let weekend = nextWeekend, let race = weekend.race, race.start > now else { return [] }
            let id = "next-\(weekend.id)"
            return [(
                TopShelfEntry(id: id, title: "\(weekend.name) · Race", sectionTitle: "Next Race",
                              imageFileName: "\(id).png", url: "clockface://sports/f1/\(weekend.id)"),
                TopShelfCard(caption: "NEXT RACE · FORMULA 1", title: weekend.name,
                             detail: "Race · \(SessionTimeText.string(for: race.start, uses24Hour: uses24Hour))")
            )]
        }

        return upcoming.map { reminder in
            (
                TopShelfEntry(id: reminder.id, title: "\(reminder.eventName) · \(reminder.sessionName)",
                              sectionTitle: "Your Reminders", imageFileName: "\(reminder.id).png",
                              url: "clockface://sports/f1/\(reminder.weekendID)"),
                TopShelfCard(caption: "REMINDER · \(reminder.seriesName.uppercased())", title: reminder.eventName,
                             detail: "\(reminder.sessionName) · \(SessionTimeText.string(for: reminder.start, uses24Hour: uses24Hour))")
            )
        }
    }

    private static func removeStaleImages(in directory: URL, keeping names: Set<String>) {
        let files = (try? FileManager.default.contentsOfDirectory(atPath: directory.path())) ?? []
        for file in files where file.hasSuffix(".png") && !names.contains(file) {
            try? FileManager.default.removeItem(at: directory.appending(path: file))
        }
    }
}

/// The artwork for one Top Shelf card (rendered to PNG at 908×512 pt, @2x).
struct TopShelfCard: View {
    let caption: String
    let title: String
    let detail: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [Color(hex: 0x141418), Color(hex: 0x2A0D10)], startPoint: .topLeading, endPoint: .bottomTrailing)

            Image(systemName: "flag.checkered")
                .font(.system(size: 260))
                .foregroundStyle(.white.opacity(0.06))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(40)

            Rectangle()
                .fill(Color.racingRed)
                .frame(width: 14)
                .frame(maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 12) {
                Text(caption)
                    .font(.system(size: 26, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Color.racingRed)
                Text(title)
                    .font(.system(size: 60, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Text(detail)
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.leading, 56)
            .padding([.trailing, .bottom], 48)
        }
    }
}
