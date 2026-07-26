//
//  DailyExpenseListView.swift
//  DualTally
//
//  Root screen of the daily-expense tab: a stat-card over either a flat expense
//  list or a calendar browse mode, toggled from the toolbar.
//

import SwiftUI
import SwiftData

struct DailyExpenseListView: View {
    private enum BrowseMode {
        case list, calendar
    }

    private enum Route: Hashable {
        case report, review, advance
    }

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var budgets: [MonthlyBudget]

    @State private var browseMode: BrowseMode = .list
    @State private var routes: [Route] = []
    @State private var showingSettings = false
    @State private var showingAddExpense = false
    @State private var editingExpense: Expense?

    private var cycle: BudgetCycle {
        BudgetCycleCalculator.currentCycle()
    }

    private var cycleExpenses: [Expense] {
        DailyExpenseCalculator.expenses(expenses, in: cycle)
    }

    private var summary: DailyExpenseSummary {
        let budget = budgets.first { $0.cycleStart == cycle.start }?.amount
        return DailyExpenseCalculator.summary(budget: budget, cycleExpenses: cycleExpenses)
    }

    var body: some View {
        NavigationStack(path: $routes) {
            VStack(spacing: 0) {
                DailyStatCard(summary: summary, cycle: cycle)
                    .padding()
                    .contentShape(Rectangle())
                    .onTapGesture { showingSettings = true }

                switch browseMode {
                case .list:
                    expenseList
                case .calendar:
                    ExpenseCalendarView(expenses: expenses)
                }
            }
            .navigationTitle("日常記帳")
            .toolbar { toolbarContent }
            .navigationDestination(for: Route.self, destination: destination)
            .overlay(alignment: .bottomTrailing) { addButton }
            .sheet(isPresented: $showingAddExpense) {
                AddEditExpenseView()
            }
            .sheet(item: $editingExpense) { expense in
                AddEditExpenseView(expense: expense)
            }
            .sheet(isPresented: $showingSettings) {
                DailyExpenseSettingsView()
            }
        }
    }

    @ViewBuilder
    private var expenseList: some View {
        if cycleExpenses.isEmpty {
            ContentUnavailableView(
                "本週期尚無支出",
                systemImage: "tray",
                description: Text("點右下角＋新增第一筆支出")
            )
        } else {
            List {
                ForEach(cycleExpenses) { expense in
                    Button {
                        editingExpense = expense
                    } label: {
                        ExpenseRow(expense: expense)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteExpenses)
            }
            .listStyle(.plain)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                browseMode = browseMode == .list ? .calendar : .list
            } label: {
                Image(systemName: browseMode == .list ? "calendar" : "list.bullet")
            }
            .accessibilityLabel(browseMode == .list ? "切換到日曆" : "切換到列表")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button { routes.append(.report) } label: {
                    Label("報表", systemImage: "chart.bar.fill")
                }
                Button { routes.append(.review) } label: {
                    Label("復盤", systemImage: "checklist")
                }
                Button { routes.append(.advance) } label: {
                    Label("墊付", systemImage: "hand.raised.fill")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .report: ReportView()
        case .review: MonthlyReviewView()
        case .advance: AdvancePaymentView()
        }
    }

    private var addButton: some View {
        Button {
            showingAddExpense = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .frame(width: 56, height: 56)
                .foregroundStyle(.white)
                .background(Circle().fill(Color.accentColor))
                .shadow(radius: 4, y: 2)
        }
        .padding()
        .accessibilityLabel("新增支出")
    }

    private func deleteExpenses(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(cycleExpenses[index])
        }
    }
}

/// The three headline numbers for the current cycle.
private struct DailyStatCard: View {
    let summary: DailyExpenseSummary
    let cycle: BudgetCycle

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("可用餘額")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(cycleLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(summary.availableBalance.formattedAsDailyCurrency())
                .font(.largeTitle.bold())
                .foregroundStyle(summary.availableBalance < 0 ? .red : .primary)
            HStack {
                labelledAmount("預算", summary.budget)
                Spacer()
                labelledAmount("已花費", summary.spent)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }

    private var cycleLabel: String {
        let end = Calendar.current.date(byAdding: .day, value: -1, to: cycle.end) ?? cycle.end
        let style = Date.FormatStyle.dateTime.month(.abbreviated).day()
        return "\(cycle.start.formatted(style)) – \(end.formatted(style))"
    }

    private func labelledAmount(_ label: String, _ amount: Decimal) -> some View {
        HStack(spacing: 4) {
            Text(label)
            Text(amount.formattedAsDailyCurrency()).foregroundStyle(.primary)
        }
    }
}

/// One row in the flat expense list.
struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: expense.isPaid ? "circle.fill" : "circle")
                .font(.caption2)
                .foregroundStyle(expense.isPaid ? Color.accentColor : Color.secondary)

            Image(systemName: expense.category?.symbolName ?? "questionmark.circle")
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.category?.name ?? "未分類")
                if expense.isOutstandingAdvance, let name = expense.advancePaidForName {
                    Text("墊 \(name)")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else if let note = expense.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(expense.amount.formattedAsDailyCurrency())
                    .strikethrough(expense.isAdvancePayment && expense.isRepaid)
                Text(expense.date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
