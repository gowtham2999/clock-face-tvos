import SwiftUI

/// Formula 1: countdown to the selected weekend's race, its sessions with
/// reminders, and the season's rounds to pick from.
struct F1View: View {
    @Environment(F1ScheduleStore.self) private var schedule

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            if let weekend = schedule.weekend(withID: schedule.selectedWeekendID)
                ?? schedule.nextWeekend(after: now)
                ?? schedule.weekends.last {
                VStack(alignment: .leading, spacing: 40) {
                    HStack(alignment: .top, spacing: 56) {
                        WeekendHeader(weekend: weekend, now: now)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        SessionList(weekend: weekend, now: now)
                            .frame(width: 600)
                    }
                    SeasonStrip(weekends: schedule.weekends, selectedID: weekend.id, now: now)
                }
            } else {
                PlaceholderTabView(title: "Formula 1", subtitle: "Schedule unavailable — check your connection")
            }
        }
    }
}

private struct WeekendHeader: View {
    let weekend: RaceWeekend
    let now: Date

    @Environment(AppSettings.self) private var settings

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ROUND \(weekend.round) · \(weekend.locality.uppercased()), \(weekend.country.uppercased())")
                .font(.system(size: 22, weight: .bold))
                .tracking(2)
                .foregroundStyle(Color.racingRed)
            Text(weekend.name)
                .font(.system(size: 56, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(Color.ink)
                .accessibilityIdentifier("weekendName")
            Text(weekend.circuitName)
                .font(.system(size: 26))
                .foregroundStyle(Color.ink.opacity(0.55))

            if let start = weekend.mainEventStart {
                CountdownTiles(target: start, now: now)
                    .padding(.top, 24)
            }

            status
                .font(.system(size: 22, weight: .semibold))
                .tracking(1.5)
                .padding(.top, 8)
        }
    }

    @ViewBuilder
    private var status: some View {
        if let live = weekend.liveSession(at: now) {
            Label("LIVE · \(live.kind.displayName.uppercased())", systemImage: "dot.radiowaves.left.and.right")
                .foregroundStyle(Color.racingRed)
        } else if weekend.isFinished(at: now) {
            Text("RACE FINISHED")
                .foregroundStyle(Color.ink.opacity(0.5))
        } else if let race = weekend.race {
            Text("UNTIL LIGHTS OUT · \(SessionTimeText.string(for: race.start, uses24Hour: settings.uses24HourTime).uppercased())")
                .foregroundStyle(Color.ink.opacity(0.6))
        }
    }
}

private struct SessionList: View {
    let weekend: RaceWeekend
    let now: Date

    @Environment(ReminderStore.self) private var reminders
    @Environment(AppSettings.self) private var settings

    var body: some View {
        VStack(spacing: 12) {
            ForEach(weekend.sessions) { session in
                row(for: session)
            }
        }
        .focusSection()
    }

    private func row(for session: RaceSession) -> some View {
        let isSet = reminders.isSet(for: session.id)

        return HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.kind.displayName)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Color.ink)
                Text(SessionTimeText.string(for: session.start, uses24Hour: settings.uses24HourTime))
                    .font(.system(size: 21))
                    .foregroundStyle(Color.ink.opacity(0.55))
            }
            Spacer(minLength: 0)

            if session.start <= now && now < session.end {
                Text("LIVE")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.racingRed, in: Capsule())
            } else if now >= session.end {
                Text("Finished")
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(Color.ink.opacity(0.4))
            } else {
                Button {
                    reminders.toggle(session: session, in: weekend, seriesName: Sport.formula1.displayName)
                } label: {
                    Label(isSet ? "Reminder set" : "Remind me", systemImage: isSet ? "bell.fill" : "bell")
                }
                .buttonStyle(ChipButtonStyle(isOn: isSet))
                .accessibilityLabel("\(session.kind.displayName) reminder")
                .accessibilityValue(isSet ? "On" : "Off")
            }
        }
        .padding(.horizontal, 28)
        .frame(height: 88)
        .background(Color.ink.opacity(0.06), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct SeasonStrip: View {
    let weekends: [RaceWeekend]
    let selectedID: String
    let now: Date

    @Environment(F1ScheduleStore.self) private var schedule

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 20) {
                    ForEach(weekends) { weekend in
                        Button {
                            schedule.selectedWeekendID = weekend.id
                        } label: {
                            RoundChip(weekend: weekend, isFinished: weekend.isFinished(at: now))
                        }
                        .buttonStyle(RoundChipButtonStyle(isSelected: weekend.id == selectedID))
                        .accessibilityLabel("Round \(weekend.round), \(weekend.name)")
                        .id(weekend.id)
                    }
                }
                .padding(.vertical, 20)
            }
            .scrollClipDisabled()
            .onAppear {
                proxy.scrollTo(selectedID, anchor: .center)
            }
        }
        .focusSection()
    }
}

private struct RoundChip: View {
    let weekend: RaceWeekend
    let isFinished: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("R\(weekend.round)")
                    .foregroundStyle(Color.racingRed)
                Spacer(minLength: 0)
                if isFinished {
                    Image(systemName: "checkmark")
                }
            }
            .font(.system(size: 18, weight: .bold))
            Text(weekend.locality)
                .font(.system(size: 24, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let start = weekend.mainEventStart {
                Text(start.formatted(.dateTime.day().month(.abbreviated)).uppercased())
                    .font(.system(size: 18, weight: .medium))
                    .opacity(0.55)
            }
        }
        .frame(width: 168, alignment: .leading)
        .opacity(isFinished ? 0.5 : 1)
    }
}

private struct RoundChipButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        RoundChipLabel(configuration: configuration, isSelected: isSelected)
    }
}

private struct RoundChipLabel: View {
    let configuration: ButtonStyleConfiguration
    let isSelected: Bool
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        configuration.label
            .foregroundStyle(isFocused ? Color.inkInverse : Color.ink)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(isFocused ? Color.ink : Color.ink.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.racingRed, lineWidth: isSelected && !isFocused ? 3 : 0)
            )
            .scaleEffect(isFocused ? 1.08 : 1)
            .animation(.easeOut(duration: 0.15), value: isFocused)
    }
}

/// "Sun 25 Oct · 1:30 AM" in the viewer's own time zone.
enum SessionTimeText {
    static func string(for date: Date, uses24Hour: Bool) -> String {
        let day = date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        return "\(day) · \(TimeFormatting.string(date, uses24Hour: uses24Hour))"
    }
}
