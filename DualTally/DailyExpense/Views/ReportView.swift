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
            }
            .chartLegend(mode == .byCategory ? .visible : .hidden)
            .chartXAxis {
                AxisMarks(values: .stride(by: axisStrideComponent, count: axisStrideCount)) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: axisLabelFormat)
                }
            }
        }
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
