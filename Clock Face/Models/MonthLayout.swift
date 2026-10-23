import Foundation

/// A month laid out for a calendar grid, honouring the locale's first weekday.
struct MonthLayout {
    /// Single-letter weekday names, starting from the first weekday.
    let weekdaySymbols: [String]
    /// Rows of seven day numbers, with nil for the blanks before the 1st and after the last day.
    let weeks: [[Int?]]

    init(for date: Date, calendar: Calendar = .current) {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        weekdaySymbols = Array(symbols[first...] + symbols[..<first])

        guard let month = calendar.dateInterval(of: .month, for: date),
              let dayCount = calendar.range(of: .day, in: .month, for: date)?.count else {
            weeks = []
            return
        }
        let leading = (calendar.component(.weekday, from: month.start) - calendar.firstWeekday + 7) % 7
        let cells: [Int?] = Array(repeating: nil, count: leading) + (1...dayCount).map { $0 }
        let padded = cells + Array(repeating: nil, count: (7 - cells.count % 7) % 7)
        weeks = stride(from: 0, to: padded.count, by: 7).map { Array(padded[$0..<$0 + 7]) }
    }
}
