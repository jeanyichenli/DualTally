//
//  DualTallyApp.swift
//  DualTally
//
//  Created by Jean on 2026/7/21.
//

import SwiftUI
import SwiftData

@main
struct DualTallyApp: App {
    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            MonthlyBudget.self,
            ExpenseCategory.self,
            PaymentMethod.self,
            Expense.self,
        ])
        // Store lives in the App Group container so the widget extension reads
        // the same database.
        let configuration = ModelConfiguration(
            schema: schema,
            url: AppGroupConstants.storeURL
        )
        do {
            modelContainer = try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        ExpenseCategory.seedDefaultsIfNeeded(in: modelContainer.mainContext)
        PaymentMethod.seedDefaultsIfNeeded(in: modelContainer.mainContext)
        // Publish the initial balance so the widget has data before the first edit.
        DailyBalanceSnapshot.refresh(using: modelContainer.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}
