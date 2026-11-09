//
//  FSRSEngine.swift
//  Husk
//
//  Created by 余哲源 on 2026/8/27.
//
import Foundation

struct FSRSEngine {
    static let defaultParams = FSRSParameters()

    static let decay = -0.5
    static let stabilityAnchorRetention = 0.9
    static let factor = pow(stabilityAnchorRetention, 1.0 / decay) - 1
    private static let sMin = 0.01

    static func initialize(
        _ state: inout FSRSState,
        rating: FSRSRating,
        desiredRetention: Double
    ) {
        state.stability = initStability(rating: rating)
        state.difficulty = initDifficulty(rating: rating)
        state.reps = 1
        state.lapses = 0
        state.lastReview = .now
        state.state = .review
        state.scheduledDays = nextInterval(
            stability: state.stability,
            desiredRetention: desiredRetention
        )
        state.dueDate = Calendar.current.date(
            byAdding: .day,
            value: state.scheduledDays,
            to: .now
        )
    }

    static func update(
        _ state: inout FSRSState,
        rating: FSRSRating,
        desiredRetention: Double
    ) {
        let now = Date()
        let elapsed = elapsedDays(from: state.lastReview, to: now)
        let retrievability = forgetRate(
            elapsed: elapsed,
            stability: state.stability
        )

        state.elapsedDays = elapsed
        state.difficulty = nextDifficulty(difficulty: state.difficulty, rating: rating)

        if rating == .again {
            state.stability = forgetStability(
                difficulty: state.difficulty,
                stability: state.stability,
                retrievability: retrievability
            )
            state.lapses += 1
            state.state = .relearning
        } else {
            state.stability = recallStability(
                difficulty: state.difficulty,
                stability: state.stability,
                retrievability: retrievability,
                rating: rating
            )
            state.state = .review
        }

        state.reps += 1
        state.lastReview = now
        state.scheduledDays = nextInterval(
            stability: state.stability,
            desiredRetention: desiredRetention
        )
        state.dueDate = Calendar.current.date(
            byAdding: .day,
            value: state.scheduledDays,
            to: now
        )
        state.dueDateOverridden = false
    }

    private static func constrainDifficulty(_ difficulty: Double) -> Double {
        min(max(difficulty, 1.0), 10.0)
    }

    private static func initStability(rating: FSRSRating) -> Double {
        max(defaultParams.weights[rating.rawValue - 1], 0.1)
    }

    private static func initDifficulty(rating: FSRSRating) -> Double {
        let w = defaultParams.weights
        let raw = w[4] - exp((Double(rating.rawValue) - 1) * w[5]) + 1
        return constrainDifficulty(raw)
    }

    private static func nextInterval(
        stability: Double,
        desiredRetention: Double
    ) -> Int {
        let clampedRetention = min(0.99, max(0.70, desiredRetention))
        let interval =
            stability * (pow(clampedRetention, 1.0 / decay) - 1) / factor
        return max(1, min(defaultParams.maximumInterval, Int(round(interval))))
    }

    private static func linearDamping(
        deltaDifficulty: Double,
        oldDifficulty: Double
    ) -> Double {
        deltaDifficulty * (10 - oldDifficulty) / 9
    }

    private static func meanReversion(
        initValue:
            Double,
        current: Double
    ) -> Double {
        let w7 = defaultParams.weights[7]
        return w7 * initValue + (1 - w7) * current
    }

    private static func clamp(_ value: Double, _ lower: Double, _ upper: Double)
        -> Double
    {
        min(max(value, lower), upper)
    }

    private static func nextDifficulty(
        difficulty: Double,
        rating: FSRSRating
    ) -> Double {
        let w = defaultParams.weights
        let deltaDifficulty = -(w[6] * (Double(rating.rawValue) - 3))
        let next =
            difficulty
            + linearDamping(
                deltaDifficulty: deltaDifficulty,
                oldDifficulty: difficulty
            )
        let initEasy = initDifficulty(rating: .easy)
        // v5：向 clamped 的 Easy-init 收敛
        return
            constrainDifficulty(
                meanReversion(
                    initValue:
                        initEasy,
                    current: next
                )
            )
    }

    private static func recallStability(
        difficulty: Double,
        stability: Double,
        retrievability: Double,
        rating: FSRSRating
    ) -> Double {
        let w = defaultParams.weights
        let hardPenalty = rating == .hard ? w[15] : 1
        let easyBound = rating == .easy ? w[16] : 1
        return clamp(
            stability
                * (1 + exp(w[8]) * (11 - difficulty) * pow(stability, -(w[9]))
                    * (exp((1 - retrievability) * w[10]) - 1) * hardPenalty
                    * easyBound),
            sMin,
            Double(defaultParams.maximumInterval)
        )
    }

    private static func forgetStability(
        difficulty: Double,
        stability: Double,
        retrievability: Double
    ) -> Double {
        let w = defaultParams.weights
        let p1 = pow(difficulty, -(w[12]))
        let p2 = pow(stability + 1, w[13]) - 1
        let p3 = exp((1 - retrievability) * w[14])
        return clamp(
            w[11] * p1 * p2 * p3,
            sMin,
            Double(defaultParams.maximumInterval)
        )
    }
    
    private static func forgetRate(elapsed: Int, stability: Double) -> Double {
        guard stability > 0 else { return elapsed == 0 ? 1 : 0 }
        return pow(1 + factor * Double(elapsed) / stability, decay)
    }

    /// 距上次复习经过的完整日历天数（本地时区、从 0 点起算）。
    /// 没有上次复习记录时返回 0；时钟回拨时不会得到负数。
    private static func elapsedDays(from lastReview: Date?, to now: Date) -> Int {
        guard let lastReview else { return 0 }
        let calendar = Calendar.current
        let fromDay = calendar.startOfDay(for: lastReview)
        let toDay = calendar.startOfDay(for: now)
        let days = calendar.dateComponents([.day], from: fromDay, to: toDay).day ?? 0
        return max(0, days)
    }
}
