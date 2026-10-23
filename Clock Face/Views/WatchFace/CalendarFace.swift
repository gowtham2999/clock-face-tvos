import SwiftUI

/// "Calendar": the weekday, a large date and the month with the time beneath,
/// next to this month's grid with today marked in the accent colour.
struct CalendarFace: WatchFace {
    let date: Date

    @Environment(AppSettings.self) private var settings
    @Environment(\.faceBackground) private var faceBackground

    init(date: Date) {
        self.date = date
    }

    var body: some View {
        let accent = settings.color(for: .calendar)?.primary ?? .orange

        GeometryReader { proxy in
            let unit = proxy.size.height

            ZStack {
                faceBackground ?? .black

                HStack(alignment: .center, spacing: unit * 0.16) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(date.formatted(.dateTime.weekday(.wide)))
                            .font(.system(size: unit * 0.06, weight: .regular))
                        Text(date.formatted(.dateTime.day()))
                            .font(.system(size: unit * 0.3, weight: .bold))
                            .monospacedDigit()
                            .padding(.vertical, -unit * 0.03)
                        Text(date.formatted(.dateTime.month(.wide)))
                            .font(.system(size: unit * 0.06, weight: .regular))
                        Text(TimeFormatting.string(date, uses24Hour: settings.uses24HourTime))
                            .font(.system(size: unit * 0.05, weight: .light))
                            .monospacedDigit()
                            .opacity(0.65)
                            .padding(.top, unit * 0.04)
                    }

                    MonthGrid(date: date, accent: accent, cellSize: unit * 0.068)
                }
                .foregroundStyle(.white)
            }
        }
    }
}

/// A month of days in rows of seven with weekday initials above and today circled.
private struct MonthGrid: View {
    let date: Date
    let accent: Color
    let cellSize: CGFloat

    private let calendar = Calendar.current
    private var layout: MonthLayout { MonthLayout(for: date, calendar: calendar) }

    var body: some View {
        let today = calendar.component(.day, from: date)

        Grid(horizontalSpacing: cellSize * 0.25, verticalSpacing: cellSize * 0.18) {
            GridRow {
                ForEach(Array(layout.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.system(size: cellSize * 0.36, weight: .semibold))
                        .opacity(0.5)
                        .frame(width: cellSize)
                }
            }
            ForEach(Array(layout.weeks.enumerated()), id: \.offset) { _, week in
                GridRow {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                        Text(day.map(String.init) ?? "")
                            .font(.system(size: cellSize * 0.42, weight: day == today ? .bold : .regular))
                            .monospacedDigit()
                            .foregroundStyle(day == today ? Color.black : Color.white.opacity(0.85))
                            .frame(width: cellSize, height: cellSize)
                            .background {
                                if day == today { Circle().fill(accent) }
                            }
                    }
                }
            }
        }
    }
}

#Preview {
    CalendarFace(date: .now)
        .environment(AppSettings())
}
