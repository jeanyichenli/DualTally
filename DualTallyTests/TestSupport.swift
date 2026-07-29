//
//  TestSupport.swift
//  DualTallyTests
//
//  Deterministic fixtures for the pure-logic tests. Model objects are created
//  without a ModelContext — the calculators only read their stored properties,
//  so no store is needed. A fixed calendar keeps date bucketing reproducible
//  regardless of the machine's time zone.
//

import Foundation
@testable import DualTally

enum Fixture {
    /// Fixed calendar used by every test so cycle and report bucketing is
    /// independent of the host time zone.
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Taipei")!
        return calendar
    }()

    /// Builds a noon date so day bucketing never straddles a boundary.
    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        let components = DateComponents(year: year, month: month, day: day, hour: 12)
        return calendar.date(from: components)!
    }

    static func category(_ name: String) -> ExpenseCategory {
        ExpenseCategory(name: name, symbolName: "circle", isBuiltIn: false, sortOrder: 0)
    }

    static func expense(
        _ amount: Decimal,
        on date: Date,
        category: ExpenseCategory? = nil,
        isPaid: Bool = true,
        isImpulse: Bool = false,
        advanceFor person: String? = nil,
        repaid: Bool = false
    ) -> Expense {
        let expense = Expense(
            amount: amount,
            date: date,
            category: category,
            isPaid: isPaid,
            isAdvancePayment: person != nil,
            advancePaidForName: person
        )
        expense.isImpulse = isImpulse
        if repaid {
            expense.isRepaid = true
            expense.repaidDate = date
        }
        return expense
    }
}
