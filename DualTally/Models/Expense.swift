//
//  Expense.swift
//  DualTally
//
//  A single daily-expense record. Currency is implicit (the app's single daily
//  currency), so it is not stored per record.
//

import Foundation
import SwiftData

@Model
final class Expense {
    var amount: Decimal
    var date: Date

    /// Category this expense is filed under. Optional so a category can be
    /// deleted without deleting its expenses (see `ExpenseCategory.expenses`).
    var category: ExpenseCategory?

    /// How this expense was paid (現金 / 信用卡 …). Optional so a payment method
    /// can be deleted without deleting its expenses (see `PaymentMethod.expenses`).
    var paymentMethod: PaymentMethod?

    /// Whether the money has actually left the account. Unpaid expenses still
    /// count against the available balance (already-committed money).
    var isPaid: Bool

    /// Impulse-purchase flag. Set only from the monthly review screen, never
    /// from the add/edit form.
    var isImpulse: Bool

    /// True when this whole expense was fronted for someone else (整筆墊付).
    var isAdvancePayment: Bool

    /// Name of the person the money was fronted for. Only meaningful while
    /// `isAdvancePayment` is true.
    var advancePaidForName: String?

    /// True once the person has paid back a fronted expense. A repaid advance
    /// is excluded from every total (balance, spent, reports, impulse stats).
    var isRepaid: Bool

    /// When the advance was marked repaid, if it was.
    var repaidDate: Date?

    var note: String?

    init(
        amount: Decimal,
        date: Date,
        category: ExpenseCategory?,
        paymentMethod: PaymentMethod? = nil,
        isPaid: Bool,
        note: String? = nil,
        isAdvancePayment: Bool = false,
        advancePaidForName: String? = nil
    ) {
        self.amount = amount
        self.date = date
        self.category = category
        self.paymentMethod = paymentMethod
        self.isPaid = isPaid
        self.note = note
        self.isImpulse = false
        self.isAdvancePayment = isAdvancePayment
        self.advancePaidForName = advancePaidForName
        self.isRepaid = false
        self.repaidDate = nil
    }
}

extension Expense {
    /// Whether this expense counts as the user's own spending. Everything counts
    /// except a fronted expense that has already been paid back.
    var countsAsSpending: Bool {
        !(isAdvancePayment && isRepaid)
    }

    /// An advance that is still waiting to be paid back.
    var isOutstandingAdvance: Bool {
        isAdvancePayment && !isRepaid
    }
}
