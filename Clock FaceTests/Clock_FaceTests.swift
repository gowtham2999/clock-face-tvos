//
//  Clock_FaceTests.swift
//  Clock FaceTests
//
//  Created by Web2 on 06/10/26.
//

import Foundation
import Testing
@testable import Clock_Face

private func date(_ iso: String) -> Date {
    try! Date(iso, strategy: .iso8601)
}

private func freshDefaults() -> UserDefaults {
    let name = "ClockFaceTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defaults.removePersistentDomain(forName: name)
    return defaults
}

struct F1ScheduleParserTests {
    private func bundledWeekends() throws -> [RaceWeekend] {
        let url = try #require(Bundle.main.url(forResource: "f1-2026", withExtension: "json"))
        return try F1ScheduleParser.weekends(from: Data(contentsOf: url))
    }

    @Test func parsesTheFullBundledSeason() throws {
        let weekends = try bundledWeekends()
        #expect(weekends.count == 23)
        #expect(weekends.map(\.round) == Array(1...23))
    }

    @Test func readsRaceDetailsAndStartTime() throws {
        let austin = try #require(try bundledWeekends().first { $0.round == 18 })
        #expect(austin.name == "United States Grand Prix")
        #expect(austin.locality == "Austin")
        #expect(austin.race?.start == date("2026-10-25T20:00:00Z"))
    }

    @Test func ordersSprintWeekendSessionsChronologically() throws {
        let shanghai = try #require(try bundledWeekends().first { $0.round == 2 })
        #expect(shanghai.sessions.map(\.kind) == [.practice1, .sprintQualifying, .sprint, .qualifying, .race])
    }

    @Test func nextWeekendSkipsFinishedRaces() throws {
        let weekends = try bundledWeekends()
        let next = weekends.first { !$0.isFinished(at: date("2026-10-15T12:00:00Z")) }
        #expect(next?.round == 18)
    }
}

private final class RecordingScheduler: ReminderBadgeScheduling {
    var scheduled: [String] = []
    var cancelled: [String] = []
    func schedule(_ reminder: Reminder) { scheduled.append(reminder.id) }
    func cancel(reminderID: String) { cancelled.append(reminderID) }
    func clearBadge() {}
}

struct ReminderStoreTests {
    private let raceStart = date("2026-10-25T20:00:00Z")

    private func weekend() -> (RaceWeekend, RaceSession) {
        let race = RaceSession(weekendID: "2026-18", kind: .race, start: raceStart)
        let weekend = RaceWeekend(season: 2026, round: 18, name: "United States Grand Prix", circuitName: "COTA",
                                  locality: "Austin", country: "USA", sessions: [race])
        return (weekend, race)
    }

    @Test func togglingAddsThenRemovesAndSchedulesTheBadge() {
        let scheduler = RecordingScheduler()
        let store = ReminderStore(defaults: freshDefaults(), scheduler: scheduler, now: date("2026-10-20T00:00:00Z"))
        let (weekend, race) = weekend()

        store.toggle(session: race, in: weekend, seriesName: "Formula 1", now: date("2026-10-20T00:00:00Z"))
        #expect(store.isSet(for: race.id))
        #expect(scheduler.scheduled == [race.id])

        store.toggle(session: race, in: weekend, seriesName: "Formula 1", now: date("2026-10-20T00:00:00Z"))
        #expect(!store.isSet(for: race.id))
        #expect(scheduler.cancelled == [race.id])
    }

    @Test func pastSessionsCannotBeReminded() {
        let store = ReminderStore(defaults: freshDefaults(), scheduler: RecordingScheduler())
        let (weekend, race) = weekend()
        store.toggle(session: race, in: weekend, seriesName: "Formula 1", now: raceStart.addingTimeInterval(60))
        #expect(store.reminders.isEmpty)
    }

