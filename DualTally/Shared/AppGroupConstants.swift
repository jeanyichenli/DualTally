//
//  AppGroupConstants.swift
//  DualTally
//
//  Shared App Group configuration for the main app and the widget extension.
//  Both targets read/write the same SwiftData store and the same month-start-day
//  setting from this group's container so the widget shows the same balance cycle.
//

import Foundation

enum AppGroupConstants {
    /// App Group identifier shared by the main app and the widget extension.
    /// Must match the value configured in Signing & Capabilities for both targets.
    static let identifier = "group.com.yichenli.DualTally"

    /// Filename of the SwiftData store inside the shared container.
    static let storeFileName = "DualTally.sqlite"

    /// Shared `UserDefaults` suite backed by the App Group container.
    static let sharedDefaults = UserDefaults(suiteName: identifier)

    /// URL of the SwiftData store inside the App Group's shared container.
    /// Falls back to a temporary location if the container is unavailable, which
    /// should only happen when the App Group entitlement is misconfigured.
    static var storeURL: URL {
        let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: identifier)
            ?? URL.temporaryDirectory
        return containerURL.appending(path: storeFileName)
    }
}

/// The day of the month (1–28) on which each budgeting cycle begins.
///
/// Stored in the App Group's shared `UserDefaults` so the widget computes the
/// available balance over the same cycle as the main app. Kept out of SwiftData
/// deliberately: it is a single app-wide scalar, not a per-record value.
enum MonthStartDaySetting {
    static let key = "monthStartDay"

    /// Allowed range for the start day, avoiding month-end boundaries (29–31)
    /// that do not exist in every month.
    static let allowedRange = 1...28

    static let defaultValue = 1

    static var current: Int {
        get {
            guard let defaults = AppGroupConstants.sharedDefaults,
                  defaults.object(forKey: key) != nil else {
                return defaultValue
            }
            let stored = defaults.integer(forKey: key)
            return allowedRange.contains(stored) ? stored : defaultValue
        }
        set {
            let clamped = min(max(newValue, allowedRange.lowerBound), allowedRange.upperBound)
            AppGroupConstants.sharedDefaults?.set(clamped, forKey: key)
        }
    }
}
