//
//  DailyExpenseListView.swift
//  DualTally
//
//  Created by Jean on 2026/7/21.
//

import SwiftUI

struct DailyExpenseListView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "尚無支出紀錄",
                systemImage: "tray",
                description: Text("新增第一筆支出後會顯示在這裡")
            )
            .navigationTitle("日常記帳")
        }
    }
}

#Preview {
    DailyExpenseListView()
}
