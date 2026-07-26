//
//  DailyExpenseViewModel.swift
//  DualTally
//
//  Pure calculation layer for the daily-expense module. Views fetch with
//  @Query and feed the results here; keeping the math out of the views makes it
//  unit-testable and lets the list, calendar, and stat-card share one source of
//  truth. No SwiftUI dependencies.
//

import Foundation

/// The three headline numbers on the stat-card, for one budgeting cycle.
struct DailyExpenseSummary: Equatable {
    /// The budget the user set for the cycle (zero if none set yet).
    let budget: Decimal

    /// Budget minus every counted expense, including unpaid ones. Repaid
    /// advances are excluded because they no longer count as spending.
    let availableBalance: Decimal

    /// Sum of counted expenses that are actually paid.
    let spent: Decimal
}

enum DailyExpenseCalculator {
    /// Keeps only the expenses whose date falls in the cycle.
    static func expenses(_ expenses: [Expense], in cycle: BudgetCycle) -> [Expense] {
        expenses.filter { cycle.contains($0.date) }
    }

    /// Builds the stat-card summary from a cycle's expenses and its budget.
    /// Only counted expenses (see `Expense.countsAsSpending`) contribute.
    static func summary(budget: Decimal?, cycleExpenses: [Expense]) -> DailyExpenseSummary {
        let counted = cycleExpenses.filter(\.countsAsSpending)
        let committed = counted.reduce(Decimal.zero) { $0 + $1.amount }
        let paid = counted
            .filter(\.isPaid)
            .reduce(Decimal.zero) { $0 + $1.amount }
        let budgetAmount = budget ?? .zero
        return DailyExpenseSummary(
            budget: budgetAmount,
            availableBalance: budgetAmount - committed,
            spent: paid
        )
    }

    /// Total counted spending on a single calendar day. Drives the calendar's
    /// per-day subtotal; repaid advances are excluded, matching every other
    /// total.
    static func countedTotal(on day: Date, expenses: [Expense], calendar: Calendar = .current) -> Decimal {
        expenses
            .filter { $0.countsAsSpending && calendar.isDate($0.date, inSameDayAs: day) }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    /// The set of calendar days (start-of-day) that have at least one expense,
    /// used to place dots on the calendar grid. Presence ignores the
    /// counts-as-spending rule so a repaid advance still leaves a visible mark
    /// on the day it happened.
    static func daysWithExpenses(_ expenses: [Expense], calendar: Calendar = .current) -> Set<Date> {
        Set(expenses.map { calendar.startOfDay(for: $0.date) })
    }
}
