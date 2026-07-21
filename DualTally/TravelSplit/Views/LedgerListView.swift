//
//  LedgerListView.swift
//  DualTally
//
//  Created by Jean on 2026/7/21.
//

import SwiftUI

struct LedgerListView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "尚無帳本",
                systemImage: "folder",
                description: Text("建立第一本旅遊帳本後會顯示在這裡")
            )
            .navigationTitle("旅遊記帳")
        }
    }
}

#Preview {
    LedgerListView()
}
