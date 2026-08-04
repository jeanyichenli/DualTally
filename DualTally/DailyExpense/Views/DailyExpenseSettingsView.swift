//
//  DailyExpenseSettingsView.swift
//  DualTally
//
//  Sets the budget for the current cycle and the app-wide month start day.
//  Reached by tapping the stat-card. Changing either recomputes the available
//  balance, so the widget timeline is reloaded on save. Category and payment
//  method management live under the toolbar's "設定" submenu instead of here,
//  so this stays focused on the budget itself.
//

import SwiftUI
import SwiftData

struct DailyExpenseSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var budgets: [MonthlyBudget]

    @State private var startDay: Int
    @State private var budgetText: String

    /// A date inside the cycle being configured. Defaults to today, but the
    /// caller passes the start of whatever cycle is currently browsed (see
    /// DailyExpenseListView's cycle navigator) so editing the budget always
    /// targets the period actually on screen, not always "this month".
    private let referenceDate: Date

    init(referenceDate: Date = Date()) {
        self.referenceDate = referenceDate
        _startDay = State(initialValue: MonthStartDaySetting.current)
        _budgetText = State(initialValue: "")
    }

    /// The cycle currently being configured, driven by the chosen start day.
    private var cycle: BudgetCycle {
        BudgetCycleCalculator.cycle(containing: referenceDate, startDay: startDay)
    }

    private var budgetForCycle: MonthlyBudget? {
        budgets.first { $0.cycleStart == cycle.start }
    }

    private var parsedBudget: Decimal? {
        let trimmed = budgetText.trimmingCharacters(in: .whitespaces)
        guard let value = Decimal(string: trimmed), value >= 0 else { return nil }
        return value
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("金額", text: $budgetText)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("本週期預算")
                } footer: {
                    Text(cycleRangeDescription)
                }

                Section {
                    Picker("每月起算日", selection: $startDay) {
                        ForEach(MonthStartDaySetting.allowedRange, id: \.self) { day in
                            Text("\(day) 號").tag(day)
                        }
                    }
                } footer: {
                    Text("一個「月」從這天開始，可設 1–28 號以對齊薪水日等週期。")
                }
            }
            .navigationTitle("預算設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") { save() }
                        .disabled(parsedBudget == nil)
                }
            }
            .onAppear(perform: loadBudgetText)
            .onChange(of: startDay) { loadBudgetText() }
        }
    }

    private var cycleRangeDescription: String {
        "本週期：\(cycle.rangeLabel())"
    }

    private func loadBudgetText() {
        if let amount = budgetForCycle?.amount {
            budgetText = NSDecimalNumber(decimal: amount).stringValue
        } else {
            budgetText = ""
        }
    }

    private func save() {
        guard let amount = parsedBudget else { return }
        MonthStartDaySetting.current = startDay

        if let existing = budgetForCycle {
            existing.amount = amount
        } else {
            modelContext.insert(MonthlyBudget(cycleStart: cycle.start, amount: amount))
        }

        DailyBalanceSnapshot.refresh(using: modelContext)
        dismiss()
    }
}
