# Husk 记忆架构 · 代码文档

> 版本：v4.5 · 日期：2026-08-18
> 配套设计文档：husk-architecture-design.md（决策理由见该文档，尤其第九、十节）
> 本文档只含接口/协议/类定义，具体某个 CardType 的图内容见各类型自己的代码文档
> 本文档粒度：接口签名 + 关键算法伪代码，不是可直接编译的完整实现。留空/简化的地方会明确标注。
>
> **v4.5 变更**（正式编码前的最后一轮查缺补漏：补全此前只被引用、从未正式声明的基础类型，不改变任何既有行为）：
> 1. **`StepID`/`PromptContent`/`ChecklistItem` 补上正式声明**（六、6.2）：自 v1.0 起就在使用，历次改版只写"与 v1.0 相同不重复列出"，从未出现在当前版本文档正文里。
> 2. **`StepAction`/`ActionInput`/`EngineJudge` 补上正式声明**（五、5.4.2）：同上，v1.0 遗留的文档缺口。`EngineJudge.evaluate` 里 `binarySelfAssessment` 分支产出的 case 名按 v4.4 正式命名订正为 `.listeningCheckResult`（早期草稿曾用过 `.binaryAssessmentResult` 这个已废弃的名字）；`StepAction.checklistConfirm` 补上实际已在使用但未回填进声明的 `allowEmptySelection` 参数。
>
> **v4.4 变更**（补全此前只被引用、从未正式声明的两个类型，不改变任何既有行为）：
> 1. **`ActionResult` 补上正式 enum 定义**（五、5.4.1）：此前 `.boolResult`/`.timedAssessmentResult`/`.checklistResult`/`.listeningCheckResult` 只以 switch 分支的形式散落出现，从未给出 enum 本身的声明，这是文档遗漏，不是设计变化。
> 2. **`ListeningSelfCheck` 补上正式定义**（五、5.4.1）：此前在 husk-word-card-code.md 里只以"已有的二值枚举"带过。放在架构层声明（而不是单词型代码文档），因为它是 `ActionResult` 一个 case 的 payload 类型。
>
> **v4.3 变更**（对接架构设计文档 v1.1 第九、十节）：
> 1. `Unit` 新增 `desiredRetention: Double` 字段（四），创建时通过滑块设置，`let` 常量，创建后不可修改。
> 2. `Unit` 新增计算属性 `masteredStabilityThreshold`（四），由 `desiredRetention` 反推"下次复习间隔达到 365 天"所需的 stability 阈值，供各 CardType 判定"学完不再复习"使用，不影响队列/引擎调度逻辑。
>
> **v4.0 变更总览**（相对 v3.0，这是继"传送带调度""StepOutcome简化"之后的第三次重大重构，把路由判断从代码逻辑改成纯数据规则表）：
>
> 1. **`Step` 彻底瘦身为纯静态描述**：只剩 `id`、`prompt`、`action`、`highlightSectionID`。`route` 闭包被删除，`StepOutcome` 类型也被删除——"下一步去哪、是否学完、要不要弹失败详情页"这些判断，不再是某个 Step 自己知道的事，全部交给新增的**规则表机制**（见五）。
> 2. **新增独立的临时状态存储 `LearningProgress` / `ReviewSession`**：`learningPath`、各 Step 错误次数、检查页勾选结果、复习自测来源这类"只在当前学习/复习周期内有意义"的数据，不再挂在 `Card` 身上，也不挂在 `Step` 上，统一挪到这两个新类型里，每张卡各自独立一份。`Card` 协议因此进一步瘦身，只保留真正需要长期存在的内容与状态。
> 3. **新增"学习内容"字段**：`Card` 除了原有的完整内容外，新增一份"学习内容"，默认等于完整内容；检查页勾选部分内容重点学习时，这份"学习内容"会被替换成内容子集，后续出题基于这份"学习内容"而不是完整内容。
> 4. **路由判断改为查规则表**：`LearningRouteRule`（学习流程）与 `ReviewRouteRule`（复习流程）是两套独立的静态数据表，用"特异性匹配"（不是顺序匹配）—— 条件字段填得最多的行生效，同特异性冲突由 DEBUG 断言拦截，不会有沉默走错的情况。`Factory` 的角色收窄回最初的本意：只负责组装 UI 展示需要的内容（文案、选项、正确答案），不再承担任何路由职责。
> 5. **复习流程的调度节奏不变**：仍是单卡一次会话内"自测→拼写测试"跑完，不引入槽位排队（维持设计文档第十节 10.5 的原决定）。变化的只是"这一步该弹详情页吗、下一步做什么"这层判断，现在也统一查 `ReviewRouteRule` 表，不再是各自的 `route` 闭包硬编码。
> 6. **两条独立捷径**：Step0 自测选"认识（即时）"、学习界面的"标熟"按钮，都不经过规则表判定，直接判学完。**（v4.2 起，"认识即时"这条捷径已被取消，见下方 v4.2 变更）**
>
> **v4.1 补充**（解决 v4.0 遗留的三处衔接问题，均不改变 v4.0 的核心设计，只是把"待细化"落实）：
> 1. **"这一步答完还要再问一步"的复合交互**（如单词型 Step0 的自测+检查页）：不扩展 `StepAction`，改为在查表结果 `RouteTarget` 上新增 `.stepWithFollowUp` 变体，由引擎收到这个 target 后再多问一轮、再多查一次表。这条能力是架构层通用机制，任何 CardType 有类似需求都可复用，不需要为每种具体复合交互扩展基础 action 类型（见五、5.5）。
> 2. **`LearningStepFactory.buildSequence` 补上 `settings` 参数**：v4.0 遗漏了这个参数，导致具体 CardType 无法在组装物理槽位链时读取全局设置（比如单词型判断 Step3 是否存在）。
> 3. **检查页勾选结果如何转换成规则表可查的 `outcome`**：`EngineJudge.evaluate` 的职责保持不变（只把 `StepAction`+`ActionInput` 转成 `ActionResult`），"结果转成具体 CardType 的 outcome 枚举"这一步交给各 CardType 自己的规则表实现里的转换函数负责，架构层的规则表协议明确要求提供这个转换接口（见五、5.7）。
> 4. **`RouteTarget` 改为架构层统一提供的泛型类型**（`RouteTarget<FinishedPayload>`），不再让每个 CardType 各自定义结构相同的枚举——这样 `.stepWithFollowUp` 是所有类型共用的同一个 case，引擎可以直接 `switch` 识别，不需要额外的跨类型协议（`FollowUpExtractable` 因此被取消）。复习流程对应有 `ReviewRouteTarget<FinishedPayload>`。
> 5. **`ReviewSession` 的持久化被真正落实**：`ReviewEngine.run` 现在会在会话开始时尝试恢复已有的未完成 session，每次推进到下一步就写盘，正常结束/转入完整重学时清除——修复了 v4.0 示例代码把它当纯局部变量处理、导致复习中断会丢失进度的问题。
> 6. **`FinishedPayload` 加上 `FSRSRatingConvertible` 协议约束**：`LearningRouteTable`/`ReviewRouteTable` 的 `FinishedPayload` 关联类型不再是无约束的任意类型，而是必须能提供 `.fsrsRating: FSRSRating`。这消除了 `process`/`run` 方法里原来需要的 `payload as! FSRSRating` 运行时强转，改为编译期保证的类型安全调用（见二、五、5.7、六、6.3、七）。
>
> **v4.2 变更**（产品逻辑调整，配套设计文档同步升级到 v1.1）：
> 1. **"认识（即时）"不再是直接学完的捷径**：现在也会触发检查页（`stepWithFollowUp`），跟"想到了"共用同一个检查页机制，区别仅在于检查页"全部掌握"按钮是否可用（认识入口可用、想到了入口禁用，即想到了必须至少勾选一项未掌握）。具体规则表变更见 husk-word-card-code.md 三、3.4。
> 2. **`ReviewRouteTarget<FinishedPayload>` 新增 `.stepWithFollowUp` case**：为了支持单词型复习流程新增的"认识（即时）→ 确认页"复合交互（见 husk-word-card-code.md 四、4.3），复习流程的路由目标类型需要跟学习流程一样能表达"这次不是终态，需要再问一轮"。`ReviewEngine.run` 相应新增 `resolveWithFollowUp` 辅助方法，与 `LearningEngine.process` 里的同名方法同构（见七）。
> 3. **新增 Unit 级"单次学习目标"机制**：见十三，`Unit` 新增 `dailyLearningGoal` 字段，`LearningEngine` 引入本轮已学完计数，达标后结束学习会话。

---

## 一、Card 协议（大幅瘦身）

