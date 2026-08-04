//
//  ReportCalculator.swift
//  DualTally
//
//  Pure aggregation layer for the daily-expense reports (roadmap step 7). Turns
//  a flat list of expenses into chart-ready buckets for a chosen time range and
//  view mode. No SwiftUI/Charts dependencies so the bucketing stays
//  unit-testable. Only counted expenses take part, so a repaid advance never
//  shows up in a report.
//

import Foundation

/// The time window a report spans. Determines both the range of dates included
/// and how finely they are bucketed along the x-axis.
enum ReportRange: CaseIterable, Identifiable {
    case week, month, year

    var id: Self { self }

    /// Localised label for the range picker.
    var label: String {
        switch self {
        case .week: return "週"
        case .month: return "月"
        case .year: return "年"
        }
    }

    /// The calendar unit each bar covers: days within a week/month, months
    /// within a year.
    var bucketComponent: Calendar.Component {
        self == .year ? .month : .day
    }
}

/// How the report is broken down.
enum ReportMode: CaseIterable, Identifiable {
    /// One bar per bucket, height = total spending over time.
    case total
    /// Every category's spending share for the whole window, compared at once
    /// via a pie chart and a table (see `ReportCalculator.categoryTotals`).
    case byCategory

    var id: Self { self }

    var label: String {
        switch self {
        case .total: return "總支出"
        case .byCategory: return "分類佔比"
        }
    }
}

/// One bar segment in the total-spending timeline: a bucket's summed amount.
struct ReportDataPoint: Identifiable {
    let id = UUID()

    /// Start of the bucket this point sits in; used as the chart's x value.
    let bucketDate: Date

    let amount: Decimal

    /// Chart-plottable amount.
    var amountValue: Double {
        NSDecimalNumber(decimal: amount).doubleValue
    }
}

/// One category's spending for the whole report window: its total and share
/// of every counted expense in that window, for the "分類佔比" pie chart and
/// table.
struct CategoryTotal: Identifiable {
    let id = UUID()

    let categoryName: String
    let total: Decimal

    /// Fraction of the window's grand total, `0...1`. Zero when there is no
    /// spending in the window at all.
    let share: Double

    /// Chart-plottable amount.
    var totalValue: Double {
        NSDecimalNumber(decimal: total).doubleValue
    }
}

enum ReportCalculator {
    /// The half-open date window `[start, end)` a range covers, anchored on
    /// `now`: the current calendar week, month, or year.
    static func window(
        for range: ReportRange,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> (start: Date, end: Date) {
        let component: Calendar.Component
        switch range {
        case .week: component = .weekOfYear
        case .month: component = .month
        case .year: component = .year
        }
        let interval = calendar.dateInterval(of: component, for: now)
            ?? DateInterval(start: calendar.startOfDay(for: now), duration: 86_400)
        return (interval.start, interval.end)
    }

    /// The ordered bucket start dates spanning a range's window.
    static func bucketStarts(
        for range: ReportRange,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [Date] {
        let (start, end) = window(for: range, now: now, calendar: calendar)
        var starts: [Date] = []
        var cursor = start
        while cursor < end {
            starts.append(cursor)
            guard let next = calendar.date(byAdding: range.bucketComponent, value: 1, to: cursor) else { break }
            cursor = next
        }
        return starts
    }

    /// Builds the total-spending timeline for a range: one point per bucket,
    /// summing every counted expense that falls in it. Empty buckets are
    /// omitted; the chart still spans the full window via its x-scale domain.
    static func dataPoints(
        expenses: [Expense],
        range: ReportRange,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [ReportDataPoint] {
        let (start, end) = window(for: range, now: now, calendar: calendar)
        let inWindow = expenses.filter {
            $0.countsAsSpending && $0.date >= start && $0.date < end
        }

        let grouped = Dictionary(grouping: inWindow) { expense in
            bucketStart(for: expense.date, range: range, windowStart: start, calendar: calendar)
        }

        return grouped
            .map { bucketDate, bucketExpenses in
                let sum = bucketExpenses.reduce(Decimal.zero) { $0 + $1.amount }
                return ReportDataPoint(bucketDate: bucketDate, amount: sum)
            }
            .sorted { $0.bucketDate < $1.bucketDate }
    }

    /// Every category's total and share of spending across a range's whole
    /// window (not bucketed by time), sorted by total descending, for the
    /// "分類佔比" pie chart and table. Includes unpaid and outstanding-advance
    /// expenses, same as every other counted total; excludes repaid advances.
    static func categoryTotals(
        expenses: [Expense],
        range: ReportRange,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [CategoryTotal] {
        let (start, end) = window(for: range, now: now, calendar: calendar)
        let inWindow = expenses.filter {
            $0.countsAsSpending && $0.date >= start && $0.date < end
        }
        let grandTotal = inWindow.reduce(Decimal.zero) { $0 + $1.amount }
        let grandTotalValue = NSDecimalNumber(decimal: grandTotal).doubleValue

        let byCategory = Dictionary(grouping: inWindow) { $0.category?.name ?? "未分類" }
        return byCategory
            .map { categoryName, categoryExpenses -> CategoryTotal in
                let sum = categoryExpenses.reduce(Decimal.zero) { $0 + $1.amount }
                let share = grandTotalValue > 0
                    ? NSDecimalNumber(decimal: sum).doubleValue / grandTotalValue
                    : 0
                return CategoryTotal(categoryName: categoryName, total: sum, share: share)
            }
            .sorted { $0.total > $1.total }
    }

    /// Total counted spending across a range's window, for the headline number.
    static func total(
        expenses: [Expense],
        range: ReportRange,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Decimal {
        let (start, end) = window(for: range, now: now, calendar: calendar)
        return expenses
            .filter { $0.countsAsSpending && $0.date >= start && $0.date < end }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    /// The bucket start a date falls into: start of its day for week/month
    /// ranges, start of its month for the year range.
    private static func bucketStart(
        for date: Date,
        range: ReportRange,
        windowStart: Date,
        calendar: Calendar
    ) -> Date {
        switch range.bucketComponent {
        case .month:
            let components = calendar.dateComponents([.year, .month], from: date)
            return calendar.date(from: components) ?? calendar.startOfDay(for: date)
        default:
            return calendar.startOfDay(for: date)
        }
    }
}
