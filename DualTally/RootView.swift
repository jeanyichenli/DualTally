//
//  RootView.swift
//  DualTally
//
//  Created by Jean on 2026/7/21.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            DailyExpenseListView()
                .tabItem {
                    Label("日常記帳", systemImage: "creditcard")
                }

            LedgerListView()
                .tabItem {
                    Label("旅遊記帳", systemImage: "airplane")
                }
        }
    }
}

#Preview {
    RootView()
}
