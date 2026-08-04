//
//  MonthlyReviewView.swift
//  DualTally
//
//  Monthly impulse review (roadmap step 6). Walk the current cycle's expenses
//  and flag, in hindsight, which were impulse purchases; a header shows the
//  impulse share of total spending. This is the ONLY place `isImpulse` is set —
//  the add/edit form never exposes it, since you rarely think you're being
//  impulsive in the moment.
//

import SwiftUI
import SwiftData

struct MonthlyReviewView: View {
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    private var cycle: BudgetCycle {
        BudgetCycleCalculator.currentCycle()
    }

    /// Counted expenses in the current cycle, newest first. Repaid advances drop
    /// out so they can't be flagged or counted toward the impulse share.
    private var reviewableExpenses: [Expense] {
        DailyExpenseCalculator.expenses(expenses, in: cycle)
            .filter(\.countsAsSpending)
    }

    private var summary: ImpulseReviewSummary {
        DailyExpenseCalculator.impulseReviewSummary(reviewableExpenses)
    }

    private var cycleRangeLabel: String {
        cycle.rangeLabel()
    }

    var body: some View {
        Group {
            if reviewableExpenses.isEmpty {
                ContentUnavailableView(
                    "本週期尚無可復盤的支出",
                    systemImage: "checklist",
                    description: Text("記幾筆支出後，回來標記哪些是衝動購物")
                )
            } else {
                reviewList
            }
        }
        .navigationTitle("復盤")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var reviewList: some View {
        List {
            Section {
                ImpulseShareHeader(summary: summary)
            } footer: {
                Text("點一筆支出可標記／取消「衝動購物」。此標記只影響復盤統計，不影響餘額。")
            }

            Section("本週期支出（\(cycleRangeLabel)）") {
                ForEach(reviewableExpenses) { expense in
                    Button {
                        expense.isImpulse.toggle()
                    } label: {
                        ReviewRow(expense: expense)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

/// The impulse-share readout at the top of the review: the percentage large,
/// with the impulse amount and count beneath.
private struct ImpulseShareHeader: View {
    let summary: ImpulseReviewSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("衝動購物佔比")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(summary.impulseCount) 筆")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(summary.impulseShare.formatted(.percent.precision(.fractionLength(0))))
                .font(.title.bold())
                .foregroundStyle(summary.impulseShare > 0 ? .orange : .primary)
            HStack(spacing: 4) {
                Text("衝動金額")
                Text(summary.impulseTotal.formattedAsDailyCurrency())
                    .foregroundStyle(.primary)
                Text("／ 總支出")
                Text(summary.totalSpending.formattedAsDailyCurrency())
                    .foregroundStyle(.primary)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

/// One reviewable expense: category, date and amount, with a flame that fills
/// when the expense is flagged as an impulse purchase.
private struct ReviewRow: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: expense.isImpulse ? "flame.fill" : "flame")
                .foregroundStyle(expense.isImpulse ? .orange : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.category?.name ?? "未分類")
                Text(expense.date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(expense.amount.formattedAsDailyCurrency())
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
