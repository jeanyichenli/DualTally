//
//  BudgetCycle.swift
//  DualTally
//
//  Pure date logic for the configurable budgeting cycle. A "month" begins on the
//  user-chosen start day (1–28) rather than the 1st, so this resolves the cycle
//  that contains a given date. Shared by the main app and the widget so both
//  compute the available balance over exactly the same window. No SwiftUI or
//  SwiftData dependencies — kept unit-testable in isolation.
//

import Foundation

/// A half-open budgeting cycle `[start, end)` covering one "month" as defined by
/// the month-start-day setting.
struct BudgetCycle: Equatable {
    /// First moment of the cycle (start of the start day).
    let start: Date

    /// First moment of the next cycle; the cycle contains dates `< end`.
    let end: Date

    /// Whether `date` falls within this cycle.
    func contains(_ date: Date) -> Bool {
        date >= start && date < end
    }

    /// "M/d – M/d" label for the cycle's inclusive date range, e.g. "Aug 1 – Aug 31".
    func rangeLabel(calendar: Calendar = .current) -> String {
        let end = calendar.date(byAdding: .day, value: -1, to: end) ?? end
        let style = Date.FormatStyle.dateTime.month(.abbreviated).day()
        return "\(start.formatted(style)) – \(end.formatted(style))"
    }
}

enum BudgetCycleCalculator {
    /// Resolves the cycle containing `date` for a given `startDay` (1–28).
    ///
    /// Example: `startDay = 5`, `date = July 3` → cycle is `June 5 … July 5`.
    /// `startDay = 5`, `date = July 20` → cycle is `July 5 … August 5`.
    static func cycle(
        containing date: Date,
        startDay: Int,
        calendar: Calendar = .current
    ) -> BudgetCycle {
        let clampedStartDay = min(max(startDay, 1), 28)
        let dayStart = calendar.startOfDay(for: date)

        // Anchor the current calendar month at the start day.
        var components = calendar.dateComponents([.year, .month], from: dayStart)
        components.day = clampedStartDay
        let thisMonthAnchor = calendar.date(from: components) ?? dayStart

        // If we're before this month's anchor, the cycle started last month.
        let cycleStart: Date
        if dayStart >= thisMonthAnchor {
            cycleStart = thisMonthAnchor
        } else {
            cycleStart = calendar.date(byAdding: .month, value: -1, to: thisMonthAnchor) ?? thisMonthAnchor
        }

        let cycleEnd = calendar.date(byAdding: .month, value: 1, to: cycleStart) ?? cycleStart
        return BudgetCycle(start: cycleStart, end: cycleEnd)
    }

    /// Convenience for the cycle containing "now" using the stored setting.
    static func currentCycle(
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> BudgetCycle {
        cycle(containing: now, startDay: MonthStartDaySetting.current, calendar: calendar)
    }
}
