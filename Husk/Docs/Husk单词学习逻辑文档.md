# Husk 单词背诵逻辑设计文档

> 代号：Husk（Tine 的姊妹 App）
> 文档版本：v0.1
> 日期：2026-05-23

## 目录

1. [设计哲学](#一设计哲学)
2. [核心概念](#二核心概念)
3. [主界面](#三主界面)
4. [学习流程](#四学习流程)
5. [复习流程](#五复习流程)
6. [队列管理](#六队列管理)
7. [FSRS 算法集成](#七fsrs-算法集成)
8. [数据结构](#八数据结构)
9. [页面模拟图汇总](#九页面模拟图汇总)

---

## 一、设计哲学

**学习与复习分离。** 学习时充分（多阶段、多维度），复习时高效（自测 + 拼写验证）。

**错误推迟而非循环。** 学习过程中答错某一步，整个词排到学习队列末尾过一会儿重来，而不是当场反复重做。这天然形成"间隔效应"。

**主观自测 + 客观测试。** 自测告诉算法用户的信心，测试验证用户的真实掌握度。

**FSRS 只在复习时介入。** 学习过程的对错不喂给 FSRS，只有复习结果影响调度。

---

## 二、核心概念

### 2.1 三大阶段

每个新词的学习包含三个阶段，按顺序进行：

| 阶段 | 内容 | 测试形式 |
|------|------|---------|
| **释义阶段** | 单词的中文/英文含义 | 选择题 |
| **听音阶段** | 单词的发音 | 选择题 + 自测 |
| **拼写阶段** | 单词的字母组成 | 键盘输入 + 选择 |

### 2.2 四档自测

学前自测和复习自测都用四档：

| 档位 | 含义 | 映射 FSRS Rating |
|------|------|-----------------|
| 认识 | 完全掌握 | Easy |
| 模糊 | 有印象但不确定 | Good |
| 想想 | 努力可以回忆起 | Hard |
| 不认识 | 完全没印象 | Again |

### 2.3 卡片生命周期

```
未学习 → 学习中 → 复习池中 → (到期) → 复习中
                       ↑                    │
                       │       通过 ────────┘
                       │
                    待重学 ←── 失败
                       │
                       └→ 学习中（重学）
```

---

## 三、主界面

### 3.1 布局

```
┌─────────────────────────────┐
│         Husk                │
│                             │
│      今天                    │
│                             │
│   ┌─────────────────────┐   │
│   │  📖 复习             │   │
│   │  待复习: 8 个         │   │
│   └─────────────────────┘   │
│                             │
│   ┌─────────────────────┐   │
│   │  ✏️ 学习             │   │
│   │  新词: 5 + 待重学: 2  │   │
│   └─────────────────────┘   │
│                             │
│   ─────────────────         │
│                             │
│   今日已学: 12 个            │
│   今日已复习: 15 个           │
│   连续打卡: 7 天             │
│                             │
└─────────────────────────────┘
```

### 3.2 按钮逻辑

- **复习按钮**：进入复习流程，逐个过到期的词。
- **学习按钮**：进入学习流程，先学新词，再重学复习失败的词。

复习池为空时复习按钮置灰。学习池和待重学都为空时学习按钮置灰。

---

## 四、学习流程

### 4.1 总览

```
进入学习
  ↓
取队列首词
  ↓
学前自测（Step 0）
  ↓
  ├─ 认识 → 含义/拼写检查页 → FSRS 初始化（Easy）
  ├─ 模糊 ┐
  ├─ 想想 ├─→ 完整学习流程 → FSRS 初始化
  └─ 不认识 ┘
  ↓
任何步骤答错
  → 整个词排到队列末尾，记录当前阶段
  → 下次从该阶段第一步开始
  ↓
全部步骤通过
  → 进入 FSRS 调度
  → 取下一个词
```

### 4.2 Step 0：学前自测

#### 显示

```
┌─────────────────────────────┐
│   abandon                   │
│   🔊 /əˈbændən/             │
│                             │
│   你认识这个单词吗？           │
│                             │
│   [ 认识 ]                   │
│   [ 模糊 ]                   │
│   [ 想想 ]                   │
│   [ 不认识 ]                 │
│                             │
└─────────────────────────────┘
```

#### 逻辑

- 选**认识** → 跳转到 4.3 含义/拼写检查页
- 选**模糊/想想/不认识** → 走完整学习流程（4.4 释义阶段）

### 4.3 "认识"后的检查页

#### 显示

```
┌─────────────────────────────┐
│  abandon  🔊 /əˈbændən/      │
│                             │
│  请确认你都掌握了：           │
│  （勾选不会的，点击重点学习）  │
│                             │
│  📖 中文含义                 │
│  ☐ v. 放弃；遗弃            │
│  ☐ v. 抛弃（家人朋友）       │
│  ☐ n. 放纵；无拘束          │
│                             │
│  🇬🇧 英文释义                │
│  ☐ to leave completely     │
│     and not return         │
│  ☐ to give up...           │
│                             │
│  ✏️ 拼写                    │
│  ☐ a-b-a-n-d-o-n           │
│                             │
│  ─────────────────         │
│                             │
│  [ 全部掌握 ✓ ]              │
│  （勾选任意项后变为"重点学习"）│
│                             │
└─────────────────────────────┘
```

#### 逻辑

- 不勾选任何项，点"全部掌握" → 进入 FSRS 调度（初始 stability = w[3] ≈ 15.69 天）
- 勾选某些项，点"重点学习"：
  - 勾了任意**含义** → 走释义阶段（Step 1-3）
  - 勾了**拼写** → 走拼写阶段（Step 7）
  - 同时勾两类 → 按顺序走（释义阶段 → 拼写阶段）
- 重点学习中如果错了，依然按"错则排到队列末尾"的规则处理

### 4.4 释义阶段（Step 1-3）

#### Step 1：英→中

```
┌─────────────────────────────┐
│  abandon  🔊 /əˈbændən/      │
│                             │
│  选择正确的中文释义：          │
│                             │
│  [ A. 接受 ]                 │
│  [ B. 放弃；遗弃 ]            │
│  [ C. 携带 ]                 │
│  [ D. 继续 ]                 │
│                             │
└─────────────────────────────┘
```

- 选对 → Step 2
- 选错 → 显示正确答案 2 秒 → **词排到队列末尾，下次从释义阶段重来**

#### Step 2：中→英

```
┌─────────────────────────────┐
│  放弃；遗弃                  │
│                             │
│  选择对应的英文单词：          │
│                             │
│  [ A. abundant ]            │
│  [ B. abound ]              │
│  [ C. abandon ]             │
│  [ D. abash ]               │
│                             │
└─────────────────────────────┘
```

- 选对 → Step 3
- 选错 → 显示正确答案 → **词排到队列末尾，下次从释义阶段重来**

#### Step 3：英英→中

```
┌─────────────────────────────┐
│  to leave completely and    │
│  not return                 │
│                             │
│  选择对应的中文释义：          │
│                             │
│  [ A. 拥抱 ]                 │
│  [ B. 放弃；遗弃 ]            │
│  [ C. 围绕 ]                 │
│  [ D. 探索 ]                 │
│                             │
└─────────────────────────────┘
```

- 选对 → 进入听音阶段（Step 4）
- 选错 → **词排到队列末尾，下次从释义阶段重来**

### 4.5 听音阶段（Step 4-6）

#### Step 4：听音→选词

```
┌─────────────────────────────┐
│                             │
│       🔊（点击播放）         │
│                             │
│  这个发音对应哪个单词？        │
│                             │
│  [ A. abandon ]             │
│  [ B. abundant ]            │
│  [ C. abound ]              │
│  [ D. abash ]               │
│                             │
└─────────────────────────────┘
```

- 选对 → Step 5
- 选错 → **词排到队列末尾，下次从听音阶段重来**

#### Step 5：听音→选义

```
┌─────────────────────────────┐
│                             │
│       🔊                    │
│                             │
│  这个单词的意思是？            │
│                             │
│  [ A. 接受 ]                 │
│  [ B. 放弃；遗弃 ]            │
│  [ C. 携带 ]                 │
│  [ D. 继续 ]                 │
│                             │
└─────────────────────────────┘
```

- 选对 → Step 6
- 选错 → **词排到队列末尾，下次从听音阶段重来**

#### Step 6：听音自测

```
┌─────────────────────────────┐
│                             │
│       🔊                    │
│                             │
│  你能听音辨词吗？             │
│                             │
│   [ 认识 ]                   │
│   [ 模糊 ]                   │
│   [ 想想 ]                   │
│   [ 不认识 ]                 │
│                             │
└─────────────────────────────┘
```

- 选**认识/模糊** → 进入拼写阶段
- 选**想想/不认识** → **词排到队列末尾，下次从听音阶段重来**

### 4.6 拼写阶段（Step 7）

#### Step 7：听音拼写

```
┌─────────────────────────────┐
│                             │
│       🔊                    │
│                             │
│   _ _ _ _ _ _ _             │
│                             │
│  ┌────────────────────┐     │
│  │ q w e r t y u i o p│     │
│  │  a s d f g h j k l │     │
│  │   z x c v b n m    │     │
│  │       [delete]     │     │
│  └────────────────────┘     │
│                             │
└─────────────────────────────┘
```

- 输入完成（达到字母数）→ 自动提交
- 全对 → 单词学习完成，进入 FSRS 调度
- 错 → 进入 Step 7a

#### Step 7a：听音 + 选拼写

```
┌─────────────────────────────┐
│                             │
│       🔊                    │
│                             │
│  选择正确的拼写：             │
│                             │
│  [ A. abandone ]            │
│  [ B. abandon ]             │
│  [ C. abbandon ]            │
│  [ D. abandun ]             │
│                             │
└─────────────────────────────┘
```

- 选对 → 进入 Step 7b
- 选错 → **词排到队列末尾，下次从拼写阶段重来**

#### Step 7b：全提示拼写

```
┌─────────────────────────────┐
│                             │
│  v. 放弃；遗弃                │
│  to leave completely and    │
│  not return                 │
│  🔊                         │
│                             │
│   _ _ _ _ _ _ _             │
│                             │
│  [键盘]                     │
│                             │
└─────────────────────────────┘
```

- 拼对 → 单词学习完成，进入 FSRS 调度
- 拼错 → **词排到队列末尾，下次从拼写阶段重来**

### 4.7 学习完成

```
┌─────────────────────────────┐
│                             │
│        ✓                    │
│                             │
│    abandon                  │
│    已掌握                    │
│                             │
│  下次复习：4 天后             │
│                             │
└─────────────────────────────┘
```

短暂展示后自动进入下一个词。

---

## 五、复习流程

### 5.1 总览

```
进入复习
  ↓
取复习队列首词
  ↓
复习自测：只显示 🔊 + 音标
  ↓
  ├─ 认识 → 拼写测试
  │           ├─ 对 → FSRS 更新（Good/Easy）→ 下一个
  │           └─ 错 → 重走 Step 7 → 加入待重学队列
  │
  ├─ 模糊  ┐
  ├─ 想想  ├─→ 加入待重学队列 → 下一个
  └─ 不认识 ┘
  ↓
所有词过完
  ↓
返回主界面（待重学队列里多了几个词）
```

### 5.2 复习自测

```
┌─────────────────────────────┐
│                             │
│       🔊 /əˈbændən/          │
│                             │
│  你认识这个单词吗？           │
│                             │
│   [ 认识 ]                   │
│   [ 模糊 ]                   │
│   [ 想想 ]                   │
│   [ 不认识 ]                 │
│                             │
└─────────────────────────────┘
```

注意：**不显示单词本身**，只显示发音和音标。

### 5.3 复习拼写测试

仅当自测选"认识"时进入：

```
┌─────────────────────────────┐
│                             │
│       🔊 /əˈbændən/          │
│                             │
│   _ _ _ _ _ _ _             │
│                             │
│  [键盘]                     │
│                             │
└─────────────────────────────┘
```

- 拼对 → FSRS 更新为 Easy → 进入下一个词
- 拼错 → 进入 5.4 拼写补救

### 5.4 拼写补救

进入学习流程的 Step 7a → Step 7b。

- 补救通过 → FSRS 更新为 Hard → 进入下一个词
- 补救仍失败 → 加入待重学队列 → FSRS 更新为 Again → 进入下一个词

### 5.5 复习完成

```
┌─────────────────────────────┐
│                             │
│        ✓                    │
│                             │
│   今日复习完成                │
│                             │
│   通过：6 个                 │
│   待重学：2 个                │
│                             │
│   [ 返回首页 ]                │
│   [ 立即学习 ]                │
│                             │
└─────────────────────────────┘
```

---

## 六、队列管理

### 6.1 三个队列

| 队列 | 内容 | 来源 |
|------|------|------|
| 新词队列 | 今日要学的新词 | 用户添加 / 词书导入 |
| 复习队列 | 今日 FSRS 到期的词 | FSRS 调度 |
| 待重学队列 | 复习失败的词 | 复习流程 |

### 6.2 复习按钮行为

```
点击复习
  ↓
执行复习队列（FIFO）
  ↓
失败的词加入待重学队列
  ↓
通过的词更新 FSRS
  ↓
复习队列清空，结束
```

### 6.3 学习按钮行为

```
点击学习
  ↓
合并队列：新词队列 + 待重学队列（新词在前）
  ↓
执行 FIFO：
  - 取队首
  - 学习
  - 学完 → 进入 FSRS
  - 答错 → 排到队尾，记录当前阶段
  ↓
队列清空，结束
```

### 6.4 学习中失败的处理细节

```swift
// 伪代码
func onStepFailed(card: WordCard, currentStage: LearningStage) {
    // 1. 记录该词的当前阶段（下次从这里开始）
    card.currentLearningStage = currentStage
    
    // 2. 排到队列末尾
    learningQueue.removeFirst()  // 移除队首
    learningQueue.append(card)   // 加到末尾
    
    // 3. 进入下一个词
    showCard(learningQueue.first)
}
```

### 6.5 跨天处理

- 昨天的**待重学队列**保留到今天
- 昨天的**新词队列**未学完的保留到今天
- 今日新到期的 FSRS 词进入今日复习队列

---

## 七、FSRS 算法集成

### 7.1 算法选择

使用 **FSRS-5**（Free Spaced Repetition Scheduler v5），社区目前公认最优的开源 SRS 算法。

### 7.2 默认参数

```swift
// FSRS-5 论文默认 19 个权重
let defaultWeights: [Double] = [
    0.40255, 1.18385, 3.173, 15.69105,   // w[0-3]: 4 档评分初始 stability
    7.1949, 0.5345, 1.4604, 0.0046,
    1.54575, 0.1192, 1.01925, 1.9395,
    0.11, 0.29605, 2.2698, 0.2315,
    2.9898, 0.51655, 0.6621
]

let requestRetention: Double = 0.9    // 目标记忆保留率 90%
let maximumInterval: Int = 36500       // 最大间隔 100 年
```

### 7.3 自测到 Rating 的映射

```swift
SelfAssessment.认识   → Rating.easy   → 初始 stability ≈ 15.69 天
SelfAssessment.模糊   → Rating.good   → 初始 stability ≈ 3.17 天
SelfAssessment.想想   → Rating.hard   → 初始 stability ≈ 1.18 天
SelfAssessment.不认识 → Rating.again  → 初始 stability ≈ 0.40 天
```

### 7.4 FSRS 介入时机

| 时机 | 操作 |
|------|------|
| 新词学完 | 初始化 FSRS 状态，用学前自测的 Rating |
| 复习通过（自测认识 + 拼写对） | FSRS.schedule(rating: .easy) |
| 复习拼写错但补救对 | FSRS.schedule(rating: .hard) |
| 复习失败（自测非认识，或补救仍错） | FSRS.schedule(rating: .again) |
| 学习中答错 | **不更新 FSRS**（FSRS 不知道这事） |

### 7.5 调度公式（核心）

```swift
func nextInterval(stability: Double, requestRetention: Double = 0.9) -> Int {
    // FSRS-5 公式：基于稳定性计算下次间隔
    let interval = stability * (pow(requestRetention, -1.0/decay) - 1) / factor
    return max(1, min(maximumInterval, Int(round(interval))))
}

// decay 和 factor 是 FSRS-5 的固定常数
let decay: Double = -0.5
let factor: Double = pow(0.9, 1.0/decay) - 1
```

---

## 八、数据结构

### 8.1 主要模型

```swift
import SwiftData
import Foundation

// MARK: - 卡片本体

@Model
final class WordCard {
    @Attribute(.unique) var id: UUID
    
    // 基本信息
    var word: String
    var phoneticUS: String?
    var phoneticUK: String?
    var audioUSPath: String?
    var audioUKPath: String?
    
    // 内容（用关系而非内嵌，便于单独学习子项）
    @Relationship(deleteRule: .cascade) var definitions: [WordDefinition]
    @Relationship(deleteRule: .cascade) var englishDefinitions: [WordEnglishDefinition]
    @Relationship(deleteRule: .cascade) var examples: [WordExample]
    var imageData: Data?
    
    // 学习状态
    var phase: CardPhase
    var currentLearningStage: LearningStage?  // 学习中处于哪个阶段
    var createdAt: Date
    var firstLearnedAt: Date?
    
    // FSRS 状态
    var fsrs: FSRSState
    
    init(word: String) {
        self.id = UUID()
        self.word = word
        self.definitions = []
        self.englishDefinitions = []
        self.examples = []
        self.phase = .未学习
        self.createdAt = .now
        self.fsrs = FSRSState()
    }
}

// MARK: - 卡片子项

@Model
final class WordDefinition {
    @Attribute(.unique) var id: UUID
    var partOfSpeech: String        // "v." / "n." / "adj."
    var meaning: String              // "放弃；遗弃"
    var order: Int                   // 显示顺序
}

@Model
final class WordEnglishDefinition {
    @Attribute(.unique) var id: UUID
    var content: String              // "to leave completely..."
    var order: Int
}

@Model
final class WordExample {
    @Attribute(.unique) var id: UUID
    var sentence: String             // "He abandoned his car."
    var translation: String?         // "他丢下了他的车。"
    var audioPath: String?
    var source: String?              // "牛津" / "用户自定义"
}

// MARK: - 枚举

enum CardPhase: Int, Codable {
    case 未学习 = 0
    case 学习中 = 1
    case 复习池中 = 2
    case 待复习 = 3        // 到期但未开始
    case 待重学 = 4        // 复习失败，等待重学
}

enum LearningStage: Int, Codable {
    case 释义阶段 = 0
    case 听音阶段 = 1
    case 拼写阶段 = 2
}

enum SelfAssessment: Int, Codable, CaseIterable {
    case 不认识 = 1
    case 想想 = 2
    case 模糊 = 3
    case 认识 = 4
    
    var fsrsRating: FSRSRating {
        switch self {
        case .不认识: return .again
        case .想想:   return .hard
        case .模糊:   return .good
        case .认识:   return .easy
        }
    }
}

enum FSRSRating: Int, Codable {
    case again = 1
    case hard = 2
    case good = 3
    case easy = 4
}

// MARK: - FSRS 状态

struct FSRSState: Codable {
    var stability: Double = 0
    var difficulty: Double = 0
    var elapsedDays: Int = 0
    var scheduledDays: Int = 0
    var reps: Int = 0
    var lapses: Int = 0
    var dueDate: Date?
    var lastReview: Date?
    var state: CardState = .new
}

enum CardState: Int, Codable {
    case new = 0           // 新卡，未学
    case learning = 1      // 学习中
    case review = 2        // 复习中
    case relearning = 3    // 重新学习
}

// MARK: - 会话记录

@Model
final class StudySession {
    @Attribute(.unique) var id: UUID
    var cardId: UUID
    var sessionType: SessionType
    var startedAt: Date
    var finishedAt: Date?
    var initialAssessment: SelfAssessment?
    var spellingFirstTryCorrect: Bool?
    var stepsCompleted: [String]
    var failed: Bool
    
    init(cardId: UUID, type: SessionType) {
        self.id = UUID()
        self.cardId = cardId
        self.sessionType = type
        self.startedAt = .now
        self.stepsCompleted = []
        self.failed = false
    }
}

enum SessionType: Int, Codable {
    case 初次学习 = 0
    case 复习 = 1
    case 重学 = 2
}
```

### 8.2 队列管理（运行时）

```swift
@Observable
class TodayQueues {
    var newWordsQueue: [WordCard] = []      // 今日新词
    var reviewQueue: [WordCard] = []         // 今日到期复习
    var relearnQueue: [WordCard] = []        // 复习失败待重学
    
    // 复习按钮：返回复习队列副本
    func startReviewSession() -> ReviewSession {
        return ReviewSession(cards: reviewQueue, queues: self)
    }
    
    // 学习按钮：合并新词 + 待重学
    func startLearningSession() -> LearningSession {
        let combined = newWordsQueue + relearnQueue
        return LearningSession(cards: combined, queues: self)
    }
    
    var reviewCount: Int { reviewQueue.count }
    var learningCount: Int { newWordsQueue.count + relearnQueue.count }
}
```

### 8.3 复习会话

```swift
class ReviewSession {
    var queue: [WordCard]
    var passedCards: [WordCard] = []
    var failedCards: [WordCard] = []
    weak var queues: TodayQueues?
    
    init(cards: [WordCard], queues: TodayQueues) {
        self.queue = cards
        self.queues = queues
    }
    
    var currentCard: WordCard? { queue.first }
    
    // 用户做完一个词的复习
    func completeCurrentCard(result: ReviewResult) {
        guard let card = queue.first else { return }
        queue.removeFirst()
        
        switch result {
        case .passedEasy:
            FSRSEngine.update(card.fsrs, rating: .easy)
            passedCards.append(card)
        case .passedHard:
            FSRSEngine.update(card.fsrs, rating: .hard)
            passedCards.append(card)
        case .failed:
            FSRSEngine.update(card.fsrs, rating: .again)
            failedCards.append(card)
            queues?.relearnQueue.append(card)
        }
    }
    
    var isFinished: Bool { queue.isEmpty }
}

enum ReviewResult {
    case passedEasy        // 自测认识 + 拼写一次对
    case passedHard        // 拼写错但补救对
    case failed            // 自测非认识 / 补救仍错
}
```

### 8.4 学习会话

```swift
class LearningSession {
    var queue: [WordCard]
    weak var queues: TodayQueues?
    
    init(cards: [WordCard], queues: TodayQueues) {
        self.queue = cards
        self.queues = queues
    }
    
    var currentCard: WordCard? { queue.first }
    var currentStage: LearningStage? { queue.first?.currentLearningStage }
    
    // 子步骤答错：词排到末尾
    func failCurrentStep() {
        guard let card = queue.first else { return }
        // currentLearningStage 已经记录了当前阶段，不变
        queue.removeFirst()
        queue.append(card)
    }
    
    // 阶段完成：进入下一阶段
    func completeCurrentStage() {
        guard let card = queue.first else { return }
        let next = card.currentLearningStage?.next
        card.currentLearningStage = next
        
        if next == nil {
            // 整个词学完
            queue.removeFirst()
            initializeFSRS(for: card)
            card.phase = .复习池中
            removeFromQueues(card)  // 从 newWordsQueue 或 relearnQueue 移除
        }
    }
    
    private func initializeFSRS(for card: WordCard) {
        // 用学前自测的 Rating 初始化
        // 详见 FSRSEngine
    }
    
    var isFinished: Bool { queue.isEmpty }
}

extension LearningStage {
    var next: LearningStage? {
        switch self {
        case .释义阶段: return .听音阶段
        case .听音阶段: return .拼写阶段
        case .拼写阶段: return nil  // 完成
        }
    }
}
```

### 8.5 FSRS 引擎

```swift
struct FSRSEngine {
    static let defaultParams = FSRSParameters()
    
    // 新卡初始化
    static func initialize(_ state: inout FSRSState, rating: FSRSRating) {
        let w = defaultParams.weights
        state.stability = w[rating.rawValue - 1]
        state.difficulty = initDifficulty(rating: rating)
        state.reps = 1
        state.lapses = 0
        state.lastReview = .now
        state.state = .review
        state.scheduledDays = nextInterval(stability: state.stability)
        state.dueDate = Calendar.current.date(byAdding: .day, value: state.scheduledDays, to: .now)
    }
    
    // 复习更新
    static func update(_ state: inout FSRSState, rating: FSRSRating) {
        let now = Date()
        let elapsed = elapsedDays(from: state.lastReview, to: now)
        let retrievability = forgetRate(elapsed: elapsed, stability: state.stability)
        
        state.elapsedDays = elapsed
        state.difficulty = nextDifficulty(d: state.difficulty, rating: rating)
        
        if rating == .again {
            state.stability = forgetStability(d: state.difficulty,
                                              s: state.stability,
                                              r: retrievability)
            state.lapses += 1
            state.state = .relearning
        } else {
            state.stability = recallStability(d: state.difficulty,
                                              s: state.stability,
                                              r: retrievability,
                                              rating: rating)
            state.state = .review
        }
        
        state.reps += 1
        state.lastReview = now
        state.scheduledDays = nextInterval(stability: state.stability)
        state.dueDate = Calendar.current.date(byAdding: .day, value: state.scheduledDays, to: now)
    }
    
    // 公式部分（参考 FSRS-5 论文）
    private static func nextInterval(stability: Double) -> Int {
        let decay = -0.5
        let factor = pow(0.9, 1.0 / decay) - 1
        let interval = stability * (pow(defaultParams.requestRetention, 1.0 / decay) - 1) / factor
        return max(1, min(defaultParams.maximumInterval, Int(round(interval))))
    }
    
    private static func forgetRate(elapsed: Int, stability: Double) -> Double {
        return pow(1 + Double(elapsed) / (9 * stability), -1)
    }
    
    // ... 其他公式（initDifficulty, nextDifficulty, recallStability, forgetStability）
    // 参考 https://github.com/open-spaced-repetition/ts-fsrs 翻译
}

struct FSRSParameters {
    var weights: [Double] = [
        0.40255, 1.18385, 3.173, 15.69105,
        7.1949, 0.5345, 1.4604, 0.0046,
        1.54575, 0.1192, 1.01925, 1.9395,
        0.11, 0.29605, 2.2698, 0.2315,
        2.9898, 0.51655, 0.6621
    ]
    var requestRetention: Double = 0.9
    var maximumInterval: Int = 36500
}
```

---

## 九、页面模拟图汇总

### 9.1 主页

```
┌─────────────────────────────┐
│         Husk                │
│                             │
│      今天                    │
│                             │
│   ┌─────────────────────┐   │
│   │  📖 复习             │   │
│   │  待复习: 8 个         │   │
│   └─────────────────────┘   │
│                             │
│   ┌─────────────────────┐   │
│   │  ✏️ 学习             │   │
│   │  新词: 5 + 待重学: 2  │   │
│   └─────────────────────┘   │
│                             │
│   ─────────────────         │
│                             │
│   今日已学: 12 个            │
│   今日已复习: 15 个           │
│   连续打卡: 7 天             │
│                             │
└─────────────────────────────┘
```

### 9.2 学前自测

```
┌─────────────────────────────┐
│   abandon                   │
│   🔊 /əˈbændən/             │
│                             │
│   你认识这个单词吗？           │
│                             │
│   [ 认识 ]                   │
│   [ 模糊 ]                   │
│   [ 想想 ]                   │
│   [ 不认识 ]                 │
│                             │
└─────────────────────────────┘
```

### 9.3 "认识"后检查页

```
┌─────────────────────────────┐
│  abandon  🔊 /əˈbændən/      │
│                             │
│  请确认你都掌握了：           │
│                             │
│  📖 中文含义                 │
│  ☐ v. 放弃；遗弃            │
│  ☐ v. 抛弃（家人朋友）       │
│  ☐ n. 放纵；无拘束          │
│                             │
│  🇬🇧 英文释义                │
│  ☐ to leave completely     │
│     and not return         │
│                             │
│  ✏️ 拼写                    │
│  ☐ a-b-a-n-d-o-n           │
│                             │
│  [ 全部掌握 ✓ ]              │
└─────────────────────────────┘
```

### 9.4 释义 Step 1（英→中）

```
┌─────────────────────────────┐
│  abandon  🔊 /əˈbændən/      │
│                             │
│  选择正确的中文释义：          │
│                             │
│  [ A. 接受 ]                 │
│  [ B. 放弃；遗弃 ]            │
│  [ C. 携带 ]                 │
│  [ D. 继续 ]                 │
│                             │
└─────────────────────────────┘
```

### 9.5 释义 Step 2（中→英）

```
┌─────────────────────────────┐
│  放弃；遗弃                  │
│                             │
│  选择对应的英文单词：          │
│                             │
│  [ A. abundant ]            │
│  [ B. abound ]              │
│  [ C. abandon ]             │
│  [ D. abash ]               │
│                             │
└─────────────────────────────┘
```

### 9.6 释义 Step 3（英英→中）

```
┌─────────────────────────────┐
│  to leave completely and    │
│  not return                 │
│                             │
│  选择对应的中文释义：          │
│                             │
│  [ A. 拥抱 ]                 │
│  [ B. 放弃；遗弃 ]            │
│  [ C. 围绕 ]                 │
│  [ D. 探索 ]                 │
│                             │
└─────────────────────────────┘
```

### 9.7 听音 Step 4（听音→选词）

```
┌─────────────────────────────┐
│                             │
│       🔊（点击播放）         │
│                             │
│  这个发音对应哪个单词？        │
│                             │
│  [ A. abandon ]             │
│  [ B. abundant ]            │
│  [ C. abound ]              │
│  [ D. abash ]               │
│                             │
└─────────────────────────────┘
```

### 9.8 听音 Step 5（听音→选义）

```
┌─────────────────────────────┐
│                             │
│       🔊                    │
│                             │
│  这个单词的意思是？            │
│                             │
│  [ A. 接受 ]                 │
│  [ B. 放弃；遗弃 ]            │
│  [ C. 携带 ]                 │
│  [ D. 继续 ]                 │
│                             │
└─────────────────────────────┘
```

### 9.9 听音 Step 6（听音自测）

```
┌─────────────────────────────┐
│                             │
│       🔊                    │
│                             │
│  你能听音辨词吗？             │
│                             │
│   [ 认识 ]                   │
│   [ 模糊 ]                   │
│   [ 想想 ]                   │
│   [ 不认识 ]                 │
│                             │
└─────────────────────────────┘
```

### 9.10 拼写 Step 7（听音拼写）

```
┌─────────────────────────────┐
│                             │
│       🔊                    │
│                             │
│   _ _ _ _ _ _ _             │
│                             │
│  ┌────────────────────┐     │
│  │ q w e r t y u i o p│     │
│  │  a s d f g h j k l │     │
│  │   z x c v b n m    │     │
│  │       [delete]     │     │
│  └────────────────────┘     │
│                             │
└─────────────────────────────┘
```

### 9.11 拼写 Step 7a（选拼写）

```
┌─────────────────────────────┐
│                             │
│       🔊                    │
│                             │
│  选择正确的拼写：             │
│                             │
│  [ A. abandone ]            │
│  [ B. abandon ]             │
│  [ C. abbandon ]            │
│  [ D. abandun ]             │
│                             │
└─────────────────────────────┘
```

### 9.12 拼写 Step 7b（全提示拼写）

```
┌─────────────────────────────┐
│                             │
│  v. 放弃；遗弃                │
│  to leave completely and    │
│  not return                 │
│  🔊                         │
│                             │
│   _ _ _ _ _ _ _             │
│                             │
│  [键盘]                     │
│                             │
└─────────────────────────────┘
```

### 9.13 学习完成

```
┌─────────────────────────────┐
│                             │
│        ✓                    │
│                             │
│    abandon                  │
│    已掌握                    │
│                             │
│  下次复习：4 天后             │
│                             │
└─────────────────────────────┘
```

### 9.14 复习自测

```
┌─────────────────────────────┐
│                             │
│       🔊 /əˈbændən/          │
│                             │
│  你认识这个单词吗？           │
│                             │
│   [ 认识 ]                   │
│   [ 模糊 ]                   │
│   [ 想想 ]                   │
│   [ 不认识 ]                 │
│                             │
└─────────────────────────────┘
```

### 9.15 复习拼写

```
┌─────────────────────────────┐
│                             │
│       🔊 /əˈbændən/          │
│                             │
│   _ _ _ _ _ _ _             │
│                             │
│  [键盘]                     │
│                             │
└─────────────────────────────┘
```

### 9.16 复习完成

```
┌─────────────────────────────┐
│                             │
│        ✓                    │
│                             │
│   今日复习完成                │
│                             │
│   通过：6 个                 │
│   待重学：2 个                │
│                             │
│   [ 返回首页 ]                │
│   [ 立即学习 ]                │
│                             │
└─────────────────────────────┘
```

---

## 附录 A：错误处理规则速查

| 场景 | 规则 |
|------|------|
| 学前自测选"不认识/想想/模糊" | 走完整流程 |
| 学前自测选"认识" | 进入检查页，可勾选不会项重点学习 |
| 释义阶段任一步答错 | 词排到队列末尾，下次从释义阶段开始 |
| 听音阶段任一步答错 | 词排到队列末尾，下次从听音阶段开始 |
| 听音自测选"想想/不认识" | 词排到队列末尾，下次从听音阶段开始 |
| 拼写 Step 7 错 | 进入 7a |
| 拼写 7a 错 | 词排到队列末尾，下次从拼写阶段开始 |
| 拼写 7b 错 | 词排到队列末尾，下次从拼写阶段开始 |
| 复习自测选"认识" | 进入拼写测试 |
| 复习自测选"模糊/想想/不认识" | 加入待重学队列 |
| 复习拼写错 | 进入 7a/7b 补救 |
| 复习补救通过 | FSRS 评 Hard |
| 复习补救失败 | 加入待重学队列，FSRS 评 Again |

## 附录 B：术语表

- **FSRS**：Free Spaced Repetition Scheduler，开源间隔重复算法
- **Stability（稳定性）**：FSRS 中表示记忆强度的核心变量，单位为天
- **Difficulty（难度）**：FSRS 中表示该卡片对用户的难度，1-10
- **Retrievability（可提取性）**：当前时刻能成功回忆该卡片的概率
- **Rating**：FSRS 的 4 档评分（Again/Hard/Good/Easy）
- **自测**：用户主观判断对单词的熟悉程度
- **阶段**：学习流程的三大分组（释义/听音/拼写）
- **步骤**：阶段内的具体测试（如 Step 1, Step 2）

---

*文档结束。如需修改或补充，编辑后更新版本号。*
