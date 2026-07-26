//
//  CategoryManagementView.swift
//  DualTally
//
//  Lets the user manage daily-expense categories: the built-in defaults ship
//  pre-seeded, and the user can add their own or delete any they don't use.
//  Deleting a category nullifies its historical expenses (they become 未分類)
//  rather than deleting them.
//

import SwiftUI
import SwiftData

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    @State private var showingAddCategory = false

    var body: some View {
        List {
            Section {
                ForEach(categories) { category in
                    Label(category.name, systemImage: category.symbolName)
                }
                .onDelete(perform: deleteCategories)
            } footer: {
                Text("刪除分類不會刪除既有支出，那些支出會變成未分類。")
            }
        }
        .navigationTitle("分類管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddCategory = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("新增分類")
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView()
        }
    }

    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(categories[index])
        }
    }
}

/// Sheet for creating a new user category: a name plus an SF Symbol picked from
/// a curated grid.
private struct AddCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var categories: [ExpenseCategory]

    @State private var name: String = ""
    @State private var symbolName: String = ExpenseCategory.symbolChoices.first ?? "tag.fill"

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    private var isValid: Bool {
        !trimmedName.isEmpty
            && !categories.contains { $0.name == trimmedName }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("名稱") {
                    TextField("分類名稱", text: $name)
                }

                Section("圖示") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(ExpenseCategory.symbolChoices, id: \.self) { symbol in
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
            .navigationTitle("新增分類")
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
        modelContext.insert(
            ExpenseCategory(
                name: trimmedName,
                symbolName: symbolName,
                isBuiltIn: false,
                sortOrder: ExpenseCategory.nextSortOrder(after: categories)
            )
        )
        dismiss()
    }
}
