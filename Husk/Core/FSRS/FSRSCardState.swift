//
//  FSRSCardState.swift
//  Husk
//
//  Created by 余哲源 on 2026/8/24.
//

enum FSRSCardState: Int, Codable {
    case new = 0
    case learning = 1
    case review = 2
    case relearning = 3
}
