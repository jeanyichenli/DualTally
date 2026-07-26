//
//  AmountFormatter.swift
//  DualTally
//
//  Formatting helpers for daily-expense amounts. The daily module uses a single
//  implicit currency, so amounts are formatted with the device locale's
//  currency.
//

import Foundation

extension Decimal {
    /// The daily currency code, taken from the device locale (falls back to
    /// TWD). Daily expenses are single-currency, so this is not stored per
    /// record.
    static var dailyCurrencyCode: String {
        Locale.current.currency?.identifier ?? "TWD"
    }

    /// Formats the amount as currency in the daily currency, e.g. "NT$1,200".
    func formattedAsDailyCurrency() -> String {
        formatted(.currency(code: Decimal.dailyCurrencyCode).precision(.fractionLength(0)))
    }
}