```swift
protocol Card: AnyObject, Identifiable {
    var id: UUID { get }
    var cardType: CardType { get }
    var unitID: UUID { get set }
    var createdAt: Date { get }
    var source: CardSource { get set }

    // FSRS 调度状态，长期持久化，不受本次重构影响
    var fsrs: FSRSState { get set }

    // 这张卡是否已完全学完，进入长期复习轮转
    var isFullyLearned: Bool { get }

    // 复习时展示的线索
    func reviewPrompt() -> ReviewPrompt

    // 随手记相关字段，仅 source == .quickCapture 时有意义
    var sourceContext: String? { get set }
    var sourceDocumentTitle: String? { get set }
    var sourceDocumentId: String? { get set }
    var capturedAt: Date? { get set }
    var addedToQueue: Bool { get set }

    // 这张卡片当前正被哪个队列/槽位体系追踪。
    // nil：已完全学完，进入长期复习轮转
    // .review：在复习队列里排队等到期
    // .newCards / .fullRelearn：在学习引擎的 Step 槽位传送带里
    var originQueue: QueueKind? { get set }

    func postFSRSUpdateHook(context: ReviewSession?)

    // 失败详情页的完整展示内容，具体内容由类型自己决定
    func fullDetailContent() -> DetailContent

    // v4.0 新增：这次学习该基于哪些内容出题。默认等于完整内容；
    // 检查页勾选部分内容重点学习时，被替换为内容子集（见三、LearningProgress）。
    // 具体"内容"长什么样由各 CardType 自己定义（比如 WordCard 的释义/拼写），
    // 这里只要求类型提供一个"重置为默认（=完整内容）"和"收窄为子集"的接口，
    // 具体见各类型自己的代码文档。
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
    case relearn = 1   // 保留 case，新逻辑不再产生此状态
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
```

**v4.0 从 `Card` 协议里彻底移除的东西**（相对 v3.0）：`currentStepID`。这张卡当前在哪个 Step，现在记录在 `LearningProgress`（学习流程）或 `ReviewSession`（复习流程）里，不再是 `Card` 自己的字段——`Card` 不应该知道自己"正在被哪个引擎、走到哪一步"，这属于运行时的、周期性的状态，跟"这是一张什么内容的卡"是两个维度，理应分开存放。

---

## 二、FSRS 通用状态

`FSRSState`、`FSRSCardState`、`FSRSParameters`、`FSRSEngine`（`initialize`/`update` 等方法）与 v1.0 相同，不重复列出。

```swift
enum FSRSRating: Int, Codable {
    case again = 1
    case hard = 2
    case good = 3
    case easy = 4
}

/// v4.1 新增：让 LearningRouteTable.FinishedPayload（见五、5.7）能被约束到
/// "必须可以转换成 FSRSRating"，而不是任意类型。这样 process 方法（见六、6.3）
/// 能在编译期确定 resolved.target 里 .finished 携带的 payload 一定能拿到一个
/// FSRSRating，不需要 `as! FSRSRating` 这种运行时强转（v4.1 早前遗留的技术债，
/// 见十三"已解决问题"记录）。
protocol FSRSRatingConvertible {
    var fsrsRating: FSRSRating { get }
}

/// FSRSRating 自己就是最简单的实现：直接返回自己
extension FSRSRating: FSRSRatingConvertible {
    var fsrsRating: FSRSRating { self }
}
```

单词型的 `LearningRouteTable.FinishedPayload` 直接实例化为 `FSRSRating`（见 husk-word-card-code.md），天然满足这个约束。如果未来某个 CardType 学完时需要携带比单纯 Rating 更多的信息（比如连带一些统计元数据），可以定义自己的类型去遵循 `FSRSRatingConvertible`，只要求提供"怎么从这个类型算出一个 FSRSRating"，不强制"这个类型必须就是 FSRSRating 本身"。

---

## 三、学习/复习临时状态存储：`LearningProgress` / `ReviewSession`

这是本次重构新增的核心概念。原来分散在 `Card`（`learningPath`/`step1CorrectOnFirstTry`/`checklistUncheckedSpelling`）、`EngineState.typeContext`（`SessionContext`）、以及一度设想挂在 `Step` 上的各种临时数据，现在统一收进这两个类型：**只要是"这张卡在当前这一轮学习/复习周期内才有意义、不需要跟着卡片本身长期保留"的数据，都放这里，不再有第三个存放的地方。**

### 3.1 LearningProgress：每张卡的学习临时状态

```swift
/// 每张正在学习中的卡，对应一份 LearningProgress，随卡片一起持久化
/// （学习过程可能被中断切后台，这份数据需要能在下次回来时原样恢复）。
/// 卡片学完退出学习引擎时，对应的 LearningProgress 应当被清除。
struct LearningProgress: Codable {
    let cardID: UUID

    /// 这张卡当前实际排在哪个 Step 槽位。取代 v3.0 里 Card.currentStepID 的角色。
    var currentStepID: StepID

    /// 每个 Step 各自的错误次数，供规则表里可能需要用到的"错了几次"这类条件
    /// （目前单词型规则表暂未用到这个维度，但架构层保留这份记录能力，
    /// 供未来任何 CardType 需要时使用，不需要额外改动这个类型）
    var errorCountByStep: [StepID: Int] = [:]

    /// 具体 CardType 专属的临时状态（如单词型的 learningPath、
    /// step1CorrectOnFirstTry、checklistUncheckedSpelling），
    /// 遵循 LearningTypeContext 协议，见下方
    var typeContext: (any LearningTypeContext)?
}

/// 类型专属的学习临时状态协议，类似 v3.0 的 SessionContext，但明确只服务学习流程
protocol LearningTypeContext: Codable {}
```

### 3.2 ReviewSession：每张卡的复习会话临时状态

```swift
/// 复习流程调度节奏不变（单卡一次会话内自测→拼写测试跑完），
/// 这份数据的生命周期严格绑定"一次复习会话"——会话开始时创建，
/// 会话结束（无论 finished 还是 transferToFullRelearn）后清除，不带到下一次复习。
///
/// 与 LearningProgress 对称：这份数据同样需要持久化，不是运行时局部变量——
/// 复习会话同样可能被中断（切后台、来电话、被系统杀掉），中断后重新进入
/// 这张卡的复习时，应该能读到中断前的 ReviewSession、从 currentStepID
/// 指示的那一步继续，而不是无声地从 reviewAssessment 重新开始一遍。
/// 具体的写盘时机与恢复流程见七、ReviewEngine.run 的实现。
struct ReviewSession: Codable {
    let cardID: UUID
    var currentStepID: StepID

    /// 具体 CardType 专属的会话上下文（如单词型的 WordReviewContext，
    /// 记录本轮自测选了"认识/想到了/模糊/不认识"中的哪一个）
    var typeContext: (any ReviewTypeContext)?
}

protocol ReviewTypeContext: Codable {}
```

**存放位置**：`LearningProgress`/`ReviewSession` 按 `cardID` 索引，可以理解为挂在 `Unit` 或某个全局的进度存储表上（具体持久化位置属于建模阶段的技术选择，比如做成 SwiftData 的 `@Model` 类、用 `cardID` 做主键关联，或者是 `Unit` 内部的一个字典），本文档不规定具体存储介质，只规定这两个类型各自的字段职责。

**待编码阶段解决的技术细节**：`any LearningTypeContext`/`any ReviewTypeContext` 是存在型，`Codable` 合成问题与 v1.0-v3.0 遗留的 `SessionContext` 编解码问题相同，需要手写 `encode(to:)`/`init(from:)` + 类型 tag 注册表。

---

## 四、Unit

