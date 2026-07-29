//
//  AdvancePaymentView.swift
//  DualTally
//
//  Advance-payment tracking screen (roadmap step 5). Lists money the user
//  fronted for other people, grouped by who owes them, with the total still to
//  be recovered. Marking an advance repaid excludes it from every total and
//  restores the available balance, so the widget timeline is reloaded on change.
//

import SwiftUI
import SwiftData
import WidgetKit

struct AdvancePaymentView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var expenses: [Expense]

    private var outstandingTotal: Decimal {
        DailyExpenseCalculator.outstandingAdvanceTotal(expenses)
    }

    private var outstandingByPerson: [(name: String, expenses: [Expense])] {
        DailyExpenseCalculator.outstandingAdvancesByPerson(expenses)
    }

    private var repaidAdvances: [Expense] {
        DailyExpenseCalculator.repaidAdvances(expenses)
    }

    var body: some View {
        Group {
            if outstandingByPerson.isEmpty && repaidAdvances.isEmpty {
                ContentUnavailableView(
                    "沒有墊付紀錄",
                    systemImage: "hand.raised.fill",
                    description: Text("在新增支出時打開「墊付」開關，就會出現在這裡")
                )
            } else {
                advanceList
            }
        }
        .navigationTitle("墊付")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var advanceList: some View {
        List {
            Section {
                HStack {
                    Text("尚未收回")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(outstandingTotal.formattedAsDailyCurrency())
                        .font(.title3.bold())
                        .foregroundStyle(outstandingTotal > 0 ? .orange : .primary)
                }
            }

            ForEach(outstandingByPerson, id: \.name) { group in
                Section {
                    ForEach(group.expenses) { advance in
                        AdvanceRow(advance: advance) {
                            markRepaid(advance)
                        }
                    }
                } header: {
                    HStack {
                        Text(personName(group.name))
                        Spacer()
                        Text(groupTotal(group.expenses).formattedAsDailyCurrency())
                    }
                    .textCase(nil)
                }
            }

            if !repaidAdvances.isEmpty {
                Section("已收回") {
                    ForEach(repaidAdvances) { advance in
                        RepaidAdvanceRow(advance: advance) {
                            markOutstanding(advance)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func personName(_ name: String) -> String {
        name.isEmpty ? "未填姓名" : name
    }

    private func groupTotal(_ expenses: [Expense]) -> Decimal {
        expenses.reduce(Decimal.zero) { $0 + $1.amount }
    }

    private func markRepaid(_ advance: Expense) {
        advance.isRepaid = true
        advance.repaidDate = Date()
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func markOutstanding(_ advance: Expense) {
        advance.isRepaid = false
        advance.repaidDate = nil
        WidgetCenter.shared.reloadAllTimelines()
    }
}

/// One outstanding advance: what it was and how much, with a button to mark it
/// paid back.
private struct AdvanceRow: View {
    let advance: Expense
    let onMarkRepaid: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(advance.category?.name ?? "未分類")
                Text(advance.date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let note = advance.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(advance.amount.formattedAsDailyCurrency())
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(action: onMarkRepaid) {
                Label("已收回", systemImage: "checkmark.circle.fill")
            }
            .tint(.green)
        }
    }
}

/// A repaid advance in the history section, with a button to put it back to
/// outstanding if it was marked by mistake.
private struct RepaidAdvanceRow: View {
    let advance: Expense
    let onMarkOutstanding: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(repaidTitle)
                    .foregroundStyle(.secondary)
                Text(advance.amount.formattedAsDailyCurrency())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(action: onMarkOutstanding) {
                Label("改回未收回", systemImage: "arrow.uturn.backward")
            }
            .tint(.orange)
        }
    }

    private var repaidTitle: String {
        let who = advance.advancePaidForName ?? ""
        let category = advance.category?.name ?? "未分類"
        return who.isEmpty ? category : "\(who) · \(category)"
    }
}
