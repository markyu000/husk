//
//  Card.swift
//  Husk
//
//  Created by 余哲源 on 2026/8/23.
//

import Foundation

protocol Card: AnyObject, Identifiable {
    var id: UUID { get }
    var cardType: CardType { get }
    var unitID: UUID { get set }
    var createdAt: Date { get }
    var source: CardSource { get set }

    var fsrs: FSRSState { get set }

    // 这张卡是否已经完全学完，进入长期复习轮转
    var isFullyLearned: Bool { get }

    func reviewPrompt() -> ReviewPrompt

    // 随手记相关字段，仅 source == .quickCapture 时有意义
    var sourceContext: String? { get set }
    var sourceDocumentTitle: String? { get set }
    var sourceDocumentId: String? { get set }
    var capturedAt: Date? { get set }
    var addedToQueue: Bool { get set }

    // 这张卡片当前正在被哪个队列/槽位体系追踪
    // nil: 已完全学完，进入长期复习轮转
    // .review: 在复习队列里排队等到期
    // .newCards / .fullRelearn: 在学习引擎的 Step 槽位传送带里
    var originQueue: QueueKind? { get set }

    func postFSRSUpdateHook(context: ReviewSession?)

    func fullDetailContent() -> DetailContent
}

extension Card {
    func postFSRSUpdateHook(context: ReviewSession?) {}

    var isInInbox: Bool {
        source == .quickCapture && !addedToQueue
    }

    var isFullyLearned: Bool {
        originQueue == nil
    }
}

enum QueueKind: Int, Codable {
    case newCards = 0
    case relearn = 1
    case review = 2
    case fullRelearn = 3
}

enum CardType: Int, Codable, CaseIterable {
    case word = 0
    case phrase = 1
}

enum CardSource: Int, Codable {
    case wordbook = 0
    case manual = 1
    case quickCapture = 2
}