```swift
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

    /// v4.3 新增：这个 Unit 的 FSRS 目标保留率，创建时通过滑块选择（见架构设计
    /// 文档九），范围 0.80–0.97，默认 0.90。**创建后不可修改**——FSRS 假设
    /// retention 在整个调度历史中恒定，中途改动会让已经累积的 stability 和
    /// 新 retention 不匹配，造成一次不可预期的复习节奏跳变。init 之后这个字段
    /// 只读，不提供任何 setter 或修改入口。
    let desiredRetention: Double

    /// v4.2 新增：单次学习目标（本轮学习会话最多学完几张卡就自动收尾）。
    /// nil = 使用全局默认值（AppSettings.defaultDailyLearningGoal），
    /// 非 nil = 这个 Unit 自己覆盖了目标值。两者都不代表"每日"概念上的强限制，
    /// 只是"学习会话一轮学多少"的批次大小，用户可以无限次"再学一轮"。
    var dailyLearningGoal: Int?

    @Transient lazy var learningEngine: LearningEngine = LearningEngine(unit: self)
    @Transient lazy var reviewEngine: ReviewEngine = ReviewEngine(unit: self)

    init(cardType: CardType, name: String, desiredRetention: Double = 0.90) {
        self.id = UUID()
        self.cardType = cardType
        self.name = name
        self.createdAt = .now
        self.learningSlots = LearningSlotChain(cardType: cardType)
        self.desiredRetention = desiredRetention
    }

    /// 解析出这个 Unit 实际生效的学习目标：自己设置过就用自己的，否则回退全局默认值
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

    /// v4.3 新增：某张卡在这个 Unit 的 desiredRetention 下，stability 达到多少
    /// 就意味着下一次复习间隔已经自然拉长到约一年（365 天）以后——统一以
    /// "间隔 ≥ 365 天"作为跨 Unit 可比的"学完不再复习"判定标准（见架构设计
    /// 文档十）。retention 越高，需要越高的 stability 才能撑出同样长的间隔，
    /// 所以这个阈值是随 desiredRetention 变化的，不是一个固定天数。
    ///
    /// 公式来自 FSRS 的 interval-stability 关系反推：
    ///   interval = stability × 9 × (1/retention - 1)
    /// 固定 interval = 365，解出 stability：
    ///   stability = 365 / (9 × (1/retention - 1))
    ///
    /// 这是纯计算属性，不持久化、不缓存——`fsrs.stability` 随复习不断变化，
    /// 每次需要判定时直接现算即可，不存在数据不同步的问题。
    var masteredStabilityThreshold: Double {
        365.0 / (9.0 * (1.0 / desiredRetention - 1.0))
    }
}
```

**v4.0 变化**：`Unit` 不再持有 `reviewEngineState: EngineState`——原来的 `EngineState`（含 `currentCardID`/`currentStepID`/`typeContext`）被 `ReviewSession`（三、3.2）取代，复习引擎的运行时状态现在跟着具体的卡（`ReviewSession` 按 `cardID` 索引），不再是挂在 `Unit` 上的单一一份状态。这个变化的动机：原来的 `EngineState` 隐含假设"引擎同一时刻只服务一张卡"，这个假设本身没错，但把状态存在 `Unit` 上、而不是跟着卡片走，会让"卡片自己的临时状态"和"引擎当前在忙什么"这两个概念纠缠在一起，拆开后职责更清楚。

---

## 五、规则表机制：`LearningRouteRule` / `ReviewRouteRule`

这是本次重构的核心。**架构层只定义"规则表怎么匹配、怎么检测冲突"这套通用机制，不包含任何具体 CardType 的规则内容**——具体规则数据由各 CardType 自己的代码文档提供（见 husk-word-card-code.md）。

### 5.1 核心机制：特异性匹配

规则表是一组"条件行"的静态数组。每一行包含若干**条件字段**（`Optional` 类型，`nil` 表示"通配"，即这个维度无论是什么值都算匹配这一行）和一个**结果**（去哪个 Step，或者学完，以及要不要弹失败详情页）。

匹配一次查询时：
1. 筛选出所有"键字段完全一致（比如 `step` 和 `outcome` 必须精确匹配，这两个字段不允许通配）、且所有已填的条件字段都与当前实际状态一致"的行。
2. 在这些候选行里，取"非 `nil` 条件字段数最多"的一行（**特异性最高**）作为最终结果。
3. 不依赖行在数组里的先后顺序——编辑规则表时，只需要为这条规则本身需要的字段赋值，不需要考虑它应该插在哪个位置、跟其他行的相对顺序。

```swift
/// 通用的"求特异性"辅助函数，具体 CardType 的规则类型各自实现自己的字段比对，
/// 但都遵循同一个原则：数一数这一行有几个条件字段不是 nil。
protocol RouteRuleMatching {
    /// 这一行的键字段是否与查询的键完全一致（不参与特异性计算，是先决条件）
    func matchesKey<Key: Equatable>(_ key: Key) -> Bool

    /// 这一行已填的条件字段是否都与当前状态吻合（不参与特异性计算，是先决条件）
    func matchesConditions(against state: Any) -> Bool

    /// 已填条件字段的数量，用于特异性比较
    var specificity: Int { get }
}

/// 通用查表函数：给定候选规则集合，返回特异性最高的一条。
/// 具体 CardType 的规则类型需要各自实现 matchesKey/matchesConditions/specificity，
/// 但查表逻辑本身是通用的，写一次即可复用给学习和复习两套规则表。
func resolveRoute<Rule: RouteRuleMatching>(candidates: [Rule]) -> Rule? {
    candidates.max { $0.specificity < $1.specificity }
    // 注意：真正的实现里，"取最大值"之前必须先做"是否存在并列最高特异性"的检查
    // （见 5.2 的 DEBUG 断言），max(by:) 本身在并列时会静默选其中一个，
    // 不能直接依赖它来解决冲突，这里只是示意查表本身的核心逻辑
}
```

### 5.2 冲突检测：DEBUG 断言

同一组"键字段相同"的规则行里，如果存在两行**条件互不矛盾**（存在某种真实状态能同时满足两行各自已填的条件字段）、**特异性相同**、但**结果不同**，这是一处规则冲突——查表时无法确定该用哪一行。这种情况不应该被静默地选一个了事，而应该在 App 启动时的 DEBUG 断言里直接检测出来并 crash，逼迫开发阶段发现并修正。

```swift
/// 在 DEBUG 构建下，App 启动时对每个 CardType 的规则表调用一次，
/// 检测是否存在"同键、同特异性、条件不互斥、结果却不同"的行对。
/// Release 构建不运行这个检查（假设已经在开发阶段修正过），避免运行时开销。
func assertNoRouteRuleConflicts<Rule: RouteRuleMatching>(_ rules: [Rule]) {
    #if DEBUG
    // 具体实现：按键字段分组，组内两两比较条件字段是否存在"每个字段要么至少一方是nil，
    // 要么双方非nil且值相等"这种关系（即两行的条件"相容"，存在实际状态能同时满足两者），
    // 且 specificity 相等、但 target/signal 不同 —— 命中即 assertionFailure
    // 具体比对算法留给编码阶段实现，这里只定义这个检查函数应该存在、应该在 DEBUG 下于
    // App 启动时被调用一次（比如放在 AppSettings 或规则表本身的静态初始化里触发）。
    #endif
}
```

### 5.3 数据存放：内嵌 Swift 静态数组

规则表以 Swift 静态数组字面量的形式内嵌在代码里，不做外置的 JSON/plist 配置文件。理由：项目目前是单人 iOS 开发，没有热更新或非程序员编辑规则表的实际需求，内嵌方式能保留编译期类型检查，比外置配置更适合当前阶段。若未来项目规模变化、出现内容运营团队需要独立于代码发布节奏调整规则，可以再考虑迁移到外置配置，但这不是当前阶段要解决的问题。

### 5.4 通用结果类型

```swift
/// 是否展示失败反馈，以及展示到什么程度。这不是 Step 的静态属性（v3.0 一度这样设计，
/// 后经评审否决），而是规则表每一行自带的结果之一——因为同一个 Step 在不同判定结果下，
/// 该展示的反馈程度可能不同（例：复习自测同一个 Step，"模糊"要提示、"认识"不需要）。
enum FailureSignal: Codable {
    case none          // 不展示任何反馈（正常前进/学完时的默认值）
    case lightHint      // 只做一次轻量提示（比如单词型 Step7 答错时）
    case detailPage      // 展示完整失败详情页（架构层通用能力，见五、5.6）
}
```

### 5.4.1 `ActionResult`：正式定义（v4.4 补全，此前只被各处引用从未正式声明）

`EngineJudge.evaluate(action:input:) -> ActionResult` 是 `StepAction` 判定环节的通用出口——不论具体 CardType，任何一个 Step 答完后，都先经过这一步产出一个 `ActionResult`，再由各 CardType 自己的 `outcomeKey(from:)` 翻译成具体的查表用 outcome。这个类型本身此前只以 `.boolResult`/`.timedAssessmentResult`/`.checklistResult`/`.listeningCheckResult` 等 case 的形式散落在各处 switch 分支里出现，从未给出过 enum 本身的声明，这里补上：

