//
//  AdvancePaymentView.swift
//  DualTally
//
//  Advance-payment tracking screen (roadmap step 5). Lists money the user
//  fronted for other people, grouped by who owes them, with the total still to
//  be recovered. Marking an advance repaid excludes it from every total and
//  restores the available balance, so the widget timeline is reloaded on change.
//
//  The outstanding list is a snapshot that only rebuilds on pull-to-refresh, so
//  a just-confirmed repayment stays on screen (struck through, and undoable by
//  tapping again) instead of vanishing the instant it is tapped. Pulling to
//  refresh is what clears the settled rows away.
//

import SwiftUI
import SwiftData
import WidgetKit

struct AdvancePaymentView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var expenses: [Expense]

    /// One person's outstanding advances in the current snapshot.
    private struct PersonGroup: Identifiable {
        let name: String
        let expenses: [Expense]
        var id: String { name }
    }

    @State private var outstandingGroups: [PersonGroup] = []
    @State private var repaidRows: [Expense] = []
    @State private var didLoad = false

    private var outstandingRows: [Expense] {
        outstandingGroups.flatMap(\.expenses)
    }

    /// Total still owed. Rows the user just marked repaid (pending a refresh)
    /// drop out immediately so the number reflects the tap, even though the row
    /// stays visible for undo.
    private var outstandingTotal: Decimal {
        outstandingRows
            .filter { !$0.isRepaid }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    var body: some View {
        Group {
            if outstandingGroups.isEmpty && repaidRows.isEmpty {
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
        .onAppear {
            guard !didLoad else { return }
            reload()
            didLoad = true
        }
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
            } footer: {
                Text("點右側圓圈標記已還款；下拉重新整理才會把已還款的項目清除。")
            }

            ForEach(outstandingGroups) { group in
                Section {
                    ForEach(group.expenses) { advance in
                        AdvanceRow(advance: advance) {
                            toggleRepaid(advance)
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

            if !repaidRows.isEmpty {
                Section("已收回") {
                    ForEach(repaidRows) { advance in
                        RepaidAdvanceRow(advance: advance) {
                            markOutstanding(advance)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable { reload() }
    }

    private func personName(_ name: String) -> String {
        name.isEmpty ? "未填姓名" : name
    }

    /// A group's still-owed total, matching the headline number by dropping rows
    /// already marked repaid this session.
    private func groupTotal(_ expenses: [Expense]) -> Decimal {
        expenses
            .filter { !$0.isRepaid }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    /// Rebuilds the snapshot from the live query. Called on first appear and on
    /// pull-to-refresh — the only points where settled rows leave the list.
    private func reload() {
        outstandingGroups = DailyExpenseCalculator.outstandingAdvancesByPerson(expenses)
            .map { PersonGroup(name: $0.name, expenses: $0.expenses) }
        repaidRows = DailyExpenseCalculator.repaidAdvances(expenses)
    }

    /// Toggles an outstanding row's repaid state in place. The row stays in the
    /// snapshot until the next refresh, so a mis-tap can be undone by tapping
    /// again.
    private func toggleRepaid(_ advance: Expense) {
        advance.isRepaid.toggle()
        advance.repaidDate = advance.isRepaid ? Date() : nil
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func markOutstanding(_ advance: Expense) {
        advance.isRepaid = false
        advance.repaidDate = nil
        WidgetCenter.shared.reloadAllTimelines()
        reload()
    }
}

/// One outstanding advance: what it was and how much, with a tappable circle to
/// confirm it was paid back (filled check) or undo that (empty circle).
private struct AdvanceRow: View {
    let advance: Expense
    let onToggleRepaid: () -> Void

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
                .foregroundStyle(advance.isRepaid ? .secondary : .primary)
                .strikethrough(advance.isRepaid)

            Button(action: onToggleRepaid) {
                Image(systemName: advance.isRepaid ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(advance.isRepaid ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(advance.isRepaid ? "取消還款標記" : "確認已還款")
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