    @Test func becomesDueFifteenMinutesBeforeAndOnlyOnce() {
        let store = ReminderStore(defaults: freshDefaults(), scheduler: RecordingScheduler())
        let (weekend, race) = weekend()
        store.toggle(session: race, in: weekend, seriesName: "Formula 1", now: date("2026-10-20T00:00:00Z"))

        #expect(store.dueReminder(at: raceStart.addingTimeInterval(-16 * 60)) == nil)
        let due = store.dueReminder(at: raceStart.addingTimeInterval(-14 * 60))
        #expect(due?.id == race.id)

        store.markPresented(due!)
        #expect(store.dueReminder(at: raceStart.addingTimeInterval(-10 * 60)) == nil)
    }

    @Test func remindersPersistAcrossLaunches() {
        let defaults = freshDefaults()
        let (weekend, race) = weekend()
        ReminderStore(defaults: defaults, scheduler: RecordingScheduler())
            .toggle(session: race, in: weekend, seriesName: "Formula 1", now: date("2026-10-20T00:00:00Z"))

        let relaunched = ReminderStore(defaults: defaults, scheduler: RecordingScheduler(), now: date("2026-10-21T00:00:00Z"))
        #expect(relaunched.isSet(for: race.id))
    }
}

struct AppSettingsTests {
    @Test func facesCycleThroughMyFacesInBothDirections() {
        let settings = AppSettings(defaults: freshDefaults())
        settings.faceType = .analogClassic
        let faces = settings.myFaces

        #expect(settings.face(offsetBy: 1) == faces[1])
        #expect(settings.face(offsetBy: -1) == faces.last)
    }

    @Test func removingTheCurrentFaceMovesToAnotherAndKeepsOne() {
        let settings = AppSettings(defaults: freshDefaults())
        for face in settings.myFaces.dropFirst() { settings.removeFromMyFaces(face) }
        let last = settings.myFaces[0]
        settings.removeFromMyFaces(last)
        #expect(settings.myFaces == [last])
        #expect(settings.faceType == last)
    }

    @Test func worldClockStopsAtSixCities() {
        let settings = AppSettings(defaults: freshDefaults())
        #expect(settings.worldCities.count == WorldCity.maximumSelection)
        #expect(!settings.canAddWorldCity)

        let extra = WorldCity.catalog.first { !settings.isWorldCitySelected($0) }!
        settings.toggleWorldCity(extra)
        #expect(!settings.isWorldCitySelected(extra))
    }

    @Test func faceColourDefaultsToFirstAndPersists() {
        let defaults = freshDefaults()
        let settings = AppSettings(defaults: defaults)
        #expect(settings.color(for: .tint)?.id == "ochre")

        settings.setColor(WatchFaceType.tint.palette[3], for: .tint)
        #expect(AppSettings(defaults: defaults).color(for: .tint)?.id == WatchFaceType.tint.palette[3].id)
    }

    @Test func everyWorldCityHasAValidTimeZone() {
        for city in WorldCity.catalog {
            #expect(TimeZone(identifier: city.id) != nil, "\(city.name) has an invalid time zone")
        }
    }
}

struct FormattingTests {
    @Test func offsetDescriptionsIncludeHalfHours() {
        let now = date("2026-10-15T12:00:00Z")
        let utc = TimeZone(identifier: "UTC")!
        #expect(TimeFormatting.offsetDescription(for: TimeZone(identifier: "Asia/Kolkata")!, at: now, relativeTo: utc) == "+5h 30m")
        #expect(TimeFormatting.offsetDescription(for: TimeZone(identifier: "America/New_York")!, at: now, relativeTo: utc) == "−4h")
        #expect(TimeFormatting.offsetDescription(for: utc, at: now, relativeTo: utc) == "Same time")
    }

    @Test func twelveAndTwentyFourHourParts() {
        let now = date("2026-10-15T13:05:00Z")
        let utc = TimeZone(identifier: "UTC")!
        let twentyFour = TimeFormatting.parts(now, in: utc, uses24Hour: true)
        #expect(twentyFour.time == "13:05")
        #expect(twentyFour.period == nil)

        let twelve = TimeFormatting.parts(now, in: utc, uses24Hour: false)
        #expect(twelve.time == "1:05")
        #expect(twelve.period == "PM")
    }