```swift
/// EngineJudge.evaluate 的统一返回类型。case 与 StepAction 的具体形式一一对应
/// （见二、StepAction 各 case），新增一种 StepAction 形式时需要在这里同步新增一个 case。
enum ActionResult {
    case boolResult(Bool)
    // 用于一次性对/错判定的 Step（如拼写测试、选词题），true=答对。

    case timedAssessmentResult(TimedAssessment)
    // 用于限时自测类 Step（如单词型 Step0），payload 是具体选中的自测档位。

    case listeningCheckResult(ListeningSelfCheck)
    // 用于二选一的听力自测类 Step（如单词型 Step6，见 husk-word-card-code.md 六、
    // 第2条），payload 是"听懂了/没听懂"的判定结果。

    case checklistResult(uncheckedItems: [ChecklistItem])
    // 用于检查页类 Step（如单词型的学习检查页、复习确认页），payload 是本次
    // 用户勾选为"未掌握"的条目列表（全部掌握 = 空数组，而不是单独一个 case）。
}
```

`ListeningSelfCheck` 同样此前只在 `husk-word-card-code.md` 里以"已有的二值枚举"带过，未正式定义，这里一并补上（放在架构层而非单词型代码文档，因为 `ActionResult.listeningCheckResult` 是架构层类型的一个 case，其 payload 类型也应在架构层声明；若未来出现第二个需要"二选一"语义的 CardType，可以直接复用，不需要重新定义）：

```swift
/// 二选一的自测结果，语义上与 TimedAssessment 的四分支自测是两回事——
/// 不共享同一个类型，避免"听懂/没听懂"被误当成"认识/想到了/模糊/不认识"的子集。
enum ListeningSelfCheck: Codable {
    case recognized       // 听懂了
    case notRecognized    // 没听懂
}
```

`ChecklistItem` 定义见六、6.2。

### 5.4.2 `StepAction` / `ActionInput` / `EngineJudge`：正式定义（补全，此前只被引用从未正式声明）

与 `ActionResult`/`ListeningSelfCheck` 同样的情况——`StepAction`（`Step.action` 的类型）、`ActionInput`（渲染层交回的原始作答）、`EngineJudge`（两者之间的判定环节）自 v1.0 起就在使用，历次改版只引用未重新声明，这里一并补全：

```swift
/// 一个 Step 是什么形式的交互。与 ActionResult 的 case 一一对应
/// （新增一种交互形式需要在 StepAction/ActionInput/ActionResult 三处同步扩展）。
enum StepAction {
    case multipleChoice(options: [String], correctIndex: Int)
    case spelling(correctAnswer: String, toleranceRule: SpellingTolerance = .exact)
    case timedSelfAssessment
    case binarySelfAssessment
    case checklistConfirm(items: [ChecklistItem], allowEmptySelection: Bool)
}

enum SpellingTolerance: Codable {
    case exact
    case caseInsensitive
    // 未来可加：忽略重音符号、允许一处拼写误差等
}

/// 渲染层收集到的原始用户输入，交给 EngineJudge.evaluate 判定
enum ActionInput {
    case selectedIndex(Int)
    case typedText(String)
    case timedChoice(TimedAssessment, elapsedMs: Int)
    case binaryChoice(ListeningSelfCheck)
    case checklistSelection(uncheckedItems: [ChecklistItem])
}

/// StepAction + ActionInput → ActionResult 的统一判定环节。任何一个 Step 答完后，
/// 都先经过这里产出一个 ActionResult，再由各 CardType 自己的 outcomeKey(from:) 翻译
/// 成具体的查表用 outcome（见五、5.7）。这里只判断"这次操作本身对不对/是什么形式的结果"，
/// 不知道任何具体 CardType 的语义。
enum EngineJudge {
    static func evaluate(action: StepAction, input: ActionInput) -> ActionResult {
        switch (action, input) {
        case (.multipleChoice(_, let correctIndex), .selectedIndex(let i)):
            return .boolResult(i == correctIndex)

        case (.spelling(let correct, let tolerance), .typedText(let text)):
            return .boolResult(matches(text, correct, tolerance))

        case (.timedSelfAssessment, .timedChoice(let choice, _)):
            return .timedAssessmentResult(choice)

        case (.binarySelfAssessment, .binaryChoice(let choice)):
            return .listeningCheckResult(choice)

        case (.checklistConfirm, .checklistSelection(let unchecked)):
            return .checklistResult(uncheckedItems: unchecked)

        default:
            fatalError("action 与 input 类型不匹配，说明 UI 层传错了数据")
        }
    }

    private static func matches(_ input: String, _ answer: String, _ rule: SpellingTolerance) -> Bool {
        switch rule {
        case .exact: return input == answer
        case .caseInsensitive: return input.lowercased() == answer.lowercased()
        }
    }
}
```

**与 8/15 早期草稿的一处命名订正**：早期草稿里 `binarySelfAssessment` 分支产出的是 `.binaryAssessmentResult(ListeningSelfCheck)`，v4.4 正式声明 `ActionResult`（5.4.1）时把这个 case 改名为 `.listeningCheckResult(ListeningSelfCheck)`，语义更贴合"这是 Step6 的听音自测专用结果"。上面 `EngineJudge.evaluate` 已按 v4.4 的正式命名书写，不是历史遗留的旧名字。

`checklistConfirm` 同样订正：早期草稿是 `case checklistConfirm(items: [ChecklistItem])`，不带 `allowEmptySelection`；但 husk-word-card-code.md 3.2/4.4 节的实际调用（`buildCheckPageStep(allowEmptySelection:)`/`buildReviewCheckPageStep()`）已经在传这个参数，说明这个字段是后续迭代中加上、但从未回填进 `StepAction` 本身的正式声明。上面按实际调用方式补全。

### 5.5 通用泛型 `RouteTarget<FinishedPayload>`（v4.1 修正：不再让每个 CardType 各自定义）

查表结果的"去向"有三种可能：去某个 Step、学完（带上学完时需要的具体信息，比如单词型是 `FSRSRating`）、或者"这次还不是终态，需要再走一个 Step 才能确定"。这三种可能性的**结构**（是三选一）对所有 CardType 都是一样的，唯一因类型而异的只是"学完时具体带什么信息"。

v4.1 之前的草稿曾设想让每个 CardType 各自定义一份结构几乎相同的 `RouteTarget` 枚举（比如单词型的 `WordRouteTarget`），但这样会导致"要不要弹检查页这类追加交互"（`.stepWithFollowUp`）这个 case 在每个类型里都要重新定义一遍，而且引擎那边想通用地处理"这次结果是不是 stepWithFollowUp"时，需要面对一堆结构相同、类型却不同的枚举，只能借助一个额外的协议（`FollowUpExtractable`）去跨类型识别，绕了一层不必要的弯路。

**改为架构层直接提供一个泛型类型，所有 CardType 共用**：

```swift
/// 查表结果的通用去向类型。FinishedPayload 是"学完时要携带什么信息"的类型参数，
/// 单词型实例化为 RouteTarget<FSRSRating>，未来别的 CardType 如果学完时需要
/// 携带别的信息类型，直接换一个类型参数即可，不需要重新定义整个枚举结构。
enum RouteTarget<FinishedPayload> {
    case step(StepID)
    case finished(FinishedPayload)
    case stepWithFollowUp(followUpStep: Step)
}
```

引擎收到 `.stepWithFollowUp(followUpStep:)` 时：
1. 立即 `present(followUpStep)`，拿到这次交互的 `ActionResult`
2. 用规则表实现里提供的转换函数（见 5.7），把这个结果转成对应 CardType 的 outcome
3. 用 `(原Step的StepID, 这个新outcome, 当前的临时状态)` **再查一次同一份规则表**，
   得到真正的最终结果（这次结果不应该再是 `.stepWithFollowUp`，否则视为规则表设计错误，
   引擎可以在这种情况下触发一次 DEBUG 断言防止无限递归）
4. 按这次查表结果正常处理（挪动槽位/学完/展示 signal），流程与普通一次查表完全一致

因为所有 CardType 共用同一个泛型 `RouteTarget<FinishedPayload>`，引擎在 `switch` 时可以直接匹配 `.stepWithFollowUp` 这个 case，**不需要任何跨类型识别的协议**（v4.1 早前草稿设想的 `FollowUpExtractable` 协议因此被取消，见十三"已解决问题"记录）。这个机制是通用的，不知道"检查页"这种具体细节——引擎只认"target 是 stepWithFollowUp 就再多问一轮、再查一次表"这条规则，具体触发条件（自测选了想到了）、具体多问的是什么（检查页）完全由单词型自己的规则表决定。

### 5.6 失败详情页：引擎通用能力

```swift
struct DetailContent {
    var sections: [DetailSection]
}

struct DetailSection {
    let id: String
    let title: String
    let content: String
}
```

