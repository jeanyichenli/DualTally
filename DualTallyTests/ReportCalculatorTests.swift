//
//  ReportCalculatorTests.swift
//  DualTallyTests
//
//  Report windowing and bucket aggregation across ranges and view modes.
//

import Testing
import Foundation
@testable import DualTally

@Suite("ReportCalculator")
struct ReportCalculatorTests {
    private let calendar = Fixture.calendar
    private let now = Fixture.date(2026, 7, 15)

    // MARK: Windows and buckets

    @Test("The month window spans the containing calendar month")
    func monthWindow() {
        let window = ReportCalculator.window(for: .month, now: now, calendar: calendar)
        #expect(window.start == Fixture.date(2026, 7, 1).startOfDay(calendar))
        #expect(window.end == Fixture.date(2026, 8, 1).startOfDay(calendar))
    }

    @Test("A month buckets into one start per day")
    func monthBuckets() {
        let starts = ReportCalculator.bucketStarts(for: .month, now: now, calendar: calendar)
        #expect(starts.count == 31)
    }

    @Test("A year buckets into twelve months")
    func yearBuckets() {
        let starts = ReportCalculator.bucketStarts(for: .year, now: now, calendar: calendar)
        #expect(starts.count == 12)
    }

    @Test("A week buckets into seven days")
    func weekBuckets() {
        let starts = ReportCalculator.bucketStarts(for: .week, now: now, calendar: calendar)
        #expect(starts.count == 7)
    }

    // MARK: Data points

    @Test("Total mode sums each bucket under one series key")
    func totalMode() {
        let expenses = [
            Fixture.expense(100, on: Fixture.date(2026, 7, 10)),
            Fixture.expense(50, on: Fixture.date(2026, 7, 10)),
            Fixture.expense(70, on: Fixture.date(2026, 7, 12)),
        ]
        let points = ReportCalculator.dataPoints(
            expenses: expenses, range: .month, mode: .total, now: now, calendar: calendar
        )
        #expect(points.count == 2)
        #expect(points.allSatisfy { $0.categoryName == ReportCalculator.totalSeriesKey })
        #expect(points.first?.amount == 150)
        #expect(points.last?.amount == 70)
    }

    @Test("Category mode emits one segment per category in a bucket")
    func byCategoryMode() {
        let food = Fixture.category("飲食")
        let transport = Fixture.category("交通")
        let expenses = [
            Fixture.expense(100, on: Fixture.date(2026, 7, 10), category: food),
            Fixture.expense(40, on: Fixture.date(2026, 7, 10), category: transport),
        ]
        let points = ReportCalculator.dataPoints(
            expenses: expenses, range: .month, mode: .byCategory, now: now, calendar: calendar
        )
        #expect(points.count == 2)
        #expect(Set(points.map(\.categoryName)) == ["飲食", "交通"])
    }

    @Test("Single-category mode keeps only the chosen category")
    func singleCategoryMode() {
        let food = Fixture.category("飲食")
        let transport = Fixture.category("交通")
        let expenses = [
            Fixture.expense(100, on: Fixture.date(2026, 7, 10), category: food),
            Fixture.expense(40, on: Fixture.date(2026, 7, 12), category: transport),
        ]
        let points = ReportCalculator.dataPoints(
            expenses: expenses, range: .month, mode: .singleCategory,
            selectedCategory: "飲食", now: now, calendar: calendar
        )
        #expect(points.count == 1)
        #expect(points.first?.categoryName == "飲食")
        #expect(points.first?.amount == 100)
    }

    @Test("Expenses outside the window are ignored")
    func windowFiltersOutOfRange() {
        let expenses = [
            Fixture.expense(100, on: Fixture.date(2026, 7, 10)),
            Fixture.expense(999, on: Fixture.date(2026, 6, 30)),
            Fixture.expense(999, on: Fixture.date(2026, 8, 1)),
        ]
        let total = ReportCalculator.total(expenses: expenses, range: .month, now: now, calendar: calendar)
        #expect(total == 100)
    }

    @Test("Repaid advances are excluded from report totals")
    func excludesRepaidAdvance() {
        let expenses = [
            Fixture.expense(100, on: Fixture.date(2026, 7, 10)),
            Fixture.expense(500, on: Fixture.date(2026, 7, 11), advanceFor: "Amy", repaid: true),
        ]
        let total = ReportCalculator.total(expenses: expenses, range: .month, now: now, calendar: calendar)
        #expect(total == 100)
    }
}

private extension Date {
    func startOfDay(_ calendar: Calendar) -> Date {
        calendar.startOfDay(for: self)
    }
}