    @Test func countdownSplitsIntoDaysHoursMinutesSeconds() {
        let now = date("2026-10-15T12:00:00Z")
        let twoDaysThreeHoursFourMinutesFiveSeconds: TimeInterval = 183_845
        let parts = CountdownTiles.parts(until: now.addingTimeInterval(twoDaysThreeHoursFourMinutesFiveSeconds), from: now)
        let values: [Int] = [parts.days, parts.hours, parts.minutes, parts.seconds]
        #expect(values == [2, 3, 4, 5])

        let past = CountdownTiles.parts(until: now.addingTimeInterval(-10), from: now)
        let pastValues: [Int] = [past.days, past.hours, past.minutes, past.seconds]
        #expect(pastValues == [0, 0, 0, 0])
    }

    @Test func pixelShiftStaysWithinItsRadius() {
        for minute in 0..<16 {
            let offset = PixelShift.offset(at: Date(timeIntervalSince1970: Double(minute) * 60))
            #expect((offset.width * offset.width + offset.height * offset.height).squareRoot() <= PixelShift.radius + 0.001)
        }
    }
}

struct SolarCalculatorTests {
    private let london = GeoCoordinate(latitude: 51.5072, longitude: -0.1276)
    private let londonZone = TimeZone(identifier: "Europe/London")!

    private func time(of event: SolarEvent, in events: [SolarEventTime]) -> Date? {
        events.first { $0.event == event }?.date
    }

    private func expectClose(_ actual: Date?, _ expected: String, within minutes: Double = 3, sourceLocation: SourceLocation = #_sourceLocation) {
        guard let actual else {
            Issue.record("missing event, expected \(expected)", sourceLocation: sourceLocation)
            return
        }
        let difference = abs(actual.timeIntervalSince(date(expected))) / 60
        #expect(difference <= minutes, "off by \(difference) minutes from \(expected)", sourceLocation: sourceLocation)
    }

    @Test func londonMidsummerSunriseNoonAndSunset() {
        let events = SolarCalculator.events(on: date("2026-06-21T12:00:00Z"), coordinate: london, timeZone: londonZone)
        expectClose(time(of: .sunriseStarts, in: events), "2026-06-21T03:43:00Z")
        expectClose(time(of: .solarNoon, in: events), "2026-06-21T12:02:00Z")
        expectClose(time(of: .sunsetEnds, in: events), "2026-06-21T20:21:00Z")
        // In June the sun never sinks to −18° in London, so there is no astronomical dawn.
        #expect(time(of: .astronomicalDawn, in: events) == nil)
    }

    @Test func sydneyMidsummerSunriseAndSunset() {
        let sydney = GeoCoordinate(latitude: -33.8688, longitude: 151.2093)
        let events = SolarCalculator.events(on: date("2026-12-21T02:00:00Z"), coordinate: sydney,
                                            timeZone: TimeZone(identifier: "Australia/Sydney")!)
        expectClose(time(of: .sunriseStarts, in: events), "2026-12-20T18:41:00Z", within: 4)
        expectClose(time(of: .sunsetEnds, in: events), "2026-12-21T09:05:00Z", within: 4)
    }

    @Test func midnightSunHasNoSunriseOrSunset() {
        let tromso = GeoCoordinate(latitude: 69.6492, longitude: 18.9553)
        let events = SolarCalculator.events(on: date("2026-06-21T12:00:00Z"), coordinate: tromso,
                                            timeZone: TimeZone(identifier: "Europe/Oslo")!)
        #expect(time(of: .sunriseStarts, in: events) == nil)
        #expect(time(of: .sunsetEnds, in: events) == nil)
        #expect(time(of: .solarNoon, in: events) != nil)
    }

    @Test func autumnDayHasAllTwentyTwoEventsInOrder() {
        let events = SolarCalculator.events(on: date("2026-10-15T12:00:00Z"), coordinate: london, timeZone: londonZone)
        #expect(events.count == SolarEvent.allCases.count)
        #expect(events.map(\.event) == SolarEvent.allCases)
        #expect(zip(events, events.dropFirst()).allSatisfy { $0.date <= $1.date })
    }