任何一次查表结果的 `signal` 是 `.detailPage` 时，引擎在执行"去向"之前，先调用 `card.fullDetailContent()` 展示详情页，用户确认后才继续。`.lightHint` 则调用渲染层一个更轻量的提示方法。这条机制本身与 v1.0-v3.0 一脉相承，变化的只是"谁来决定用哪种 signal"——现在是规则表的每一行，不是 Step 的静态配置、也不是散落在 route 闭包里的判断。

### 5.7 规则表协议：`LearningRouteTable` / `ReviewRouteTable`（v4.1 补全）

v4.0 的引擎示例代码（六、七节）直接调用了 `ruleTable.resolve(...)`/`ruleTable.outcomeKey(...)` 等方法，但没有给出正式的协议定义，这里补全：

```swift
/// 每个 CardType 提供一份遵循此协议的实现，封装"怎么查自己的规则表"这件事，
/// 引擎只依赖这个协议，不知道具体规则表长什么样。
protocol LearningRouteTable {
    associatedtype Rule: RouteRuleMatching
    associatedtype OutcomeKeyType: Equatable

    /// 具体 CardType 学完时携带的信息类型（单词型直接是 FSRSRating）。
    /// v4.1：约束为 FSRSRatingConvertible（见二），保证 process 方法（六、6.3）
    /// 能在编译期从这个类型拿到一个 FSRSRating，不需要运行时强转。
    associatedtype FinishedPayload: FSRSRatingConvertible

    /// 把 EngineJudge.evaluate 产出的通用 ActionResult，转换成这个 CardType 自己的
    /// outcome 枚举值（如 WordLearningOutcomeKey）。这一步转换的职责边界：
    /// EngineJudge.evaluate 只负责"这次操作本身对不对/是什么形式的结果"这种通用判断，
    /// 不知道任何具体 CardType 的语义；把"通用结果"翻译成"这个 CardType 的规则表
    /// 用来查表的具体 outcome 值"，是每个 CardType 自己的职责，因为只有它自己知道
    /// 比如"检查页勾选了哪些"该怎么表达成一个 outcome case。
    func outcomeKey(from result: ActionResult) -> OutcomeKeyType

    /// 查表：给定当前 Step、这次的 outcome、这张卡的 LearningProgress、以及全局设置，
    /// 返回特异性最高的规则行（内部调用架构层通用的 resolveRoute(candidates:)）。
    /// 返回类型用架构层的泛型 RouteTarget<FinishedPayload>，不是每个类型各自的类型。
    /// v4.3 补充：新增 settings 参数——原协议遗漏了这个参数，导致规则表条件字段里
    /// 凡是依赖全局设置（如单词型的 definitionTestMode）的具体实现，只能自己想办法
    /// 拿到一个隐式单例。buildSequence(for:settings:) 在 v4.1 已经补过一次类似的
    /// settings 参数遗漏，这次是同一类问题在 resolve 这一侧的补漏（详见
    /// husk-word-card-code.md 六、第4条实现细节）。
    func resolve(step: StepID, outcome: OutcomeKeyType, progress: LearningProgress, settings: AppSettings) -> (target: RouteTarget<FinishedPayload>, signal: FailureSignal)?

    /// 查表命中后，是否需要更新 LearningProgress 里的某些字段（比如记录"Step1首次作答"），
    /// 由具体 CardType 决定要不要更新、更新什么，架构层只提供这个挂载点
    func updateProgress(_ progress: LearningProgress, step: StepID, outcome: OutcomeKeyType) -> LearningProgress
}

/// 复习流程的对应协议，结构类似，区别是查表用 ReviewSession 而不是 LearningProgress
protocol ReviewRouteTable {
    associatedtype Rule: RouteRuleMatching
    associatedtype OutcomeKeyType: Equatable
    associatedtype FinishedPayload: FSRSRatingConvertible

    func outcomeKey(from result: ActionResult) -> OutcomeKeyType
    /// v4.3：同 LearningRouteTable.resolve，补上 settings 参数，保持两个协议对称。
    func resolve(step: StepID, outcome: OutcomeKeyType, session: ReviewSession, settings: AppSettings) -> (target: ReviewRouteTarget<FinishedPayload>, signal: FailureSignal)?
    func updateSession(_ session: ReviewSession, step: StepID, outcome: OutcomeKeyType) -> ReviewSession
}

/// 复习流程的 target 比学习流程多一种可能（转入完整重学），
/// 不能直接复用 RouteTarget<FinishedPayload>，单独定义一个平行的泛型类型。
///
/// v1.1 追加：补上 .stepWithFollowUp，与学习流程的 RouteTarget 对齐——单词型
/// 复习流程新增了"认识（即时）→ 确认页"这个复合交互（详见 husk-word-card-code.md
/// 四、4.3），复习引擎需要跟学习引擎一样，能识别"这次结果不是终态，需要再问一轮、
/// 再查一次表"。ReviewEngine.run 处理这个 case 的方式与 LearningEngine.process
/// 的 resolveWithFollowUp 完全同构（见七），不重复定义一套单独的处理逻辑，只是
/// 复习侧的循环结构本身就是 while true，直接在循环内展开这次追加交互即可，
/// 不需要像学习引擎那样额外抽一个递归辅助方法。
enum ReviewRouteTarget<FinishedPayload> {
    case step(StepID)
    case finished(FinishedPayload)
    case transferToFullRelearn
    case stepWithFollowUp(followUpStep: Step)
}
```

**这解决了 v4.0 遗留的检查页转换问题**：`.checklistResult(uncheckedItems:)`（`EngineJudge.evaluate` 产出的通用结果）→ `outcomeKey(from:)`（单词型自己实现，把 `uncheckedItems` 翻译成 `.checklistCompleted(uncheckedMeaning:uncheckedSpelling:)`）→ 拿这个具体 outcome 去查 `wordLearningRouteTable`。这个转换步骤明确属于每个 CardType 自己的规则表实现，不需要 `EngineJudge` 或架构层知道"检查页有哪些具体勾选项"这种细节。

---

## 六、学习引擎：Step 槽位传送带（调度机制不变，路由判断改为查表）

### 6.1 StepSlot / 槽位处理阈值 / LearningSlotChain（与 v3.0 相同，不重复列出）

`StepSlot`、`shouldProcess(slot:stepID:nonThresholdStepIDs:)`、`LearningSlotChain` 的定义与 v3.0 完全一致——传送带的调度机制（指针怎么移动、什么时候停下处理、"≥2才处理"与"非空即处理"两条规则并存）本次不受影响，只字未改。

### 6.2 基础类型：`StepID` / `PromptContent` / `ChecklistItem`（补全，此前只被引用从未正式声明）

这三个类型自 v1.0 起就在使用，历次改版说明文字里只写"与 v1.0 相同，不重复列出"，但从未正式出现在当前版本文档正文里，属于文档遗漏，这里补上，不改变任何既有行为：

```swift
/// Step 的稳定标识符，跨 CardType 用命名空间前缀区分（如 "word.step0"），
/// 具体命名约定见各 CardType 自己的代码文档
struct StepID: Hashable, Codable {
    let rawValue: String
}

/// Step 展示层的通用提示内容占位符。本身只是结构容器，不含任何"该显示什么"的判断——
/// 具体某个 Step 该往这几个字段里填什么内容，属于设计文档的职责（见设计文档相关章节），
/// 代码文档里出现的 `PromptContent()` 均为空占位，渲染时由 Factory 结合具体卡片内容现填。
struct PromptContent {
    var primaryText: String?      // 主展示文字，如单词本身、释义、语境句
    var secondaryText: String?    // 次级提示，如音标、词性
    var audioPath: String?        // 可选：点击播放
    var imageData: Data?          // 可选：配图
}

/// 检查页/确认页勾选项的最小单位，"未勾选=未掌握"，具体 id/label 取值由各 CardType 决定
struct ChecklistItem: Codable, Identifiable {
    let id: String
    let label: String
}
```

### 6.3 LearningStepSequence：Step 的静态描述集合

```swift
struct Step {
    let id: StepID
    let prompt: PromptContent
    let action: StepAction
    let highlightSectionID: String?
    // 不再有 route、suppressDetailInterrupt（被规则表 signal 字段取代）、
    // 不再有 v3.0 那个 followUp 结构体字段——"需要多问一轮"现在是 RouteTarget 的
    // 一个正规 case（.stepWithFollowUp，见五、5.5），不是 Step 自己携带的逻辑
}

struct LearningStepSequence {
    let orderedStepIDs: [StepID]
    let steps: [StepID: Step]
    let nonThresholdStepIDs: Set<StepID>
}

/// v4.1：补上 settings 参数（v4.0 遗漏）。具体 CardType 组装物理槽位链时，
/// 可能需要依据全局设置决定某些 Step 是否存在（如单词型的 Step3 是否编入，
/// 取决于 definitionTestMode），这是"槽位链的物理结构"层面的一次性判断，
/// 不是路由逻辑，因此仍然是 Factory 的职责，不是规则表的职责。
protocol LearningStepFactory {
    func buildSequence(for cardType: CardType, settings: AppSettings) -> LearningStepSequence
}
```

