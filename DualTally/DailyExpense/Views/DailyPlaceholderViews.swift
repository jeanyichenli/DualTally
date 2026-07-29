//
//  DailyPlaceholderViews.swift
//  DualTally
//
//  Navigation placeholder for the reports screen implemented in roadmap step 7.
//  It exists so the list view's entry point is wired now, and is replaced when
//  that step lands.
//

import SwiftUI

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
