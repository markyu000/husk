//
//  FSRSState.swift
//  Husk
//
//  Created by 余哲源 on 2026/8/24.
//

import Foundation

struct FSRSState: Codable {
    var stability: Double = 0 // 记忆强度，越大越不容易遗忘
    var difficulty: Double = 0 // 卡片难度，越大越难记
    var elapsedDays: Int = 0 // 距上次复习实际过去的天数
    var scheduledDays: Int = 0 // 本次排定的复习间隔天数
    var reps: Int = 0 // 累计复习次数
    var lapses: Int = 0 // 累计遗忘（again）次数
    var dueDate: Date? // 下次到期复习日期
    var lastReview: Date? // 上次复习时间
    var state: FSRSCardState = .new // 当前所处的记忆阶段
    var dueDateOverridden: Bool = false // 特殊规则触发的调度覆盖标记（如单词型"想到了"次日强制复习）
}