### 6.3 LearningEngine：调度器本身（process 方法查表驱动，支持 stepWithFollowUp）

```swift
final class LearningEngine {
    private weak var unit: Unit?

    /// v4.2 新增：本轮学习会话已学完的卡片数量。随 LearningEngine 实例的生命周期存在——
    /// 引擎实例本身是 @Transient lazy var（见四、Unit），一次"点击学习按钮进入学习界面"
    /// 到"离开学习界面"之间是同一个引擎实例、同一次会话，这个计数天然地只在这次会话内累积，
    /// 不需要额外持久化：如果学习中途被系统杀掉，重新进入学习会开启新的 LearningEngine 实例，
    /// 计数从 0 重新开始，相当于新的一轮——这是可接受的行为，好过为了保留半轮计数
    /// 而增加一份持久化状态的复杂度。
    private var completedInSession: Int = 0

    init(unit: Unit) {
        self.unit = unit
    }

    /// v4.1：step()/process() 改为对 RouteTable 关联类型使用泛型约束（而不是 any LearningRouteTable
    /// 存在型），因为 process 内部需要直接 switch RouteTarget<FinishedPayload> 的 case，
    /// 存在型会丢失这个具体类型信息，泛型能保留。调用方在实例化时传入具体的 RouteTable 实现
    /// （如 WordCardLearningRouteTable），编译期就能确定 FinishedPayload 具体是什么类型。
    ///
    /// v4.2：学完一张卡（.finished 分支）后检查是否达到本轮学习目标，达标则返回
    /// `.sessionGoalReached`，调用方（UI层）据此结束本轮会话、展示汇总页，
    /// 不再继续调用 step()。这个检查放在"学完一张卡之后"这个时间点，不会在半路打断
    /// 一张正在进行中的卡——因为只有 .finished 分支才会做这个判断，卡片答错排队、
    /// 推进到下一个 Step 都不受影响，可以正常继续。
    func step<Table: LearningRouteTable>(factory: any LearningStepFactory, settings: AppSettings,
                                          ruleTable: Table, on renderer: StepRenderer) async -> LearningStepResult {
        guard let unit else { return .chainEmpty }

        let sequence = factory.buildSequence(for: unit.cardType, settings: settings)
        if unit.learningSlots.orderedStepIDs.isEmpty {
            unit.learningSlots.orderedStepIDs = sequence.orderedStepIDs
            unit.learningSlots.nonThresholdStepIDs = sequence.nonThresholdStepIDs
        }

        var loopGuard = 0
        while loopGuard < unit.learningSlots.orderedStepIDs.count {
            loopGuard += 1

            let stepID = unit.learningSlots.currentStepID
            let slot = unit.learningSlots.slots[stepID] ?? StepSlot(stepID: stepID)

            guard shouldProcess(slot: slot, stepID: stepID, nonThresholdStepIDs: unit.learningSlots.nonThresholdStepIDs),
                  let cardID = slot.peekFirst() else {
                unit.learningSlots.advancePointer()
                continue
            }

            let result = await process(cardID: cardID, stepID: stepID, sequence: sequence,
                                        ruleTable: ruleTable, unit: unit, renderer: renderer, settings: settings)

            if case .cardCompleted = result {
                completedInSession += 1
                let goal = unit.resolvedLearningGoal(settings: settings)
                if completedInSession >= goal {
                    return .sessionGoalReached(completedCount: completedInSession, cardID: extractCardID(from: result))
                }
            }
            return result
        }

        return .chainEmpty
    }

    /// 会话结束（用户点"返回本子首页"或本身正常收尾）时调用，重置计数，
    /// 供"再学一轮"或下次重新进入学习界面时重新开始计数
    func resetSessionCount() {
        completedInSession = 0
    }

    private func extractCardID(from result: LearningStepResult) -> UUID {
        guard case .cardCompleted(let cardID) = result else {
            fatalError("extractCardID 只应在 result 是 .cardCompleted 时被调用")
        }
        return cardID
    }

    private func process<Table: LearningRouteTable>(cardID: UUID, stepID: StepID, sequence: LearningStepSequence,
                                                      ruleTable: Table, unit: Unit, renderer: StepRenderer, settings: AppSettings) async -> LearningStepResult {
        guard let card = fetchCard(id: cardID, unit: unit) else {
            unit.learningSlots.slots[stepID]?.remove(cardID)
            return .chainEmpty
        }
        guard let step = sequence.steps[stepID] else { fatalError("槽位物理顺序里的 StepID 没有对应的 Step 定义") }
        guard var progress = fetchLearningProgress(cardID: cardID) else {
            fatalError("正在学习中的卡必须有对应的 LearningProgress，数据不一致")
        }

        // 判定 + 查表，支持 stepWithFollowUp 的连续查表（见 resolveWithFollowUp）
        let (resolved, updatedProgress) = await resolveWithFollowUp(
            step: step, stepID: stepID, progress: progress, ruleTable: ruleTable, renderer: renderer, settings: settings
        )
        progress = updatedProgress

        switch resolved.target {
        case .finished(let payload):
            // v4.1：FinishedPayload 现在约束为 FSRSRatingConvertible（见二、五、5.7），
            // 直接调用 .fsrsRating 拿到 FSRSRating，编译期保证类型安全，
            // 不再需要运行时强转（取代了此前的 `payload as! FSRSRating` 写法）。
            FSRSEngine.initialize(&card.fsrs, rating: payload.fsrsRating)
            unit.learningSlots.removeCompletedCard(cardID, from: stepID)
            card.originQueue = nil
            clearLearningProgress(cardID: cardID)
            unit.learningSlots.advancePointer()
            return .cardCompleted(cardID: cardID)

        case .step(let targetStepID):
            await presentSignal(resolved.signal, card: card, step: step, renderer: renderer)

            unit.learningSlots.moveCard(cardID, from: stepID, to: targetStepID)
            progress.currentStepID = targetStepID
            saveLearningProgress(progress)
            unit.learningSlots.advancePointer()

            return resolved.signal == .none
                ? .cardAdvanced(cardID: cardID, from: stepID, to: targetStepID)
                : .cardFailed(cardID: cardID, atStep: targetStepID)

        case .stepWithFollowUp:
            // resolveWithFollowUp 内部已经把这种情况处理掉、递归查到了真正的终态结果，
            // 正常流程不应该在这里再看到这个 case——出现即视为规则表设计错误
            fatalError("stepWithFollowUp 应已被 resolveWithFollowUp 消化，不应该到达这里")
        }
    }

    /// v4.1：处理"判定→查表→如果是stepWithFollowUp则再问一轮→再查表"的完整循环。
    /// 因为 RouteTarget<FinishedPayload> 现在是真正的泛型类型（不是 Any），
    /// 这里可以直接 switch，不再需要额外的协议或提取方法。
    /// 递归深度理论上应该很浅（目前唯一用例 Step0 只需要一轮 followUp），
    /// 但仍加一个保护上限，避免规则表设计错误导致无限循环。
    private func resolveWithFollowUp<Table: LearningRouteTable>(
        step: Step, stepID: StepID, progress: LearningProgress, ruleTable: Table, renderer: StepRenderer, settings: AppSettings, depth: Int = 0
    ) async -> (resolved: (target: RouteTarget<Table.FinishedPayload>, signal: FailureSignal), progress: LearningProgress) {
        guard depth < 5 else { fatalError("stepWithFollowUp 递归层数异常，规则表可能存在设计错误") }

        let input = await renderer.present(step)
        let result = EngineJudge.evaluate(action: step.action, input: input)
        let outcomeKey = ruleTable.outcomeKey(from: result)

        // v4.3：resolve 补上 settings 参数（见五、5.7 说明），这里的 settings
        // 是 process(...) 已经持有的同一份，顺手往下传，不引入新的依赖来源。
        guard let resolved = ruleTable.resolve(step: stepID, outcome: outcomeKey, progress: progress, settings: settings) else {
            fatalError("规则表未能匹配到任何行，说明该 CardType 的规则表存在遗漏，需要补充")
        }
        let updatedProgress = ruleTable.updateProgress(progress, step: stepID, outcome: outcomeKey)

        if case .stepWithFollowUp(let followUpStep) = resolved.target {
            return await resolveWithFollowUp(step: followUpStep, stepID: stepID, progress: updatedProgress,
                                              ruleTable: ruleTable, renderer: renderer, depth: depth + 1)
        }

        return (resolved, updatedProgress)
    }

    private func presentSignal(_ signal: FailureSignal, card: any Card, step: Step, renderer: StepRenderer) async {
        switch signal {
        case .none:
            break
        case .lightHint:
            await renderer.presentLightweightFailureHint()
        case .detailPage:
            let detail = card.fullDetailContent()
            await renderer.presentDetailInterrupt(detail, highlight: step.highlightSectionID)
        }
    }

    private func fetchCard(id: UUID, unit: Unit) -> (any Card)? {
        fatalError("依赖 SwiftData ModelContext 查询，此处留空")
    }
    private func fetchLearningProgress(cardID: UUID) -> LearningProgress? {
        fatalError("依赖具体持久化实现查询，此处留空")
    }
    private func saveLearningProgress(_ progress: LearningProgress) {
        fatalError("依赖具体持久化实现写入，此处留空")
    }
    private func clearLearningProgress(cardID: UUID) {
        fatalError("依赖具体持久化实现删除，此处留空")
    }
}

enum LearningStepResult {
    case cardAdvanced(cardID: UUID, from: StepID, to: StepID)
    case cardCompleted(cardID: UUID)
    case cardFailed(cardID: UUID, atStep: StepID)
    case chainEmpty
    /// v4.2 新增：本轮已学完卡片数达到 Unit 的学习目标。这张卡本身已经正常学完
    /// （cardID 是这张卡的 id），调用方收到这个结果后应结束本轮学习会话、
    /// 展示汇总页（见设计文档 6.3.1），不应再调用 step() 继续取下一张卡，
    /// 除非用户主动选择"再学一轮"（那种情况下调用方自己决定何时再次调用 step()，
    /// 引擎侧只需要在那之前调用一次 resetSessionCount()）。
    case sessionGoalReached(completedCount: Int, cardID: UUID)
}
```

