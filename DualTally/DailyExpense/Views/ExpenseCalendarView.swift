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

struct ExpenseCalendarView: View {
    /// All expenses; day filtering happens locally so dots and subtotals stay in
    /// sync with the stat-card's source data.
    let expenses: [Expense]

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
            Button { changeMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(displayedMonth.formatted(.dateTime.year().month(.wide)))
                .font(.headline)
            Spacer()
            Button { changeMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
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
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
            ForEach(Array(monthDays.enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 40)
                }
            }
        }
        .padding(.horizontal, 4)
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDay)
        let isToday = calendar.isDateInToday(day)
        let hasExpenses = daysWithExpenses.contains(calendar.startOfDay(for: day))
        return Button {
            selectedDay = calendar.startOfDay(for: day)
        } label: {
            VStack(spacing: 3) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.callout)
                    .foregroundStyle(isSelected ? Color.white : (isToday ? Color.accentColor : .primary))
                Circle()
                    .fill(hasExpenses ? Color.accentColor : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(
                Circle()
                    .fill(isSelected ? Color.accentColor : Color.clear)
                    .frame(width: 34, height: 34)
                    .offset(y: -4)
            )
        }
        .buttonStyle(.plain)
    }

    private var selectedDayDetail: some View {
        VStack(spacing: 0) {
            HStack {
                Text(selectedDay.formatted(.dateTime.month(.abbreviated).day().weekday()))
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(selectedDayTotal.formattedAsDailyCurrency())
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            if selectedDayExpenses.isEmpty {
                Spacer()
                Button {
                    showingAddExpense = true
                } label: {
                    Label("在這天新增支出", systemImage: "plus.circle")
                }
                .padding()
                Spacer()
            } else {
                List {
                    ForEach(selectedDayExpenses) { expense in
                        Button {
                            editingExpense = expense
                        } label: {
                            ExpenseRow(expense: expense)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.plain)
                .safeAreaInset(edge: .bottom) {
                    Button {
                        showingAddExpense = true
                    } label: {
                        Label("在這天新增支出", systemImage: "plus.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                }
            }
        }
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

    private func changeMonth(by delta: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: delta, to: displayedMonth) {
            displayedMonth = calendar.startOfMonth(for: newMonth)
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
