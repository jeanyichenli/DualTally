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
        case report, review, advance, categories, paymentMethods
    }

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var budgets: [MonthlyBudget]

    @State private var browseMode: BrowseMode = .list
    @State private var routes: [Route] = []
    @State private var showingSettings = false
    @State private var showingAddExpense = false
    @State private var editingExpense: Expense?
    // Cycles away from the current one; list mode can browse to a neighbor to
    // review its budget and expenses. The widget always shows the current
    // cycle regardless of this — see DailyBalanceSnapshot.
    @State private var cycleOffset = 0

    private var cycle: BudgetCycle {
        let current = BudgetCycleCalculator.currentCycle()
        guard cycleOffset != 0,
              let shiftedStart = Calendar.current.date(byAdding: .month, value: cycleOffset, to: current.start)
        else {
            return current
        }
        return BudgetCycleCalculator.cycle(containing: shiftedStart, startDay: MonthStartDaySetting.current)
    }

    private var cycleExpenses: [Expense] {
        DailyExpenseCalculator.expenses(expenses, in: cycle)
    }

    private var groupedExpenses: [(day: Date, expenses: [Expense])] {
        DailyExpenseCalculator.groupedByDay(cycleExpenses)
    }

    private var summary: DailyExpenseSummary {
        let budget = budgets.first { $0.cycleStart == cycle.start }?.amount
        return DailyExpenseCalculator.summary(budget: budget, cycleExpenses: cycleExpenses)
    }

    var body: some View {
        NavigationStack(path: $routes) {
            VStack(spacing: 0) {
                DailyStatCard(summary: summary, cycle: cycle)
                    .padding(.horizontal)
                    .padding(.top, 4)
                    .padding(.bottom, 8)
                    .contentShape(Rectangle())
                    .onTapGesture { showingSettings = true }

                if browseMode == .list {
                    cycleNavigator
                }

                switch browseMode {
                case .list:
                    expenseList
                case .calendar:
                    ExpenseCalendarView(expenses: expenses)
                }
            }
            // No visible title — the tab bar already labels this "日常記帳", so a
            // slim inline bar keeps the toolbar controls without spending a whole
            // large-title row of vertical space.
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .navigationDestination(for: Route.self, destination: destination)
            .overlay(alignment: .bottomTrailing) {
                // Calendar mode has its own day-specific "在這天新增支出" button,
                // so the floating add button only appears in list mode.
                if browseMode == .list {
                    addButton
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddEditExpenseView()
            }
            .sheet(item: $editingExpense) { expense in
                AddEditExpenseView(expense: expense)
            }
            .sheet(isPresented: $showingSettings) {
                DailyExpenseSettingsView(referenceDate: cycle.start)
            }
        }
    }

    /// Lets list mode browse the budget and expenses of a neighboring cycle,
    /// independent from the widget's snapshot which always shows the current one.
    private var cycleNavigator: some View {
        HStack {
            cycleStepButton(systemName: "chevron.left", delta: -1, label: "上一期")

            Spacer()

            if cycleOffset != 0 {
                Button("回到本期") { cycleOffset = 0 }
                    .font(.caption)
            }

            Spacer()

            cycleStepButton(systemName: "chevron.right", delta: 1, label: "下一期")
        }
        .padding(.horizontal, 12)
        // A clear gap from the stat-card above so an imprecise tap near the
        // chevrons can't bleed onto the card's tap-to-open-settings gesture.
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    /// A chevron with a generous padded hit area — matching the calendar's own
    /// month-step buttons — so it's easy to hit deliberately instead of
    /// accidentally landing on the stat-card above it.
    private func cycleStepButton(systemName: String, delta: Int, label: String) -> some View {
        Button {
            cycleOffset += delta
        } label: {
            Image(systemName: systemName)
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
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
                ForEach(groupedExpenses, id: \.day) { group in
                    Section {
                        ForEach(group.expenses) { expense in
                            Button {
                                editingExpense = expense
                            } label: {
                                ExpenseRow(expense: expense)
                            }
                            .buttonStyle(.plain)
                            .expenseRowActions(
                                onEdit: { editingExpense = expense },
                                onDelete: { delete(expense) }
                            )
                        }
                    } header: {
                        DaySectionHeader(
                            day: group.day,
                            total: DailyExpenseCalculator.countedTotal(on: group.day, expenses: cycleExpenses)
                        )
                    }
                }
            }
            .listStyle(.insetGrouped)
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
                Menu {
                    Button { routes.append(.categories) } label: {
                        Label("分類管理", systemImage: "tag")
                    }
                    Button { routes.append(.paymentMethods) } label: {
                        Label("支付方式", systemImage: "creditcard")
                    }
                } label: {
                    Label("設定", systemImage: "gearshape.fill")
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
        case .categories: CategoryManagementView()
        case .paymentMethods: PaymentMethodManagementView()
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

    private func delete(_ expense: Expense) {
        modelContext.delete(expense)
        DailyBalanceSnapshot.refresh(using: modelContext)
    }
}

/// Shared swipe-to-delete + long-press edit/delete menu for an expense row.
/// Applied in both the flat list and the calendar's selected-day list so the
/// two browse modes offer identical row actions.
extension View {
    func expenseRowActions(onEdit: @escaping () -> Void, onDelete: @escaping () -> Void) -> some View {
        self
            .swipeActions(edge: .trailing) {
                Button(role: .destructive, action: onDelete) {
                    Label("刪除", systemImage: "trash")
                }
            }
            .contextMenu {
                Button(action: onEdit) {
                    Label("編輯", systemImage: "pencil")
                }
                Button(role: .destructive, action: onDelete) {
                    Label("刪除", systemImage: "trash")
                }
            }
    }
}

/// A prominent per-day header for the sectioned expense list: the date on the
/// left, that day's counted total on the right.
private struct DaySectionHeader: View {
    let day: Date
    let total: Decimal

    var body: some View {
        HStack {
            Text(day.formatted(.dateTime.month(.abbreviated).day().weekday()))
            Spacer()
            Text(total.formattedAsDailyCurrency())
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.primary)
        .textCase(nil)
    }
}

/// The three headline numbers for the current cycle.
private struct DailyStatCard: View {
    let summary: DailyExpenseSummary
    let cycle: BudgetCycle

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("可用餘額")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(cycleLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(summary.availableBalance.formattedAsDailyCurrency())
                .font(.title.bold())
                .foregroundStyle(summary.availableBalance < 0 ? .red : .primary)
            HStack {
                labelledAmount("預算", summary.budget)
                Spacer()
                labelledAmount("已花費", summary.spent)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
    }

    private var cycleLabel: String {
        cycle.rangeLabel()
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
            // Only unpaid expenses carry a leading marker; paid ones (the common
            // case) start straight at the category icon, keeping the list clean.
            if !expense.isPaid {
                Image(systemName: "circle")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("未付款")
            }

            Image(systemName: expense.category?.symbolName ?? "questionmark.circle")
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.category?.name ?? "未分類")
                // Advance badge and note are independent: an advance can also
                // carry a note, so show both lines rather than one or the other.
                if expense.isOutstandingAdvance, let name = expense.advancePaidForName {
                    Text("墊 \(name)")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                if let note = expense.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(expense.amount.formattedAsDailyCurrency())
                .strikethrough(expense.isAdvancePayment && expense.isRepaid)
        }
        .padding(.vertical, 4)
        // Make the whole row rectangle—including the blank gaps and the Spacer—
        // tappable, so an edit tap registers anywhere on the row, not only on the
        // text and icons.
        .contentShape(Rectangle())
    }
}