    @Test func phaseNamesFollowElevation() {
        #expect(SolarEvent.phaseName(elevation: 30, isRising: true) == "Daylight")
        #expect(SolarEvent.phaseName(elevation: 2, isRising: false) == "Golden Hour")
        #expect(SolarEvent.phaseName(elevation: -0.5, isRising: true) == "Sunrise")
        #expect(SolarEvent.phaseName(elevation: -5, isRising: false) == "Blue Hour")
        #expect(SolarEvent.phaseName(elevation: -10, isRising: true) == "Nautical Twilight")
        #expect(SolarEvent.phaseName(elevation: -30, isRising: true) == "Night")
    }

    @Test func skyColoursChangeSmoothlyAcrossKeyframes() {
        // Tiny steps in elevation must give tiny steps in colour, including at keyframe boundaries.
        var elevation = -30.0
        var previous = SkyPalette.sky(elevation: elevation, isRising: true)
        while elevation < 50 {
            elevation += 0.05
            let current = SkyPalette.sky(elevation: elevation, isRising: true)
            let jump = abs(current.horizon.l - previous.horizon.l) + abs(current.horizon.a - previous.horizon.a)
                + abs(current.horizon.b - previous.horizon.b)
            #expect(jump < 0.02, "colour jump of \(jump) at elevation \(elevation)")
            previous = current
        }
    }
}

struct MoonPhaseTests {
    @Test func newMoonIsDarkAndFullMoonIsLit() {
        // Total solar eclipse (new moon) 8 Apr 2024 18:21 UTC; full moon 25 Jan 2024 17:54 UTC.
        let new = MoonPhase(at: date("2024-04-08T18:21:00Z"))
        #expect(new.illumination < 0.01)
        #expect(new.name == .newMoon)
        let full = MoonPhase(at: date("2024-01-25T17:54:00Z"))
        #expect(full.illumination > 0.99)
        #expect(full.name == .fullMoon)
    }

    @Test func firstQuarterIsHalfLitAndWaxing() {
        // First quarter 18 Jan 2024 03:52 UTC.
        let quarter = MoonPhase(at: date("2024-01-18T03:52:00Z"))
        #expect(abs(quarter.illumination - 0.5) < 0.03)
        #expect(quarter.isWaxing)
        #expect(quarter.name == .firstQuarter)
    }

    @Test func findsTheNextFullMoonWithinAFewHours() throws {
        let next = try #require(MoonPhase.next(.fullMoon, after: date("2024-01-20T00:00:00Z")))
        #expect(abs(next.timeIntervalSince(date("2024-01-25T17:54:00Z"))) < 3 * 3600)
        let nextNew = try #require(MoonPhase.next(.newMoon, after: date("2024-04-01T00:00:00Z")))
        #expect(abs(nextNew.timeIntervalSince(date("2024-04-08T18:21:00Z"))) < 3 * 3600)
    }
}

struct FaceMathTests {
    @Test func subsolarPointFollowsTheSeasonsAndTheClock() {
        // June solstice at noon UTC: sun over the Tropic of Cancer near Greenwich.
        let june = WorldFace.subsolarPoint(at: date("2026-06-21T12:00:00Z"))
        #expect(abs(june.latitude - 23.44) < 0.3)
        #expect(abs(june.longitude) < 1.5)
        // March equinox, 18:00 UTC: over the equator, 90° west.
        let march = WorldFace.subsolarPoint(at: date("2026-03-20T18:00:00Z"))
        #expect(abs(march.latitude) < 0.5)
        #expect(abs(march.longitude + 90) < 2.5)
    }

    @Test func solarArcProgressRunsFromSunriseToSunset() {
        let sunrise = date("2026-10-18T06:30:00Z")
        let sunset = date("2026-10-18T18:30:00Z")
        #expect(SolarArcFace.dayProgress(date: date("2026-10-18T12:30:00Z"), sunrise: sunrise, sunset: sunset) == 0.5)
        #expect(SolarArcFace.dayProgress(date: date("2026-10-18T20:00:00Z"), sunrise: sunrise, sunset: sunset) == nil)
    }

