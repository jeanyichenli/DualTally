//
//  Item.swift
//  DualTally
//
//  Created by Jean on 2026/7/21.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
