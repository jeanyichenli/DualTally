//
//  ReportView.swift
//  DualTally
//
//  Daily-expense reports (roadmap step 7). Two view modes over the current
//  week, month, or year: a bar chart of total spending over time, or a pie
//  chart + table comparing every category's share of spending at once.
//  Aggregation lives in ReportCalculator; this view only picks options and
//  draws the chart/table.
//

import SwiftUI
import SwiftData
import Charts

struct ReportView: View {
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    @State private var range: ReportRange = .month
    @State private var mode: ReportMode = .total

    /// The bucket the user tapped on the total-spending chart, if any. Used to
    /// reveal that bucket's value on demand instead of cluttering every bar
    /// with a label, which would not fit a dense month view.
    @State private var selectedBucketDate: Date?

    private var dataPoints: [ReportDataPoint] {
        ReportCalculator.dataPoints(expenses: expenses, range: range)
    }

    private var categoryTotals: [CategoryTotal] {
        ReportCalculator.categoryTotals(expenses: expenses, range: range)
    }

    private var windowTotal: Decimal {
        ReportCalculator.total(expenses: expenses, range: range)
    }

    var body: some View {
        Form {
            Section {
                Picker("範圍", selection: $range) {
                    ForEach(ReportRange.allCases) { range in
                        Text(range.label).tag(range)
                    }
                }
                .pickerStyle(.segmented)

                Picker("檢視", selection: $mode) {
                    ForEach(ReportMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
            }

            Section {
                HStack {
                    Text("本\(range.label)總支出")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(windowTotal.formattedAsDailyCurrency())
                        .font(.headline)
                }
                switch mode {
                case .total:
                    totalChart
                        .frame(height: 240)
                        .padding(.vertical, 8)
                case .byCategory:
                    categoryPieChart
                        .frame(height: 240)
                        .padding(.vertical, 8)
                }
            }

            if mode == .byCategory && !categoryTotals.isEmpty {
                Section("分類明細") {
                    ForEach(categoryTotals) { item in
                        CategoryTotalRow(item: item)
                    }
                }
            }
        }
        .navigationTitle("報表")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Total-spending timeline

    @ViewBuilder
    private var totalChart: some View {
        if dataPoints.isEmpty {
            emptyState
        } else {
            Chart(dataPoints) { point in
                BarMark(
                    x: .value("日期", point.bucketDate, unit: range.bucketComponent),
                    y: .value("金額", point.amountValue)
                )
                .foregroundStyle(Color.accentColor)

                if let selection, selection.date == point.bucketDate {
                    RuleMark(x: .value("日期", selection.date, unit: range.bucketComponent))
                        .foregroundStyle(Color.secondary.opacity(0.3))
                        .annotation(
                            position: .top,
                            spacing: 0,
                            overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                        ) {
                            selectionCallout(selection)
                        }
                }
            }
            .chartXSelection(value: $selectedBucketDate)
            .chartXAxisLabel(range == .year ? "月份" : "日期")
            .chartYAxisLabel("金額（\(Decimal.dailyCurrencyCode)）")
            .chartXAxis {
                AxisMarks(values: .stride(by: axisStrideComponent, count: axisStrideCount)) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: axisLabelFormat)
                }
            }
            .onChange(of: range) { selectedBucketDate = nil }
        }
    }

    /// The little value label shown above the tapped bar, including the
    /// currency unit.
    private func selectionCallout(_ selection: (date: Date, total: Decimal)) -> some View {
        VStack(spacing: 2) {
            Text(selection.date.formatted(axisLabelFormat))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(selection.total.formattedAsDailyCurrency())
                .font(.caption.bold())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color(.secondarySystemBackground)))
    }

    /// The tapped bucket resolved to the nearest bar that has data.
    private var selection: (date: Date, total: Decimal)? {
        guard let selectedBucketDate, let bucket = nearestBucket(to: selectedBucketDate) else {
            return nil
        }
        let total = dataPoints.first { $0.bucketDate == bucket }?.amount ?? .zero
        return (bucket, total)
    }

    /// Snaps a raw selection date to the closest bucket that actually has bars.
    private func nearestBucket(to date: Date) -> Date? {
        dataPoints
            .map(\.bucketDate)
            .min { abs($0.timeIntervalSince(date)) < abs($1.timeIntervalSince(date)) }
    }

    private var axisStrideComponent: Calendar.Component {
        range == .year ? .month : .day
    }

    private var axisStrideCount: Int {
        // Label every day for a week, every 7th day for a dense month, every
        // month for a year.
        switch range {
        case .week: return 1
        case .month: return 7
        case .year: return 1
        }
    }

    /// Every tick spells out the month so a day number is never ambiguous
    /// about which month it falls in.
    private var axisLabelFormat: Date.FormatStyle {
        range == .year
            ? .dateTime.month(.abbreviated)
            : .dateTime.month(.abbreviated).day()
    }

    // MARK: Category comparison

    @ViewBuilder
    private var categoryPieChart: some View {
        if categoryTotals.isEmpty {
            emptyState
        } else {
            Chart(categoryTotals) { item in
                SectorMark(
                    angle: .value("金額", item.totalValue),
                    innerRadius: .ratio(0.55),
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value("分類", item.categoryName))
                .cornerRadius(3)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "本\(range.label)尚無支出",
            systemImage: "chart.bar",
            description: Text("這段期間沒有可統計的支出")
        )
        .frame(maxWidth: .infinity)
    }
}

/// One row in the category breakdown table: name, total spend (including
/// unpaid and outstanding advances), and share of the window's spending.
private struct CategoryTotalRow: View {
    let item: CategoryTotal

    var body: some View {
        HStack {
            Text(item.categoryName)
            Spacer()
            Text(item.total.formattedAsDailyCurrency())
                .foregroundStyle(.secondary)
            Text(item.share.formatted(.percent.precision(.fractionLength(0))))
                .frame(width: 48, alignment: .trailing)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }
}
