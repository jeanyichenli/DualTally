//
//  DailyPlaceholderViews.swift
//  DualTally
//
//  Navigation placeholders for daily-expense screens implemented in later
//  roadmap steps (5 advance management, 6 monthly review, 7 reports). They exist
//  so the list view's entry points are wired now; each is replaced when its step
//  lands.
//

import SwiftUI

struct AdvancePaymentView: View {
    var body: some View {
        ContentUnavailableView(
            "墊付管理",
            systemImage: "hand.raised.fill",
            description: Text("列出墊付紀錄與尚未收回總額（roadmap 步驟 5）")
        )
        .navigationTitle("墊付")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MonthlyReviewView: View {
    var body: some View {
        ContentUnavailableView(
            "月度復盤",
            systemImage: "checklist",
            description: Text("逐筆勾選衝動購物並統計佔比（roadmap 步驟 6）")
        )
        .navigationTitle("復盤")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ReportView: View {
    var body: some View {
        ContentUnavailableView(
            "報表",
            systemImage: "chart.bar.fill",
            description: Text("週/月/年 × 總支出/分類佔比/依分類（roadmap 步驟 7）")
        )
        .navigationTitle("報表")
        .navigationBarTitleDisplayMode(.inline)
    }
}
