//
//  AddEditExpenseView.swift
//  DualTally
//
//  Add or edit one daily expense. Deliberately has no impulse-purchase field —
//  that flag is only ever set from the monthly review screen.
//

import SwiftUI
import SwiftData
import WidgetKit

struct AddEditExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
    @Query(sort: \PaymentMethod.sortOrder) private var paymentMethods: [PaymentMethod]

    /// The expense being edited, or nil when adding a new one.
    private let expenseToEdit: Expense?

    @State private var amountText: String
    @State private var selectedCategory: ExpenseCategory?
    @State private var selectedPaymentMethod: PaymentMethod?
    @State private var date: Date
    @State private var isPaid: Bool
    @State private var isAdvancePayment: Bool
    @State private var advancePaidForName: String
    @State private var note: String

    /// - Parameters:
    ///   - expense: pass an existing expense to edit it, or nil to add.
    ///   - initialDate: starting date for a new expense (e.g. the day tapped in
    ///     the calendar). Ignored when editing.
    init(expense: Expense? = nil, initialDate: Date = Date()) {
        self.expenseToEdit = expense
        _amountText = State(initialValue: expense.map { NSDecimalNumber(decimal: $0.amount).stringValue } ?? "")
        _selectedCategory = State(initialValue: expense?.category)
        _selectedPaymentMethod = State(initialValue: expense?.paymentMethod)
        _date = State(initialValue: expense?.date ?? initialDate)
        _isPaid = State(initialValue: expense?.isPaid ?? true)
        _isAdvancePayment = State(initialValue: expense?.isAdvancePayment ?? false)
        _advancePaidForName = State(initialValue: expense?.advancePaidForName ?? "")
        _note = State(initialValue: expense?.note ?? "")
    }

    private var parsedAmount: Decimal? {
        let trimmed = amountText.trimmingCharacters(in: .whitespaces)
        guard let value = Decimal(string: trimmed), value > 0 else { return nil }
        return value
    }

    private var isValid: Bool {
        guard parsedAmount != nil, selectedCategory != nil else { return false }
        if isAdvancePayment {
            return !advancePaidForName.trimmingCharacters(in: .whitespaces).isEmpty
        }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("金額", text: $amountText)
                        .keyboardType(.decimalPad)
                    Picker("分類", selection: $selectedCategory) {
                        ForEach(categories) { category in
                            Label(category.name, systemImage: category.symbolName)
                                .tag(Optional(category))
                        }
                    }
                    Picker("支付方式", selection: $selectedPaymentMethod) {
                        ForEach(paymentMethods) { method in
                            Label(method.name, systemImage: method.symbolName)
                                .tag(Optional(method))
                        }
                    }
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                    Toggle("已付款", isOn: $isPaid)
                }

                Section {
                    Toggle("墊付", isOn: $isAdvancePayment)
                    if isAdvancePayment {
                        TextField("幫誰墊付", text: $advancePaidForName)
                    }
                } footer: {
                    if isAdvancePayment {
                        Text("這筆整筆是幫對方代墊。在對方歸還前照算入你的支出，於「墊付」畫面勾選歸還後移除。")
                    }
                }

                Section("備註") {
                    TextField("選填", text: $note, axis: .vertical)
                }
            }
            .navigationTitle(expenseToEdit == nil ? "新增支出" : "編輯支出")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") { save() }
                        .disabled(!isValid)
                }
            }
            .onAppear {
                if selectedCategory == nil {
                    selectedCategory = categories.first
                }
                if selectedPaymentMethod == nil {
                    selectedPaymentMethod = paymentMethods.first
                }
            }
        }
    }

    private func save() {
        guard let amount = parsedAmount, let category = selectedCategory else { return }
        let trimmedName = advancePaidForName.trimmingCharacters(in: .whitespaces)
        let trimmedNote = note.trimmingCharacters(in: .whitespaces)

        if let expense = expenseToEdit {
            expense.amount = amount
            expense.category = category
            expense.paymentMethod = selectedPaymentMethod
            expense.date = date
            expense.isPaid = isPaid
            expense.isAdvancePayment = isAdvancePayment
            expense.advancePaidForName = isAdvancePayment ? trimmedName : nil
            expense.note = trimmedNote.isEmpty ? nil : trimmedNote
            // Editing away from an advance clears any prior repaid state.
            if !isAdvancePayment {
                expense.isRepaid = false
                expense.repaidDate = nil
            }
        } else {
            let expense = Expense(
                amount: amount,
                date: date,
                category: category,
                paymentMethod: selectedPaymentMethod,
                isPaid: isPaid,
                note: trimmedNote.isEmpty ? nil : trimmedNote,
                isAdvancePayment: isAdvancePayment,
                advancePaidForName: isAdvancePayment ? trimmedName : nil
            )
            modelContext.insert(expense)
        }

        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}
