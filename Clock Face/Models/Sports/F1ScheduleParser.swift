import Foundation

/// Parses a season from the Jolpica F1 API (the Ergast successor),
/// e.g. https://api.jolpi.ca/ergast/f1/2026/races/
enum F1ScheduleParser {
    static func weekends(from data: Data) throws -> [RaceWeekend] {
        let response = try JSONDecoder().decode(Response.self, from: data)
        return response.data.raceTable.races.compactMap(\.weekend).sorted {
            ($0.season, $0.round) < ($1.season, $1.round)
        }
    }

    private struct Response: Decodable {
        let data: MRData

        enum CodingKeys: String, CodingKey { case data = "MRData" }

        struct MRData: Decodable {
            let raceTable: RaceTable
            enum CodingKeys: String, CodingKey { case raceTable = "RaceTable" }
        }

        struct RaceTable: Decodable {
            let races: [Race]
            enum CodingKeys: String, CodingKey { case races = "Races" }
        }
    }

    private struct Race: Decodable {
        let season: String
        let round: String
        let raceName: String
        let circuit: Circuit
        let date: String
        let time: String?
        let firstPractice: SessionTime?
        let secondPractice: SessionTime?
        let thirdPractice: SessionTime?
        let sprintQualifying: SessionTime?
        let sprint: SessionTime?
        let qualifying: SessionTime?

        enum CodingKeys: String, CodingKey {
            case season, round, raceName, date, time
            case circuit = "Circuit"
            case firstPractice = "FirstPractice"
            case secondPractice = "SecondPractice"
            case thirdPractice = "ThirdPractice"
            case sprintQualifying = "SprintQualifying"
            case sprint = "Sprint"
            case qualifying = "Qualifying"
        }

        struct Circuit: Decodable {
            let circuitName: String
            let location: Location
            enum CodingKeys: String, CodingKey {
                case circuitName
                case location = "Location"
            }
        }

        struct Location: Decodable {
            let locality: String
            let country: String
        }

        var weekend: RaceWeekend? {
            guard let season = Int(season), let round = Int(round) else { return nil }
            let weekendID = "\(season)-\(round)"
            let candidates: [(RaceSession.Kind, SessionTime?)] = [
                (.practice1, firstPractice),
                (.practice2, secondPractice),
                (.practice3, thirdPractice),
                (.sprintQualifying, sprintQualifying),
                (.sprint, sprint),
                (.qualifying, qualifying),
                (.race, SessionTime(date: date, time: time)),
            ]
            // Sessions without a published time (TBC) are left out until they're confirmed.
            let sessions = candidates.compactMap { kind, time -> RaceSession? in
                guard let start = time?.start else { return nil }
                return RaceSession(weekendID: weekendID, kind: kind, start: start)
            }
            .sorted { $0.start < $1.start }

            return RaceWeekend(
                season: season,
                round: round,
                name: raceName,
                circuitName: circuit.circuitName,
                locality: circuit.location.locality,
                country: circuit.location.country,
                sessions: sessions
            )
        }
    }

    private struct SessionTime: Decodable {
        let date: String
        let time: String?

        var start: Date? {
            guard let time else { return nil }
            return try? Date("\(date)T\(time)", strategy: .iso8601)
        }
    }
}
