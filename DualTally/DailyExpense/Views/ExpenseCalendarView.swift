//
//  ExpenseCalendarView.swift
//  DualTally
//
//  Calendar browse mode for the daily-expense tab. A month grid dots the days
//  that have expenses; tapping a day shows that day's subtotal and line items
//  below, with a shortcut to add an expense pre-dated to the selected day.
//
//  Note: the grid pages by calendar month, independent of the budgeting cycle
//  used by the stat-card. It is a browse affordance, not a balance view.
//

import SwiftUI
import SwiftData

struct ExpenseCalendarView: View {
    /// All expenses; day filtering happens locally so dots and subtotals stay in
    /// sync with the stat-card's source data.
    let expenses: [Expense]

    @Environment(\.modelContext) private var modelContext

    private let calendar = Calendar.current

    @State private var displayedMonth: Date = Calendar.current.startOfMonth(for: Date())
    @State private var selectedDay: Date = Calendar.current.startOfDay(for: Date())
    @State private var showingAddExpense = false
    @State private var editingExpense: Expense?

    private var daysWithExpenses: Set<Date> {
        DailyExpenseCalculator.daysWithExpenses(expenses, calendar: calendar)
    }

    private var selectedDayExpenses: [Expense] {
        expenses
            .filter { calendar.isDate($0.date, inSameDayAs: selectedDay) }
            .sorted { $0.date > $1.date }
    }

    private var selectedDayTotal: Decimal {
        DailyExpenseCalculator.countedTotal(on: selectedDay, expenses: expenses, calendar: calendar)
    }

    var body: some View {
        VStack(spacing: 0) {
            monthHeader
            weekdayHeader
            monthGrid
            Divider()
            selectedDayDetail
        }
        .sheet(isPresented: $showingAddExpense) {
            AddEditExpenseView(initialDate: selectedDay)
        }
        .sheet(item: $editingExpense) { expense in
            AddEditExpenseView(expense: expense)
        }
    }

    private var monthHeader: some View {
        HStack {
            monthStepButton(systemName: "chevron.left", delta: -1, label: "上個月")
            Spacer()
            Text(displayedMonth.formatted(.dateTime.year().month(.wide)))
                .font(.headline)
            Spacer()
            monthStepButton(systemName: "chevron.right", delta: 1, label: "下個月")
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
    }

    /// A chevron step button with a generous padded hit area so it's easy to hit
    /// deliberately without straying onto the stat-card above.
    private func monthStepButton(systemName: String, delta: Int, label: String) -> some View {
        Button { changeMonth(by: delta) } label: {
            Image(systemName: systemName)
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
    }

    private var weekdayHeader: some View {
        HStack {
            ForEach(calendar.shortWeekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 4)
    }

    private var monthGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 2) {
            ForEach(Array(monthDays.enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 34)
                }
            }
        }
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        // Swipe left/right across the grid to page months, as an alternative to
        // the chevrons. Only acts on a mostly-horizontal drag so it doesn't fight
        // vertical scrolling elsewhere.
        .gesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    if value.translation.width < 0 {
                        changeMonth(by: 1)
                    } else if value.translation.width > 0 {
                        changeMonth(by: -1)
                    }
                }
        )
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDay)
        let isToday = calendar.isDateInToday(day)
        let hasExpenses = daysWithExpenses.contains(calendar.startOfDay(for: day))
        return Button {
            selectedDay = calendar.startOfDay(for: day)
        } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? Color.white : (isToday ? Color.accentColor : .primary))
                Circle()
                    .fill(hasExpenses ? Color.accentColor : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(
                Circle()
                    .fill(isSelected ? Color.accentColor : Color.clear)
                    .frame(width: 30, height: 30)
                    .offset(y: -3)
            )
        }
        .buttonStyle(.plain)
    }

    private var selectedDayDetail: some View {
        VStack(spacing: 0) {
            // Header carries the day, its total, and the add button. Keeping add
            // up here — away from the tappable expense rows below — means it can't
            // be hit by accident while browsing the day's line items.
            HStack {
                Text(selectedDay.formatted(.dateTime.month(.abbreviated).day().weekday()))
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(selectedDayTotal.formattedAsDailyCurrency())
                    .font(.subheadline.weight(.semibold))
                Button {
                    showingAddExpense = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .accessibilityLabel("在這天新增支出")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            if selectedDayExpenses.isEmpty {
                ContentUnavailableView {
                    Label("這天尚無支出", systemImage: "calendar.badge.plus")
                } description: {
                    Text("點右上角＋新增")
                }
            } else {
                List {
                    ForEach(selectedDayExpenses) { expense in
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
                }
                .listStyle(.plain)
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var monthDays: [Date?] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: displayedMonth) else {
            return []
        }
        let firstOfMonth = calendar.startOfMonth(for: displayedMonth)
        // Number of blank leading cells before the 1st (Sunday-based grid).
        let leadingBlanks = (calendar.component(.weekday, from: firstOfMonth) - calendar.firstWeekday + 7) % 7
        let blanks: [Date?] = Array(repeating: nil, count: leadingBlanks)
        let days: [Date?] = monthRange.compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset - 1, to: firstOfMonth)
        }
        return blanks + days
    }

    private func delete(_ expense: Expense) {
        modelContext.delete(expense)
        DailyBalanceSnapshot.refresh(using: modelContext)
    }

    private func changeMonth(by delta: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: delta, to: displayedMonth) {
            withAnimation(.easeInOut(duration: 0.2)) {
                displayedMonth = calendar.startOfMonth(for: newMonth)
            }
        }
    }
}

extension Calendar {
    /// First moment of the month containing `date`.
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? startOfDay(for: date)
    }
}
