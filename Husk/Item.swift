//
//  Item.swift
//  Husk
//
//  Created by 余哲源 on 2026/5/19.
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
