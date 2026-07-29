//
//  DailyBalanceSnapshot.swift
//  DualTally
//
//  Writes the current cycle's available balance into the App Group's shared
//  defaults and reloads the Lock Screen widget. Call after any change that can
//  move the balance — a new/edited/deleted expense, a budget or start-day
//  change, or an advance marked repaid. The widget reads only this derived
//  snapshot, so it never has to compile the SwiftData model layer.
//

import Foundation
import SwiftData
import WidgetKit

enum DailyBalanceSnapshot {
    /// Recomputes the current cycle's summary from the store and publishes the
    /// available balance to the shared defaults, then refreshes the widget.
    static func refresh(using context: ModelContext) {
        let cycle = BudgetCycleCalculator.currentCycle()
        let allExpenses = (try? context.fetch(FetchDescriptor<Expense>())) ?? []
        let cycleExpenses = DailyExpenseCalculator.expenses(allExpenses, in: cycle)
        let budgets = (try? context.fetch(FetchDescriptor<MonthlyBudget>())) ?? []
        let budget = budgets.first { $0.cycleStart == cycle.start }?.amount
        let summary = DailyExpenseCalculator.summary(budget: budget, cycleExpenses: cycleExpenses)

        let defaults = AppGroupConstants.sharedDefaults ?? .standard
        defaults.set(
            summary.availableBalance.formattedAsDailyCurrency(),
            forKey: AppGroupConstants.WidgetSnapshotKey.balanceText
        )
        defaults.set(
            NSDecimalNumber(decimal: summary.availableBalance).doubleValue,
            forKey: AppGroupConstants.WidgetSnapshotKey.availableBalance
        )
        defaults.set(
            cycleLabel(for: cycle),
            forKey: AppGroupConstants.WidgetSnapshotKey.cycleLabel
        )

        WidgetCenter.shared.reloadAllTimelines()
    }

    private static func cycleLabel(for cycle: BudgetCycle) -> String {
        let end = Calendar.current.date(byAdding: .day, value: -1, to: cycle.end) ?? cycle.end
        let style = Date.FormatStyle.dateTime.month(.abbreviated).day()
        return "\(cycle.start.formatted(style)) – \(end.formatted(style))"
    }
}
