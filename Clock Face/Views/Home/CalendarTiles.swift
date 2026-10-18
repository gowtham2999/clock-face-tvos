import SwiftUI

/// "October / 17 / Saturday" in large type.
struct DateTile: View {
    let date: Date

    var body: some View {
        DashboardTile(padding: 34) {
            VStack(alignment: .center, spacing: 0) {
                Text(date.formatted(.dateTime.month(.wide)))
                    .font(.system(size: 38, weight: .regular))
                    .opacity(0.75)
                Text(date.formatted(.dateTime.day()))
                    .font(.system(size: 156, weight: .bold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.vertical, -14)
                    .accessibilityIdentifier("dashboardDay")
                Text(date.formatted(.dateTime.weekday(.wide)))
                    .font(.system(size: 38, weight: .regular))
                    .opacity(0.75)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .combine)
    }
}

/// This month's grid with today circled. Read-only: on an ambient display
/// there's no one to page between months.
struct MonthCalendarTile: View {
    let date: Date

    private let calendar = Calendar.current

    var body: some View {
        DashboardTile(padding: 28) {
            VStack(alignment: .leading, spacing: 14) {
                Text(date.formatted(.dateTime.month(.wide).year()))
                    .font(.system(size: 28, weight: .semibold))
                    .padding(.leading, 6)

                Grid(horizontalSpacing: 0, verticalSpacing: 4) {
                    GridRow {
                        ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                            Text(symbol)
                                .font(.system(size: 20, weight: .semibold))
                                .opacity(0.45)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.bottom, 6)

                    ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                        GridRow {
                            ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                                dayCell(day)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dayCell(_ day: Int?) -> some View {
        let isToday = day == calendar.component(.day, from: date)
        Text(day.map(String.init) ?? "")
            .font(.system(size: 23, weight: isToday ? .bold : .regular))
            .monospacedDigit()
            .foregroundStyle(isToday ? Color.inkInverse : Color.ink.opacity(0.85))
            .frame(width: 40, height: 36)
            .background {
                if isToday { Circle().fill(Color.ink).frame(width: 40, height: 40) }
            }
            .frame(maxWidth: .infinity)
    }

    /// Single-letter weekday names starting from the locale's first weekday.
    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    /// The month as rows of seven, with nil for the blanks before the 1st and after the last day.
    private var weeks: [[Int?]] {
        guard let month = calendar.dateInterval(of: .month, for: date),
              let dayCount = calendar.range(of: .day, in: .month, for: date)?.count else { return [] }
        let leading = (calendar.component(.weekday, from: month.start) - calendar.firstWeekday + 7) % 7
        let cells: [Int?] = Array(repeating: nil, count: leading) + (1...dayCount).map { $0 }
        let padded = cells + Array(repeating: nil, count: (7 - cells.count % 7) % 7)
        return stride(from: 0, to: padded.count, by: 7).map { Array(padded[$0..<$0 + 7]) }
    }
}
