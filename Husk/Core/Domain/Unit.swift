//
//  Unit.swift
//  Husk
//
//  Created by 余哲源 on 2026/9/6.
//

import SwiftData
import Foundation

@Model
final class Unit {
    @Attribute(.unique) var id: UUID
    var cardType: CardType
    var name: String
    var icon: String?
    var accentColor: String?
    var createdAt: Date
    
    var learningSlots: LearningSlotChain
    var reviewQueue: [any Card] = []
    
    let desiredRetention: Double
    
    var dailyLearningGoal: Int?
    
    @Transient lazy var learningEngine: LearningEngine = LearningEngine(unit: self)
    @Transient lazy var reviewEngine: ReviewEngine = ReviewEngine(unit: self)
    
    init(cardType: CardType, name: String, desiredRetention: Double = 0.90) {
        self.id = UUID()
        self.cardType = cardType
        self.name = name
        self.createdAt = .now
        self.learningSlots = learningSlotsChain(cardType: cardType)
        self.desiredRetention = desiredRetention
    }
    
    func resolvedLearningGoal(settings: AppSettings) -> Int {
        dailyLearningGoal ?? settings.defaultDailyLearningGoal
    }
    
    var reviewCount: Int { reviewQueue.count }
    var learningCount: Int { learningSlots.totalCardCount }
    
    func removeFromReview(_ card: any Card) {
        reviewQueue.removeAll { $0.id == card.id }
        card.originQueue = nil
    }
    
    func requeueToReview(_ card: any Card) {
        removeFromReview(card)
        reviewQueue.append(card)
        card.originQueue = .review
    }
    
    var masteredStabilityThreshold: Double {
        365.0 * FSRSEngine.factor / (pow(desiredRetention, 1.0 / FSRSEngine.decay) - 1)
    }
}
