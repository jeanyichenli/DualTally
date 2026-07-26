//
//  ExpenseCategory.swift
//  DualTally
//
//  Daily-expense category (用途類型). Ships with a built-in default set and
//  allows user-defined categories.
//

import Foundation
import SwiftData

@Model
final class ExpenseCategory {
    /// Display name, unique across categories.
    @Attribute(.unique) var name: String

    /// SF Symbol name used in lists and the report legend.
    var symbolName: String

    /// True for the seeded default categories, false for user-created ones.
    var isBuiltIn: Bool

    /// Sort order for display; built-in categories keep their seeded order.
    var sortOrder: Int

    /// Expenses filed under this category. Nullified rather than cascaded so
    /// deleting a category never deletes its historical expenses.
    @Relationship(deleteRule: .nullify, inverse: \Expense.category)
    var expenses: [Expense] = []

    init(name: String, symbolName: String, isBuiltIn: Bool, sortOrder: Int) {
        self.name = name
        self.symbolName = symbolName
        self.isBuiltIn = isBuiltIn
        self.sortOrder = sortOrder
    }
}

extension ExpenseCategory {
    /// The default categories seeded on first launch, in display order.
    static let defaults: [(name: String, symbolName: String)] = [
        ("飲食", "fork.knife"),
        ("交通", "car.fill"),
        ("娛樂", "gamecontroller.fill"),
        ("醫療", "cross.case.fill"),
        ("購物", "bag.fill"),
        ("居住", "house.fill"),
        ("學習", "book.fill"),
        ("其他", "ellipsis.circle.fill"),
    ]

    /// Inserts the default categories into the context if none exist yet.
    static func seedDefaultsIfNeeded(in context: ModelContext) {
        let existing = try? context.fetchCount(FetchDescriptor<ExpenseCategory>())
        guard (existing ?? 0) == 0 else { return }
        for (index, entry) in defaults.enumerated() {
            context.insert(
                ExpenseCategory(
                    name: entry.name,
                    symbolName: entry.symbolName,
                    isBuiltIn: true,
                    sortOrder: index
                )
            )
        }
    }
}
