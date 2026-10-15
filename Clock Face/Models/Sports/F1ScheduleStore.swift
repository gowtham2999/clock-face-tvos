import Foundation
import Observation

/// The F1 calendar: starts from the copy bundled with the app (or the last
/// download), then refreshes from the Jolpica API. Rolls over to next season
/// once the current one has no races left.
@Observable
final class F1ScheduleStore {
    private(set) var weekends: [RaceWeekend] = []
    /// The weekend shown on the F1 page; nil means "the next one".
    var selectedWeekendID: String?

    @ObservationIgnored private let session: URLSession

    init(session: URLSession = .shared, now: Date = .now) {
        self.session = session
        let year = Calendar.current.component(.year, from: now)
        weekends = Self.cachedWeekends(for: year) ?? Self.bundledWeekends() ?? []
    }

    func nextWeekend(after date: Date) -> RaceWeekend? {
        weekends.first { !$0.isFinished(at: date) }
    }

    func weekend(withID id: String?) -> RaceWeekend? {
        guard let id else { return nil }
        return weekends.first { $0.id == id }
    }

    func refresh(now: Date = .now) async {
        let year = Calendar.current.component(.year, from: now)
        if let current = await download(season: year), !current.isEmpty {
            weekends = current
        }
        if nextWeekend(after: now) == nil, let next = await download(season: year + 1), !next.isEmpty {
            weekends = next
        }
    }

    // MARK: - Loading

    private func download(season: Int) async -> [RaceWeekend]? {
        guard let url = URL(string: "https://api.jolpi.ca/ergast/f1/\(season)/races/?limit=100") else { return nil }
        do {
            let (data, response) = try await session.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let weekends = try F1ScheduleParser.weekends(from: data)
            if !weekends.isEmpty {
                try? data.write(to: Self.cacheURL(for: season))
            }
            return weekends
        } catch {
            return nil
        }
    }

    private static func cacheURL(for season: Int) -> URL {
        URL.cachesDirectory.appending(path: "f1-\(season).json")
    }

    private static func cachedWeekends(for season: Int) -> [RaceWeekend]? {
        guard let data = try? Data(contentsOf: cacheURL(for: season)) else { return nil }
        return try? F1ScheduleParser.weekends(from: data)
    }

    private static func bundledWeekends() -> [RaceWeekend]? {
        guard let url = Bundle.main.url(forResource: "f1-2026", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? F1ScheduleParser.weekends(from: data)
    }
}