---

## 七、复习流程：ReviewEngine（调度节奏不变，路由判断改为查表）

```swift
final class ReviewEngine {
    private weak var unit: Unit?

    init(unit: Unit) {
        self.unit = unit
    }

    /// v4.1：与 LearningEngine.step 同理，改为对 Table: ReviewRouteTable 使用泛型约束
    /// （而不是 any ReviewRouteTable 存在型），因为需要保留 Table.FinishedPayload
    /// 的具体类型信息，才能在 .finished 分支里安全调用 .fsrsRating。
    // v4.3：补上 settings 参数，与 LearningEngine.step(factory:settings:...) 对齐
    // （见五、5.7 resolve 协议签名订正说明）。
    func run<Table: ReviewRouteTable>(card: any Card, factory: any ReviewStepFactory,
                                       ruleTable: Table, on renderer: StepRenderer, settings: AppSettings) async {
        guard let unit else { return }

        // v4.1 修正：不再无条件 new 一个 session——先尝试读取这张卡是否已有一份
        // 未完成的 ReviewSession（说明上次会话被中断过），有则从中断处继续；
        // 没有则视为全新的复习会话，从 startStepID 开始并立即写盘，
        // 确保接下来哪怕第一步就被中断，也已经有一份可恢复的记录。
        var session = fetchReviewSession(cardID: card.id)
            ?? ReviewSession(cardID: card.id, currentStepID: factory.startStepID(for: unit.cardType))
        saveReviewSession(session)

        while true {
            let step = factory.buildStep(id: session.currentStepID, for: unit.cardType)

            let (resolved, updatedSession) = await resolveWithFollowUp(
                step: step, stepID: session.currentStepID, session: session,
                ruleTable: ruleTable, factory: factory, renderer: renderer, settings: settings
            )
            session = updatedSession

            switch resolved.target {
            case .finished(let payload):
                await presentSignal(resolved.signal, card: card, step: step, renderer: renderer)
                FSRSEngine.update(&card.fsrs, rating: payload.fsrsRating)   // 见二 FSRSRatingConvertible
                card.postFSRSUpdateHook(context: session)
                unit.removeFromReview(card)
                clearReviewSession(cardID: card.id)   // 正常完成，清除持久化的 session
                return

            case .step(let nextStepID):
                await presentSignal(resolved.signal, card: card, step: step, renderer: renderer)
                session.currentStepID = nextStepID
                saveReviewSession(session)   // 每次推进到下一步都写盘，确保中断后能从这一步续上

            case .transferToFullRelearn:
                await presentSignal(resolved.signal, card: card, step: step, renderer: renderer)
                transitionToFullRelearn(card: card, unit: unit, session: session)
                clearReviewSession(cardID: card.id)   // 已移交给学习引擎，复习会话本身结束，清除
                return

            case .stepWithFollowUp:
                // resolveWithFollowUp 内部已消化，正常流程不应该在这里再看到这个 case
                fatalError("stepWithFollowUp 应已被 resolveWithFollowUp 消化，不应该到达这里")
            }
        }
    }

    /// 与 LearningEngine.resolveWithFollowUp（六、6.3）同构：处理"判定→查表→如果是
    /// stepWithFollowUp则再问一轮→再查表"的完整循环。单词型复习流程目前唯一的用例是
    /// "认识（即时）→ 确认页"（见 husk-word-card-code.md 四、4.3），递归深度同样很浅，
    /// 加同样的保护上限防止规则表设计错误导致无限循环。
    private func resolveWithFollowUp<Table: ReviewRouteTable>(
        step: Step, stepID: StepID, session: ReviewSession, ruleTable: Table,
        factory: any ReviewStepFactory, renderer: StepRenderer, settings: AppSettings, depth: Int = 0
    ) async -> (resolved: (target: ReviewRouteTarget<Table.FinishedPayload>, signal: FailureSignal), session: ReviewSession) {
        guard depth < 5 else { fatalError("stepWithFollowUp 递归层数异常，规则表可能存在设计错误") }

        let input = await renderer.present(step)
        let result = EngineJudge.evaluate(action: step.action, input: input)
        let outcomeKey = ruleTable.outcomeKey(from: result)

        // v4.3：resolve 补上 settings 参数（架构代码文档五、5.7 说明），
        // 与 LearningEngine 侧同构（六、6.3）。
        guard let resolved = ruleTable.resolve(step: stepID, outcome: outcomeKey, session: session, settings: settings) else {
            fatalError("规则表未能匹配到任何行，说明该 CardType 的复习规则表存在遗漏")
        }
        let updatedSession = ruleTable.updateSession(session, step: stepID, outcome: outcomeKey)

        if case .stepWithFollowUp(let followUpStep) = resolved.target {
            return await resolveWithFollowUp(step: followUpStep, stepID: stepID, session: updatedSession,
                                              ruleTable: ruleTable, factory: factory, renderer: renderer, depth: depth + 1)
        }

        return (resolved, updatedSession)
    }

    private func presentSignal(_ signal: FailureSignal, card: any Card, step: Step, renderer: StepRenderer) async {
        switch signal {
        case .none: break
        case .lightHint: await renderer.presentLightweightFailureHint()
        case .detailPage:
            let detail = card.fullDetailContent()
            await renderer.presentDetailInterrupt(detail, highlight: step.highlightSectionID)
        }
    }

    private func fetchReviewSession(cardID: UUID) -> ReviewSession? {
        fatalError("依赖具体持久化实现查询，此处留空，与 fetchLearningProgress 用同一套持久化机制")
    }
    private func saveReviewSession(_ session: ReviewSession) {
        fatalError("依赖具体持久化实现写入，此处留空")
    }
    private func clearReviewSession(cardID: UUID) {
        fatalError("依赖具体持久化实现删除，此处留空")
    }
}
```

**写盘时机的选择**：每次成功推进到下一个 Step（`.step` 分支）就写一次盘，而不是等到整个复习会话结束才写——理由是复习流程只有两步（自测→拼写），写盘开销可以忽略，选择"更频繁、更安全"而不是"更少 I/O 但中断粒度更粗"。这跟 `LearningProgress` 的写盘策略（六、6.3 的 `process` 方法里，每次 `.step`/`.finished` 分支都会调用 `saveLearningProgress`）保持一致的原则。

**中断后的恢复体验**：本文档选择"无感恢复"——重新打开这张卡的复习时，`fetchReviewSession` 若查到未清除的记录，直接从 `currentStepID` 指示的那一步继续，不会额外弹出"是否继续上次复习"之类的确认对话框。这是因为复习会话很短（两步）、中断到恢复之间的用户心智负担很低，主动询问反而增加了不必要的交互成本；如果编码阶段发现这个假设不成立（比如实际体验下来用户会困惑"怎么直接跳到了拼写测试"），可以在渲染层加一个不打断流程的提示，不需要改动这里的引擎逻辑。

