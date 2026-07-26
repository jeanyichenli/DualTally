//
//  DailyExpenseSettingsView.swift
//  DualTally
//
//  Sets the budget for the current cycle and the app-wide month start day.
//  Reached by tapping the stat-card. Changing either recomputes the available
//  balance, so the widget timeline is reloaded on save.
//

import SwiftUI
import SwiftData
import WidgetKit

struct DailyExpenseSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var budgets: [MonthlyBudget]

    @State private var startDay: Int
    @State private var budgetText: String

    init() {
        _startDay = State(initialValue: MonthStartDaySetting.current)
        _budgetText = State(initialValue: "")
    }

    /// The cycle currently being configured, driven by the chosen start day.
    private var cycle: BudgetCycle {
        BudgetCycleCalculator.cycle(containing: Date(), startDay: startDay)
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

                Section {
                    NavigationLink {
                        CategoryManagementView()
                    } label: {
                        Label("分類管理", systemImage: "tag")
                    }
                    NavigationLink {
                        PaymentMethodManagementView()
                    } label: {
                        Label("支付方式", systemImage: "creditcard")
                    }
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
        let end = Calendar.current.date(byAdding: .day, value: -1, to: cycle.end) ?? cycle.end
        let formatter = Date.FormatStyle.dateTime.month(.abbreviated).day()
        return "本週期：\(cycle.start.formatted(formatter)) – \(end.formatted(formatter))"
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

        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}
