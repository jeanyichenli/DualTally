//
//  DailyExpenseCalculatorTests.swift
//  DualTallyTests
//
//  Balance, spending, advance-payment, and impulse aggregation.
//

import Testing
import Foundation
@testable import DualTally

@Suite("DailyExpenseCalculator")
struct DailyExpenseCalculatorTests {
    private let calendar = Fixture.calendar
    private let day = Fixture.date(2026, 7, 10)

    // MARK: Summary

    @Test("Available balance subtracts unpaid expenses; spent counts only paid")
    func summaryCountsUnpaidAgainstBalanceButNotSpent() {
        let expenses = [
            Fixture.expense(300, on: day, isPaid: true),
            Fixture.expense(200, on: day, isPaid: false),
        ]
        let summary = DailyExpenseCalculator.summary(budget: 1000, cycleExpenses: expenses)
        #expect(summary.budget == 1000)
        #expect(summary.availableBalance == 500)
        #expect(summary.spent == 300)
    }

    @Test("A repaid advance is excluded from balance and spent")
    func summaryExcludesRepaidAdvance() {
        let expenses = [
            Fixture.expense(300, on: day, isPaid: true),
            Fixture.expense(500, on: day, isPaid: true, advanceFor: "Amy", repaid: true),
        ]
        let summary = DailyExpenseCalculator.summary(budget: 1000, cycleExpenses: expenses)
        #expect(summary.availableBalance == 700)
        #expect(summary.spent == 300)
    }

    @Test("An outstanding advance still counts as committed spending")
    func summaryCountsOutstandingAdvance() {
        let expenses = [
            Fixture.expense(500, on: day, isPaid: true, advanceFor: "Amy"),
        ]
        let summary = DailyExpenseCalculator.summary(budget: 1000, cycleExpenses: expenses)
        #expect(summary.availableBalance == 500)
        #expect(summary.spent == 500)
    }

    @Test("A nil budget is treated as zero")
    func summaryNilBudget() {
        let summary = DailyExpenseCalculator.summary(
            budget: nil,
            cycleExpenses: [Fixture.expense(120, on: day)]
        )
        #expect(summary.budget == 0)
        #expect(summary.availableBalance == -120)
    }

    // MARK: Advances

    @Test("Outstanding advance total sums only unrepaid advances")
    func outstandingAdvanceTotal() {
        let expenses = [
            Fixture.expense(300, on: day, advanceFor: "Amy"),
            Fixture.expense(200, on: day, advanceFor: "Bob"),
            Fixture.expense(999, on: day, advanceFor: "Cara", repaid: true),
            Fixture.expense(50, on: day),
        ]
        #expect(DailyExpenseCalculator.outstandingAdvanceTotal(expenses) == 500)
    }

    @Test("Advances group by person, ordered by who owes the most")
    func advancesByPerson() {
        let expenses = [
            Fixture.expense(100, on: day, advanceFor: "Amy"),
            Fixture.expense(400, on: day, advanceFor: "Bob"),
            Fixture.expense(50, on: day, advanceFor: "Amy"),
        ]
        let groups = DailyExpenseCalculator.outstandingAdvancesByPerson(expenses)
        #expect(groups.map(\.name) == ["Bob", "Amy"])
        #expect(groups[1].expenses.count == 2)
    }

    @Test("Repaid advances are listed separately from outstanding ones")
    func repaidAndOutstandingPartition() {
        let expenses = [
            Fixture.expense(100, on: day, advanceFor: "Amy"),
            Fixture.expense(200, on: day, advanceFor: "Bob", repaid: true),
        ]
        #expect(DailyExpenseCalculator.outstandingAdvances(expenses).count == 1)
        #expect(DailyExpenseCalculator.repaidAdvances(expenses).count == 1)
    }

    // MARK: Impulse review

    @Test("Impulse summary reports total, impulse amount, count, and share")
    func impulseSummary() {
        let expenses = [
            Fixture.expense(300, on: day, isImpulse: true),
            Fixture.expense(100, on: day, isImpulse: false),
            Fixture.expense(100, on: day, isImpulse: true),
        ]
        let summary = DailyExpenseCalculator.impulseReviewSummary(expenses)
        #expect(summary.totalSpending == 500)
        #expect(summary.impulseTotal == 400)
        #expect(summary.impulseCount == 2)
        #expect(summary.impulseShare == 0.8)
    }

    @Test("Impulse share is zero when there is no spending")
    func impulseShareZeroWhenEmpty() {
        let summary = DailyExpenseCalculator.impulseReviewSummary([])
        #expect(summary.impulseShare == 0)
        #expect(summary.totalSpending == 0)
    }

    @Test("A repaid advance never inflates the impulse total")
    func impulseExcludesRepaidAdvance() {
        let expenses = [
            Fixture.expense(200, on: day, isImpulse: true),
            Fixture.expense(800, on: day, isImpulse: true, advanceFor: "Amy", repaid: true),
        ]
        let summary = DailyExpenseCalculator.impulseReviewSummary(expenses)
        #expect(summary.totalSpending == 200)
        #expect(summary.impulseTotal == 200)
    }

    // MARK: Per-day helpers

    @Test("Counted total on a day excludes repaid advances")
    func countedTotalOnDay() {
        let expenses = [
            Fixture.expense(300, on: day),
            Fixture.expense(500, on: day, advanceFor: "Amy", repaid: true),
            Fixture.expense(120, on: Fixture.date(2026, 7, 11)),
        ]
        let total = DailyExpenseCalculator.countedTotal(on: day, expenses: expenses, calendar: calendar)
        #expect(total == 300)
    }

    @Test("Grouping by day orders newest day first")
    func groupedByDayOrder() {
        let expenses = [
            Fixture.expense(10, on: Fixture.date(2026, 7, 5)),
            Fixture.expense(20, on: Fixture.date(2026, 7, 20)),
            Fixture.expense(30, on: Fixture.date(2026, 7, 12)),
        ]
        let groups = DailyExpenseCalculator.groupedByDay(expenses, calendar: calendar)
        let days = groups.map { calendar.component(.day, from: $0.day) }
        #expect(days == [20, 12, 5])
    }
}
