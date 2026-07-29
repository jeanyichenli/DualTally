//
//  ReportView.swift
//  DualTally
//
//  Daily-expense reports (roadmap step 7). A bar chart over the current week,
//  month, or year, in one of three modes: total spending, a category breakdown
//  stacked per bar, or a single category's trend over time. Aggregation lives in
//  ReportCalculator; this view only picks options and draws the chart.
//

import SwiftUI
import SwiftData
import Charts

struct ReportView: View {
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    @State private var range: ReportRange = .month
    @State private var mode: ReportMode = .total
    @State private var selectedCategoryName: String?

    /// The bucket the user tapped on the chart, if any. Used to reveal that
    /// bucket's value on demand instead of cluttering every bar with a label —
    /// which would not fit a dense month view or a stacked bar.
    @State private var selectedBucketDate: Date?

    private var dataPoints: [ReportDataPoint] {
        ReportCalculator.dataPoints(
            expenses: expenses,
            range: range,
            mode: mode,
            selectedCategory: resolvedCategoryName
        )
    }

    private var windowTotal: Decimal {
        ReportCalculator.total(expenses: expenses, range: range)
    }

    /// The category the single-category mode reports on, falling back to the
    /// first available category if none was chosen yet.
    private var resolvedCategoryName: String? {
        selectedCategoryName ?? categories.first?.name
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

                if mode == .singleCategory {
                    Picker("分類", selection: categorySelection) {
                        ForEach(categories) { category in
                            Text(category.name).tag(category.name)
                        }
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
                chart
                    .frame(height: 240)
                    .padding(.vertical, 8)
            }
        }
        .navigationTitle("報表")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var chart: some View {
        if dataPoints.isEmpty {
            ContentUnavailableView(
                "本\(range.label)尚無支出",
                systemImage: "chart.bar",
                description: Text("這段期間沒有可統計的支出")
            )
            .frame(maxWidth: .infinity)
        } else {
            Chart(dataPoints) { point in
                BarMark(
                    x: .value("期間", point.bucketDate, unit: range.bucketComponent),
                    y: .value("金額", point.amountValue)
                )
                .foregroundStyle(by: .value("分類", point.categoryName))

                if let selection, selection.date == point.bucketDate {
                    RuleMark(x: .value("期間", selection.date, unit: range.bucketComponent))
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
            .chartLegend(mode == .byCategory ? .visible : .hidden)
            .chartXSelection(value: $selectedBucketDate)
            .chartXAxis {
                AxisMarks(values: .stride(by: axisStrideComponent, count: axisStrideCount)) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: axisLabelFormat)
                }
            }
            .onChange(of: range) { selectedBucketDate = nil }
            .onChange(of: mode) { selectedBucketDate = nil }
        }
    }

    /// The little value label shown above the tapped bar: the period and its
    /// total (the sum of every category segment in that bucket).
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

    /// The tapped bucket resolved to the nearest bar that has data, with that
    /// bucket's total across all its category segments.
    private var selection: (date: Date, total: Decimal)? {
        guard let selectedBucketDate, let bucket = nearestBucket(to: selectedBucketDate) else {
            return nil
        }
        let total = dataPoints
            .filter { $0.bucketDate == bucket }
            .reduce(Decimal.zero) { $0 + $1.amount }
        return (bucket, total)
    }

    /// Snaps a raw selection date to the closest bucket that actually has bars.
    private func nearestBucket(to date: Date) -> Date? {
        dataPoints
            .map(\.bucketDate)
            .min { abs($0.timeIntervalSince(date)) < abs($1.timeIntervalSince(date)) }
    }

    /// Binding that keeps the segmented single-category picker in sync with the
    /// resolved fallback, so it shows a selection even before the user taps one.
    private var categorySelection: Binding<String> {
        Binding(
            get: { resolvedCategoryName ?? "" },
            set: { selectedCategoryName = $0 }
        )
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

    private var axisLabelFormat: Date.FormatStyle {
        range == .year
            ? .dateTime.month(.narrow)
            : .dateTime.day()
    }
}