    @Test func monthLayoutPadsToWholeWeeks() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 1
        calendar.timeZone = TimeZone(identifier: "UTC")!
        // October 2026 starts on a Thursday.
        let layout = MonthLayout(for: date("2026-10-18T12:00:00Z"), calendar: calendar)
        #expect(layout.weeks.count == 5)
        #expect(layout.weeks[0] == [nil, nil, nil, nil, 1, 2, 3])
        #expect(layout.weeks.allSatisfy { $0.count == 7 })
    }

    @Test func worldMapHasLandAndEveryCityHasCoordinates() {
        #expect(WorldDotMap.landDots.count > 1500)
        #expect(WorldCity.catalog.allSatisfy { abs($0.latitude) <= 90 && abs($0.longitude) <= 180 && ($0.latitude, $0.longitude) != (0, 0) })
    }
}

struct WeatherSnapshotTests {
    private func snapshot(fetchedAt: Date, hours: Int = 25) -> WeatherSnapshot {
        WeatherSnapshot(
            fetchedAt: fetchedAt, latitude: 19.076, longitude: 72.8777, placeName: "Mumbai",
            hours: (0..<hours).map { index in
                WeatherSnapshot.Hour(
                    date: fetchedAt.addingTimeInterval(Double(index) * 3600), temperature: 20 + Double(index),
                    symbolName: "sun.max.fill", condition: "Sunny", humidity: 0.5, pressure: 1010,
                    uvIndex: 3, precipitationChance: 0.1
                )
            },
            days: []
        )
    }

    @Test func readsTheHourContainingTheMoment() {
        let start = date("2026-10-23T06:00:00Z")
        let forecast = snapshot(fetchedAt: start)
        #expect(forecast.hour(at: start.addingTimeInterval(2.5 * 3600))?.temperature == 22)
        #expect(forecast.hour(at: start.addingTimeInterval(-60)) == nil)
    }

    @Test func refreshesAfterSixHoursOrWhenTheForecastRunsOut() {
        let start = date("2026-10-23T06:00:00Z")
        let forecast = snapshot(fetchedAt: start)
        #expect(!forecast.needsRefresh(at: start.addingTimeInterval(5.9 * 3600)))
        #expect(forecast.needsRefresh(at: start.addingTimeInterval(6 * 3600)))
        // Only three hours of forecast: refresh once the next hour isn't covered.
        let short = snapshot(fetchedAt: start, hours: 3)
        #expect(!short.needsRefresh(at: start.addingTimeInterval(1.5 * 3600)))
        #expect(short.needsRefresh(at: start.addingTimeInterval(2.5 * 3600)))
    }

    @Test func appliesOnlyNearWhereItWasFetched() {
        let forecast = snapshot(fetchedAt: .now)
        #expect(forecast.isNear(latitude: 19.1, longitude: 72.9))     // a few km away
        #expect(!forecast.isNear(latitude: 18.52, longitude: 73.86))  // Pune, ~120 km
    }

    @Test func savedForecastSurvivesARelaunch() {
        let defaults = UserDefaults(suiteName: "WeatherSnapshotTests-\(UUID().uuidString)")!
        let forecast = snapshot(fetchedAt: date("2026-10-23T06:00:00Z"))
        defaults.set(try! JSONEncoder().encode(forecast), forKey: "weatherSnapshot")
        let store = WeatherStore(defaults: defaults)
        #expect(store.snapshot == forecast)
        #expect(store.conditions(at: date("2026-10-23T07:30:00Z"))?.temperature == 21)
    }

    @Test func uvLevelsFollowTheStandardBands() {
        #expect(UVLevel(index: 2) == .low)
        #expect(UVLevel(index: 5) == .moderate)
        #expect(UVLevel(index: 7) == .high)
        #expect(UVLevel(index: 10) == .veryHigh)
        #expect(UVLevel(index: 11) == .extreme)
    }
}
