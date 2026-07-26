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

    /// SF Symbols offered when the user creates or edits a category.
    static let symbolChoices: [String] = [
        "fork.knife", "car.fill", "gamecontroller.fill", "cross.case.fill",
        "bag.fill", "house.fill", "book.fill", "cup.and.saucer.fill",
        "tram.fill", "airplane", "gift.fill", "pawprint.fill",
        "creditcard.fill", "wrench.and.screwdriver.fill", "heart.fill",
        "tshirt.fill", "cart.fill", "phone.fill", "bolt.fill",
        "ellipsis.circle.fill",
    ]

    private static let didSeedDefaultsKey = "didSeedDefaultCategories"

    /// Inserts the default categories once, on first launch only. Guarded by a
    /// persisted flag so that a user who deletes every default is not given them
    /// back on the next launch.
    static func seedDefaultsIfNeeded(in context: ModelContext) {
        let defaults = AppGroupConstants.sharedDefaults ?? .standard
        guard !defaults.bool(forKey: didSeedDefaultsKey) else { return }

        for (index, entry) in Self.defaults.enumerated() {
            context.insert(
                ExpenseCategory(
                    name: entry.name,
                    symbolName: entry.symbolName,
                    isBuiltIn: true,
                    sortOrder: index
                )
            )
        }
        defaults.set(true, forKey: didSeedDefaultsKey)
    }

    /// The next sort order to assign a user-created category, placing it after
    /// all existing ones.
    static func nextSortOrder(after categories: [ExpenseCategory]) -> Int {
        (categories.map(\.sortOrder).max() ?? -1) + 1
    }
}
