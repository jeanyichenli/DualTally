//
//  PaymentMethod.swift
//  DualTally
//
//  How a daily expense was paid (現金 / 信用卡 …). A second, independent axis
//  from ExpenseCategory (which is about purpose). Ships with built-in defaults
//  and, like categories, is fully user-editable. Mirrors ExpenseCategory rather
//  than sharing a generic type: SwiftData @Query wants a concrete model, and
//  keeping the two parallel reads more clearly than a generic abstraction.
//

import Foundation
import SwiftData

@Model
final class PaymentMethod {
    /// Display name, unique across payment methods.
    @Attribute(.unique) var name: String

    /// SF Symbol name used in the picker and rows.
    var symbolName: String

    /// True for the seeded default methods, false for user-created ones.
    var isBuiltIn: Bool

    /// Sort order for display; built-in methods keep their seeded order.
    var sortOrder: Int

    /// Expenses paid with this method. Nullified rather than cascaded so deleting
    /// a method never deletes its historical expenses.
    @Relationship(deleteRule: .nullify, inverse: \Expense.paymentMethod)
    var expenses: [Expense] = []

    init(name: String, symbolName: String, isBuiltIn: Bool, sortOrder: Int) {
        self.name = name
        self.symbolName = symbolName
        self.isBuiltIn = isBuiltIn
        self.sortOrder = sortOrder
    }
}

extension PaymentMethod {
    /// The default payment methods seeded on first launch, in display order.
    static let defaults: [(name: String, symbolName: String)] = [
        ("現金", "banknote"),
        ("信用卡", "creditcard"),
    ]

    /// SF Symbols offered when the user creates or edits a payment method.
    static let symbolChoices: [String] = [
        "banknote", "creditcard", "creditcard.fill", "dollarsign.circle",
        "wallet.bifold", "qrcode", "iphone", "applelogo", "giftcard.fill",
        "building.columns.fill", "arrow.left.arrow.right", "wonsign.circle",
    ]

    private static let didSeedDefaultsKey = "didSeedDefaultPaymentMethods"

    /// Inserts the default methods once, on first launch only. Guarded by a
    /// persisted flag so a user who deletes every default is not given them back.
    static func seedDefaultsIfNeeded(in context: ModelContext) {
        let defaults = AppGroupConstants.sharedDefaults ?? .standard
        guard !defaults.bool(forKey: didSeedDefaultsKey) else { return }

        for (index, entry) in Self.defaults.enumerated() {
            context.insert(
                PaymentMethod(
                    name: entry.name,
                    symbolName: entry.symbolName,
                    isBuiltIn: true,
                    sortOrder: index
                )
            )
        }
        defaults.set(true, forKey: didSeedDefaultsKey)
    }

    /// The next sort order to assign a user-created method, placing it after all
    /// existing ones.
    static func nextSortOrder(after methods: [PaymentMethod]) -> Int {
        (methods.map(\.sortOrder).max() ?? -1) + 1
    }
}
