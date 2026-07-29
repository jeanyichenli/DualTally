//
//  DualTallyWidget.swift
//  DualTallyWidget
//
//  Lock Screen widget for the daily-expense module. It shows one number — the
//  current cycle's available balance — which the main app publishes into the
//  App Group's shared defaults after every change (see DailyBalanceSnapshot).
//  The widget only reads that derived snapshot, so it never compiles the
//  SwiftData model layer.
//

import WidgetKit
import SwiftUI

/// Reads the balance snapshot the main app writes to the shared App Group
/// defaults. The keys must match `AppGroupConstants.WidgetSnapshotKey`, which
/// lives in the app target and is not compiled here.
private enum SharedStore {
    static let appGroupID = "group.com.yichenli.DualTally"
    static let balanceTextKey = "widget.balanceText"
    static let availableBalanceKey = "widget.availableBalance"
    static let cycleLabelKey = "widget.cycleLabel"

    static var defaults: UserDefaults? { UserDefaults(suiteName: appGroupID) }

    static func read() -> (balanceText: String, availableBalance: Double, cycleLabel: String)? {
        guard let defaults, let balanceText = defaults.string(forKey: balanceTextKey) else {
            return nil
        }
        return (
            balanceText,
            defaults.double(forKey: availableBalanceKey),
            defaults.string(forKey: cycleLabelKey) ?? ""
        )
    }
}

struct DailyBalanceEntry: TimelineEntry {
    let date: Date
    let balanceText: String
    let availableBalance: Double
    let cycleLabel: String
    /// True before the app has published any snapshot (fresh install).
    let isPlaceholder: Bool

    static let sample = DailyBalanceEntry(
        date: .now,
        balanceText: "$12,340",
        availableBalance: 12_340,
        cycleLabel: "7/5 – 8/4",
        isPlaceholder: false
    )
}

struct DailyBalanceProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyBalanceEntry {
        .sample
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyBalanceEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyBalanceEntry>) -> Void) {
        // The app reloads the timeline on every change, so the balance is always
        // fresh. Refresh again at the start of the next day to roll the cycle
        // label over even if the app has not been opened.
        let entry = currentEntry()
        let nextDay = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
        )
        completion(Timeline(entries: [entry], policy: .after(nextDay)))
    }

    private func currentEntry() -> DailyBalanceEntry {
        guard let snapshot = SharedStore.read() else {
            return DailyBalanceEntry(
                date: .now,
                balanceText: "—",
                availableBalance: 0,
                cycleLabel: "",
                isPlaceholder: true
            )
        }
        return DailyBalanceEntry(
            date: .now,
            balanceText: snapshot.balanceText,
            availableBalance: snapshot.availableBalance,
            cycleLabel: snapshot.cycleLabel,
            isPlaceholder: false
        )
    }
}

struct DualTallyWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DailyBalanceEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            Text("餘 \(entry.balanceText)")

        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 1) {
                    Text("餘")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(entry.balanceText)
                        .font(.headline)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                .padding(4)
            }

        default: // .accessoryRectangular
            VStack(alignment: .leading, spacing: 2) {
                Text("可用餘額")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(entry.balanceText)
                    .font(.title3.bold())
                if !entry.cycleLabel.isEmpty {
                    Text(entry.cycleLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct DualTallyWidget: Widget {
    let kind = "DualTallyDailyBalance"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyBalanceProvider()) { entry in
            DualTallyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("可用餘額")
        .description("顯示日常記帳本週期的剩餘可用金額")
        .supportedFamilies([.accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

@main
struct DualTallyWidgetBundle: WidgetBundle {
    var body: some Widget {
        DualTallyWidget()
    }
}