**v4.0 变化**：`ReviewEngine` 不再持有 `stateKeyPath: ReferenceWritableKeyPath<Unit, EngineState>`——运行时状态现在是方法内的局部变量 `session: ReviewSession`，而不是挂在 `Unit` 上的一份持久化状态。这带来一个需要在编码阶段确认的取舍：**如果复习会话在中途被中断（切后台、关App），局部变量 `session` 会丢失**，之前 v1.0-v3.0 的 `EngineState` 是持久化的，能在中断后恢复。v4.0 的 `ReviewSession` 虽然类型定义上标了 `Codable`（三、3.2），但上面这段 `run` 方法的示例代码并没有在每次循环时把它写盘、也没有在方法开头尝试恢复一个已存在的 session——这是本文档遗留的一个需要修正的实现细节，见十一。

---

## 八、完整重学：从复习流程移交给学习引擎

```swift
func transitionToFullRelearn(card: any Card, unit: Unit, session: ReviewSession, entryStepID: StepID) {
    unit.removeFromReview(card)
    card.originQueue = .fullRelearn
    unit.learningSlots.enqueueFullRelearn(card.id, atStepID: entryStepID)

    let progress = LearningProgress(cardID: card.id, currentStepID: entryStepID)
    saveLearningProgress(progress)   // 具体持久化实现见六、6.3 的占位说明
}
```

---

## 九、随手记捕获（与 v1.0 相同）

## 十、渲染层接口

```swift
protocol StepRenderer {
    func present(_ step: Step) async -> ActionInput
    func presentDetailInterrupt(_ detail: DetailContent, highlight: String?) async
    func presentLightweightFailureHint() async
}

enum ReviewPrompt {
    case audio(phonetic: String, audioPath: String?)
    case contextCloze(String)
    case custom(CardType, payload: [String: Any])
}
```

## 十一、AppSettings

与 v1.0 基本相同，v4.2 新增一个字段：

```swift
extension AppSettings {
    /// 单次学习目标的全局默认值。Unit 若未单独设置 dailyLearningGoal，
    /// resolvedLearningGoal(settings:)（见四、Unit）会回退到这个值。
    /// 具体默认数值（如 10）留给编码阶段结合实际测试的学习节奏确定，
    /// 本文档不作硬性规定。
    var defaultDailyLearningGoal: Int { /* 具体存取实现见 AppSettings 完整定义，此处仅示意新增字段 */ fatalError() }
}
```

## 十二、删除 Unit：级联删除 + 前置确认

```swift
enum UnitDeletion {
    static func requestDeletion(for unit: Unit) -> DeletionConfirmation {
        DeletionConfirmation(
            unitName: unit.name,
            cardCount: unit.learningSlots.totalCardCount + unit.reviewQueue.count
        )
    }

    static func confirmDeletion(for unit: Unit, context: ModelContext) {
        context.delete(unit)
    }
}

struct DeletionConfirmation {
    let unitName: String
    let cardCount: Int
}
```

---

## 十三、单次学习目标（会话调用方视角）

对应设计文档 6.3.1。本节说明 UI 层应该如何驱动 `LearningEngine.step`，配合十四的 `sessionGoalReached` 结果。

```swift
/// 示意性伪代码，展示调用方（ViewModel/View 层）如何驱动一轮学习会话，
/// 不是本文档其余部分那种"接口签名"粒度，仅用于说明调用节奏。
func runLearningSession(unit: Unit, factory: any LearningStepFactory, settings: AppSettings,
                         ruleTable: some LearningRouteTable, renderer: StepRenderer) async {
    while true {
        let result = await unit.learningEngine.step(factory: factory, settings: settings,
                                                       ruleTable: ruleTable, on: renderer)
        switch result {
        case .chainEmpty:
            // 待学队列已耗尽（本身就没到目标数量），正常结束，无需汇总页的"达标"措辞，
            // 可以复用同一个汇总页组件，只是文案上"已学 N 个"里 N 小于目标值
            return
        case .sessionGoalReached(let completedCount, _):
            // 展示汇总页（设计文档 6.3.1），等待用户选择"返回首页"或"再学一轮"。
            // 若选择"再学一轮"，调用方在再次进入循环前调用一次
            // unit.learningEngine.resetSessionCount()，计数清零重新开始。
            return
        case .cardAdvanced, .cardCompleted, .cardFailed:
            continue   // 正常推进，继续下一次 step() 调用
        }
    }
}
```

**关键点**：`step()` 本身仍然是"处理一次交互"的粒度，不知道"这一轮学习会话"的存在——目标达成的判断被封装在 `LearningEngine` 内部的 `completedInSession` 计数里，`step()` 的返回值只是多了一种可能性（`.sessionGoalReached`），调用方据此决定要不要继续循环调用，职责边界依然清楚：引擎管"一步怎么处理"，调用方（UI层）管"什么时候该停、要不要开始新一轮"。

---

## 十四、本文档遗留的实现细节（需要在编码阶段敲定）

按重要程度排序：

1. **`assertNoRouteRuleConflicts` 的具体比对算法**：五、5.2 只给了函数签名和调用时机，具体"如何判断两行条件互不矛盾"的算法留空，需要编码阶段实现。
2. **`fetchCard`/`fetchLearningProgress`/`saveLearningProgress`/`clearLearningProgress`/`fetchReviewSession`/`saveReviewSession`/`clearReviewSession` 的具体实现**：均依赖 SwiftData 或其他持久化方案，本文档留空。
3. **`any LearningTypeContext`/`any ReviewTypeContext` 的 `Codable` 落地**：与历次遗留问题相同，需要手写编解码 + 类型 tag 注册表。
4. **`LearningEngine.step()`/`ReviewEngine.run()` 的调用节奏**：UI 层自行决定何时调用。**遗留一个缺口**：十三节给出了 `runLearningSession` 作为 `LearningEngine.step` 的调用方示意，但 `ReviewEngine.run` 目前没有对应的 `runReviewSession` 级别示意代码——本次给 `run` 补上 `settings` 参数后，这个缺失的调用方示意就成了唯一一处"`settings` 从哪里传进来"没有落地的地方。编码阶段需要照着 `runLearningSession` 的样子补一份 `runReviewSession`（或等价的调用方逻辑），确保 `settings` 有真实来源，而不是让 `run` 的 `settings` 参数变成一个没人真正传值的签名。
5. **`AppSettings.defaultDailyLearningGoal` 的具体默认数值**：v4.2 只定义了字段存在，没有规定默认值该是多少（比如 10 或其他），需要结合实际学习节奏测试后确定，属于产品参数调优而非架构决策。

**v4.0 遗留、已在 v4.1 解决的问题**（记录于此，避免以后误查旧版本文档产生困惑）：
- ~~`Step.action` 如何表达"复合交互"~~ → 改为不扩展 `StepAction`，用泛型 `RouteTarget<FinishedPayload>.stepWithFollowUp` 表达（见五、5.5）
- ~~`LearningStepFactory.buildSequence` 缺少 `settings` 参数~~ → 已补上（见六、6.2）
- ~~检查页勾选结果如何转换成规则表可查的 outcome~~ → 明确为 `LearningRouteTable.outcomeKey(from:)` 的职责，由各 CardType 自己实现这个转换（见五、5.7）
- ~~`FollowUpExtractable` 协议未定义~~ → 不再需要这个协议：`RouteTarget<FinishedPayload>` 改为架构层统一提供的泛型类型（不是每个 CardType 各自定义结构相同的枚举），`.stepWithFollowUp` 是所有 CardType 共用的同一个 case，引擎可以直接 `switch` 识别，不需要跨类型识别机制（见五、5.5、六、6.3）
- ~~`ReviewSession` 的持久化时机没有在 `ReviewEngine.run` 里落实~~ → 已补上：会话开始时先尝试 `fetchReviewSession` 恢复，每次推进到下一步就 `saveReviewSession` 写盘，正常结束或转入完整重学时 `clearReviewSession` 清除（见七）
- ~~`FSRSEngine.initialize`/`.update` 需要 `payload as! FSRSRating` 强转~~ → 给 `LearningRouteTable`/`ReviewRouteTable` 的 `FinishedPayload` 关联类型加上 `FSRSRatingConvertible` 协议约束（见二），编译期即可保证拿到 `FSRSRating`，`process`/`run` 直接调用 `.fsrsRating`，不再需要运行时强转（见二、五、5.7、六、6.3、七）
