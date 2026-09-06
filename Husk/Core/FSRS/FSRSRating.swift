//
//  FSRSRating.swift
//  Husk
//
//  Created by 余哲源 on 2026/8/27.
//

enum FSRSRating: Int, Codable {
    case again = 1
    case hard = 2
    case good = 3
    case easy = 4
}

extension FSRSRating: FSRSRatingConvertible {
    var fsrsRating: FSRSRating { self }
}
