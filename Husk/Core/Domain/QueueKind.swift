//
//  QueueKind.swift
//  Husk
//
//  Created by 余哲源 on 2026/8/24.
//

enum QueueKind: Int, Codable {
    case newCards = 0
    case relearn = 1
    case review = 2
    case fullRelearn = 3
}
