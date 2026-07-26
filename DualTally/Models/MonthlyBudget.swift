//
//  MonthlyBudget.swift
//  DualTally
//
//  The manually-set total budget for one budgeting cycle. A "month" is defined
//  by the app-wide month-start-day setting, so a cycle is keyed by the date it
//  begins rather than a calendar year/month.
//

import Foundation
import SwiftData

@Model
final class MonthlyBudget {
    /// First day of the cycle this budget applies to, normalised to the start of
    /// that day. Unique so there is at most one budget per cycle.
    @Attribute(.unique) var cycleStart: Date

    /// The total budget amount the user set for this cycle.
    var amount: Decimal

    init(cycleStart: Date, amount: Decimal) {
        self.cycleStart = cycleStart
        self.amount = amount
    }
}
