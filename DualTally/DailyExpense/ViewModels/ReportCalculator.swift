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

/// How the bars are broken down.
enum ReportMode: CaseIterable, Identifiable {
    /// One bar per bucket, height = total spending.
    case total
    /// One bar per bucket, stacked by category.
    case byCategory
    /// One bar per bucket for a single chosen category's spending over time.
    case singleCategory

    var id: Self { self }

    var label: String {
        switch self {
        case .total: return "總支出"
        case .byCategory: return "分類佔比"
        case .singleCategory: return "依分類"
        }
    }
}

/// One bar segment: an amount within a bucket, tagged with the category it
/// belongs to (a fixed key for non-stacked modes).
struct ReportDataPoint: Identifiable {
    let id = UUID()

    /// Start of the bucket this point sits in; used as the chart's x value.
    let bucketDate: Date

    /// Category name for stacking/colouring. A fixed key for total mode.
    let categoryName: String

    let amount: Decimal

    /// Chart-plottable amount.
    var amountValue: Double {
        NSDecimalNumber(decimal: amount).doubleValue
    }
}

enum ReportCalculator {
    /// Fixed series key used when a report is not broken down by category, so
    /// the chart still has a single stable colour/legend entry.
    static let totalSeriesKey = "支出"

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

    /// Builds the chart data points for a range, mode, and (for single-category
    /// mode) a chosen category name. Empty buckets are omitted; the chart still
    /// spans the full window via its x-scale domain.
    static func dataPoints(
        expenses: [Expense],
        range: ReportRange,
        mode: ReportMode,
        selectedCategory: String? = nil,
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

        var points: [ReportDataPoint] = []
        for (bucketDate, bucketExpenses) in grouped {
            switch mode {
            case .total:
                let sum = bucketExpenses.reduce(Decimal.zero) { $0 + $1.amount }
                points.append(ReportDataPoint(bucketDate: bucketDate, categoryName: totalSeriesKey, amount: sum))

            case .singleCategory:
                let matching = bucketExpenses.filter { ($0.category?.name ?? "未分類") == selectedCategory }
                let sum = matching.reduce(Decimal.zero) { $0 + $1.amount }
                if sum > 0 {
                    points.append(ReportDataPoint(bucketDate: bucketDate, categoryName: selectedCategory ?? "未分類", amount: sum))
                }

            case .byCategory:
                let byCategory = Dictionary(grouping: bucketExpenses) { $0.category?.name ?? "未分類" }
                for (categoryName, categoryExpenses) in byCategory {
                    let sum = categoryExpenses.reduce(Decimal.zero) { $0 + $1.amount }
                    points.append(ReportDataPoint(bucketDate: bucketDate, categoryName: categoryName, amount: sum))
                }
            }
        }
        return points.sorted { $0.bucketDate < $1.bucketDate }
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
