//
//  CategoryManagementView.swift
//  DualTally
//
//  Lets the user manage daily-expense categories: the built-in defaults ship
//  pre-seeded, and the user can add their own, edit any category's name or
//  icon, or delete any they don't use. Deleting a category nullifies its
//  historical expenses (they become 未分類) rather than deleting them.
//

import SwiftUI
import SwiftData
import UIKit

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    @State private var showingAddCategory = false
    @State private var editingCategory: ExpenseCategory?

    var body: some View {
        List {
            Section {
                ForEach(categories) { category in
                    Button {
                        editingCategory = category
                    } label: {
                        Label(category.name, systemImage: category.symbolName)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteCategories)
            } footer: {
                Text("點一下可編輯名稱與圖示。刪除分類不會刪除既有支出，那些支出會變成未分類。")
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
            CategoryEditorView(category: nil)
        }
        .sheet(item: $editingCategory) { category in
            CategoryEditorView(category: category)
        }
    }

    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(categories[index])
        }
    }
}

/// Sheet for creating or editing a category: a name plus an SF Symbol picked
/// from a curated grid, or typed in directly. `category == nil` creates a new
/// one; otherwise the existing category's fields are edited in place.
private struct CategoryEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var categories: [ExpenseCategory]

    let category: ExpenseCategory?

    @State private var name: String
    @State private var symbolName: String
    @State private var customSymbolInput: String = ""

    init(category: ExpenseCategory?) {
        self.category = category
        _name = State(initialValue: category?.name ?? "")
        _symbolName = State(initialValue: category?.symbolName ?? ExpenseCategory.symbolChoices.first ?? "tag.fill")
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    private var trimmedCustomSymbol: String {
        customSymbolInput.trimmingCharacters(in: .whitespaces)
    }

    /// Whether the typed name resolves to a real SF Symbol. `UIImage(systemName:)`
    /// returns nil for anything that isn't a valid symbol, so this doubles as
    /// both validation and a live preview check.
    private var isCustomSymbolValid: Bool {
        !trimmedCustomSymbol.isEmpty && UIImage(systemName: trimmedCustomSymbol) != nil
    }

    private var isValid: Bool {
        !trimmedName.isEmpty
            && !categories.contains { $0.name == trimmedName && $0.id != category?.id }
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

                Section {
                    HStack {
                        TextField("輸入 SF Symbol 名稱", text: $customSymbolInput)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        if isCustomSymbolValid {
                            Image(systemName: trimmedCustomSymbol)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Button("使用此圖示") {
                        symbolName = trimmedCustomSymbol
                    }
                    .disabled(!isCustomSymbolValid)
                } header: {
                    Text("自訂圖示")
                } footer: {
                    Text("找不到想要的圖示？輸入任何 SF Symbol 名稱，例如「moon.stars.fill」。")
                }
            }
            .navigationTitle(category == nil ? "新增分類" : "編輯分類")
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
        if let category {
            category.name = trimmedName
            category.symbolName = symbolName
        } else {
            modelContext.insert(
                ExpenseCategory(
                    name: trimmedName,
                    symbolName: symbolName,
                    isBuiltIn: false,
                    sortOrder: ExpenseCategory.nextSortOrder(after: categories)
                )
            )
        }
        dismiss()
    }
}
