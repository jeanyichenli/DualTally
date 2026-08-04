//
//  PaymentMethodManagementView.swift
//  DualTally
//
//  Manage payment methods (現金 / 信用卡 …): built-in defaults ship pre-seeded,
//  and the user can add their own, edit any, or delete any. Deleting
//  nullifies the method on historical expenses rather than deleting them.
//  Parallels CategoryManagementView — see PaymentMethod for why the two
//  aren't unified.
//

import SwiftUI
import SwiftData

struct PaymentMethodManagementView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \PaymentMethod.sortOrder) private var paymentMethods: [PaymentMethod]

    @State private var showingAddPaymentMethod = false
    @State private var editingPaymentMethod: PaymentMethod?

    var body: some View {
        List {
            Section {
                ForEach(paymentMethods) { method in
                    Button {
                        editingPaymentMethod = method
                    } label: {
                        Label(method.name, systemImage: method.symbolName)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deletePaymentMethods)
            } footer: {
                Text("點一下可編輯名稱與圖示。刪除支付方式不會刪除既有支出，那些支出會變成未指定支付方式。")
            }
        }
        .navigationTitle("支付方式")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddPaymentMethod = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("新增支付方式")
            }
        }
        .sheet(isPresented: $showingAddPaymentMethod) {
            PaymentMethodEditorView(paymentMethod: nil)
        }
        .sheet(item: $editingPaymentMethod) { method in
            PaymentMethodEditorView(paymentMethod: method)
        }
    }

    private func deletePaymentMethods(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(paymentMethods[index])
        }
    }
}

/// Sheet for creating or editing a payment method: a name plus an SF Symbol
/// picked from a curated grid. `paymentMethod == nil` creates a new one;
/// otherwise the existing method's fields are edited in place.
private struct PaymentMethodEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var paymentMethods: [PaymentMethod]

    let paymentMethod: PaymentMethod?

    @State private var name: String
    @State private var symbolName: String

    init(paymentMethod: PaymentMethod?) {
        self.paymentMethod = paymentMethod
        _name = State(initialValue: paymentMethod?.name ?? "")
        _symbolName = State(initialValue: paymentMethod?.symbolName ?? PaymentMethod.symbolChoices.first ?? "creditcard")
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    private var isValid: Bool {
        !trimmedName.isEmpty
            && !paymentMethods.contains { $0.name == trimmedName && $0.id != paymentMethod?.id }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("名稱") {
                    TextField("支付方式名稱", text: $name)
                }

                Section("圖示") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(PaymentMethod.symbolChoices, id: \.self) { symbol in
                            Button {
                                symbolName = symbol
                            } label: {
                                Image(systemName: symbol)
                                    .font(.title3)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle().fill(symbol == symbolName
                                            ? Color.accentColor.opacity(0.2)
                                            : Color.clear)
                                    )
                                    .foregroundStyle(symbol == symbolName ? Color.accentColor : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(paymentMethod == nil ? "新增支付方式" : "編輯支付方式")
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
        }
    }

    private func save() {
        guard isValid else { return }
        if let paymentMethod {
            paymentMethod.name = trimmedName
            paymentMethod.symbolName = symbolName
        } else {
            modelContext.insert(
                PaymentMethod(
                    name: trimmedName,
                    symbolName: symbolName,
                    isBuiltIn: false,
                    sortOrder: PaymentMethod.nextSortOrder(after: paymentMethods)
                )
            )
        }
        dismiss()
    }
}
