import Foundation

struct RaceWeekend: Identifiable, Hashable {
    let season: Int
    let round: Int
    let name: String
    let circuitName: String
    let locality: String
    let country: String
    /// Sessions with a confirmed start time, in chronological order.
    let sessions: [RaceSession]

    var id: String { "\(season)-\(round)" }

    var race: RaceSession? { sessions.first { $0.kind == .race } }

    /// The main event's start (the race), falling back to the last session.
    var mainEventStart: Date? { (race ?? sessions.last)?.start }

    /// True once the race (or the weekend's last session) has finished.
    func isFinished(at date: Date) -> Bool {
        guard let last = race ?? sessions.last else { return false }
        return date >= last.end
    }

    func nextSession(after date: Date) -> RaceSession? {
        sessions.first { $0.start > date }
    }

    func liveSession(at date: Date) -> RaceSession? {
        sessions.first { $0.start <= date && date < $0.end }
    }
}

struct RaceSession: Identifiable, Hashable {
    enum Kind: String, CaseIterable {
        case practice1, practice2, practice3, sprintQualifying, sprint, qualifying, race

        var displayName: String {
            switch self {
            case .practice1: return "Practice 1"
            case .practice2: return "Practice 2"
            case .practice3: return "Practice 3"
            case .sprintQualifying: return "Sprint Qualifying"
            case .sprint: return "Sprint"
            case .qualifying: return "Qualifying"
            case .race: return "Race"
            }
        }

        /// Typical session length, used to show a session as live.
        var duration: TimeInterval {
            switch self {
            case .practice1, .practice2, .practice3, .qualifying: return 60 * 60
            case .sprintQualifying: return 45 * 60
            case .sprint: return 45 * 60
            case .race: return 2 * 60 * 60
            }
        }
    }

    let weekendID: String
    let kind: Kind
    let start: Date

    /// Stable across app launches; used as the reminder ID.
    var id: String { "f1-\(weekendID)-\(kind.rawValue)" }
    var end: Date { start.addingTimeInterval(kind.duration) }
}
