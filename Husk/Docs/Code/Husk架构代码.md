# Husk 记忆架构 · 代码文档

> 版本：v4.9 · 日期：2026-11-07
> 配套设计文档：husk-architecture-design.md（决策理由见该文档，尤其第九、十节）
> 本文档只含接口/协议/类定义，具体某个 CardType 的图内容见各类型自己的代码文档
> 本文档粒度：类型/结构定义用 Swift；算法、逻辑、行为一律用自然语言规格（做什么、输入、输出、注意事项），不含可执行函数体。
>
> **v4.9 变更**（补全 v4.8 遗留的 `ReviewStepFactory` 声明缺口，并把 `masteredStabilityThreshold` 与 `FSRSEngine` 的 `factor`/`decay` 常量落实为真正共享定义，均不改变任何已确定的产品行为）：
> 1. **`ReviewStepFactory` 协议补全定义**（七、7.0）：`ReviewEngine.run`/`resolveWithFollowUp` 一直使用 `any ReviewStepFactory`，但协议本身从未声明——`LearningStepFactory`（六）有对应声明，其复习侧版本被漏掉了。根据 `WordCardReviewStepFactory`（单词Card代码文档五）的实际实现（`startStepID(for:)`/`buildStep(id:for:)`）补全，与 `LearningStepFactory` 结构对称。
> 2. **`FSRSEngine.decay`/`stabilityAnchorRetention`/`factor` 从 `private` 提升为 `internal static let`**（二）：编码阶段已这样做（`Husk/Core/FSRS/FSRSEngine.swift`），`Unit.masteredStabilityThreshold`（四）同步改为直接引用这三个常量，不再维护一份数值相同的独立字面量——解决 v4.8 文档遗留清单（原十四节第 7 条）。
>
> **v4.8 变更**（desiredRetention 相关的一轮一致性修正与命名澄清，均不改变已确定的产品行为，`forgetRate` 曲线统一除外——这一点是本次唯一的行为变化，理由见下）：
> - **文档写法**：去掉可执行函数体，规格改为自然语言（不改变 v4.8 行为）。
> 1. **`forgetRate` 从 decay=-1 的旧曲线统一为 FSRS-5 的 decay=-0.5 曲线**（二）：此前 `forgetRate` 与 `nextInterval` 用了两条不同的遗忘曲线（分别是 `(1+t/9S)^-1` 和 FSRS-5 的 `(1+F·t/S)^-0.5`），只在设计早期占位，本次正式统一成同一条曲线的两个方向（`nextInterval` 是反解，`forgetRate` 是正算），避免 retrievability 计算和调度计算基于不同假设。`factor`/`decay` 提升为 `FSRSEngine` 的静态常量供两处共享。
> 2. **`Unit.masteredStabilityThreshold` 公式改为与 `nextInterval` 同源反解**（四）：原公式用的正是上面被替换掉的旧曲线，与实际调度用的曲线不一致，R 偏离默认值 0.90 时阈值有 4%–7% 偏差。现在直接对 `nextInterval` 的公式解 stability，两者恒等自洽。
> 3. **`FSRSEngine.nextInterval` 新增 `desiredRetention` 越界防护**（二）：非法值（0、负数、读盘异常）会使 `pow` 产生 `inf`，进而在 `Int(round(...))` 处 trap 崩溃。加入 clamp 到 `[0.70, 0.99]` 的防线，UI 滑块限制的 80%–97% 之外的异常值不再能击穿到崩溃。
> 4. **`Card.isFullyLearned` 更名为 `Card.isGraduated`**（一）：与 `WordCard.isCompletelyLearned(in:)`（单词卡代码文档）语义完全不同（前者="学习流程已走完、进入长期复习轮转"，后者="stability 已达阈值、一年内不用再复习"）但命名几乎一样，容易混淆误用，予以更名。`isInInbox` 等其余 `Card` extension 计算属性不受影响。
> 5. **新增"到期卡定时入队"机制**（四、七）：此前 `originQueue = nil` 的卡只有 `fsrs.dueDate`，没有任何机制在到期后把它放回 `Unit.reviewQueue`——`requeueToReview` 在全文档中从未被调用。现在明确由一个后台定时任务负责这一步，见七新增小节。
> 6. **补全"用到了却从未声明"的类型**（不改变既有行为）：`AppSettings` 本体（十一，此前只写"与 v1.0 基本相同"）；`StepSlot` / `LearningSlotChain` / `shouldProcess`（六、6.1，此前只写"与 v3.0 相同不重复列出"）；`FSRSEngine` 中 `update`/`initialize` 实际调用但未列入签名的内部辅助（`elapsedDays`、`initDifficulty`、`nextDifficulty`、`recallStability`、`forgetStability`）；`Card` 扩展上的 `isInInbox`。
>
> **v4.6 变更**（补全此前两处"与 v1.0 相同/不重复列出"但从未在正文出现过的空白，均为文档遗漏，不改变既有行为；顺带把 v4.3 引入的"desiredRetention 按 Unit 配置"同步进 FSRSEngine 的调用签名，这属于本次补全过程中发现的真实缺口，非单纯格式修订）：
> 1. **`FSRSState`/`FSRSCardState`/`FSRSParameters`/`FSRSEngine` 补全完整定义**（二）：v1.0 起历次改版只写"与 v1.0 相同，不重复列出"，从未真正出现在文档正文里。
> 2. **`FSRSEngine.initialize`/`.update` 新增 `desiredRetention` 参数**（二）：v4.3 已经把 desired retention 从全局固定值改成按 Unit 配置，但当时只改了 `Unit` 侧（新增字段与计算属性），没有同步更新 `FSRSEngine` 的调用签名——本次补全 v1.0 原文时发现这处不一致，一并修正。六、七两节实际调用处尚未跟进，已记入十四节遗留清单。
> 3. **随手记捕获（九）补全完整定义**：此前这一节只有标题和"与 v1.0 相同"六个字，没有正文，属于文档遗漏，这里补上 v1.0 原文（`QuickCaptureFlow` 三态判断）。
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
> 4. **`RouteTarget` 改为架构层统一提供的泛型类型**（`RouteTarget<FinishedPayload>`），不再让每个 CardType 各自定义结构相同的枚举——这样 `.stepWithFollowUp` 是所有 CardType 共用的同一个 case，引擎可以直接 `switch` 识别，不需要额外的跨类型协议（`FollowUpExtractable` 因此被取消）。复习流程对应有 `ReviewRouteTarget<FinishedPayload>`。
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

    // v4.8 更名（原 isFullyLearned）：这张卡是否已经走完学习流程、进入长期复习轮转。
    // 注意与 WordCard.isCompletelyLearned(in:)（单词卡代码文档）区分——那是完全不同的
    // 概念："stability 已经高到一年内不用再复习"，只在复习了很多次之后才会变 true。
    // 这里的 isGraduated 只是"脱离学习引擎的槽位传送带"，学完那一刻就是 true。
    var isGraduated: Bool { get }

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
```

协议默认实现（架构层统一提供，具体 CardType 可覆盖）：

```swift
extension Card {
    var isInInbox: Bool { source == .quickCapture && !addedToQueue }
}
```

- **`postFSRSUpdateHook(context:)`**：FSRS 状态更新之后的钩子。默认什么都不做。输入是可选的当前 `ReviewSession`（学习流程里可能没有会话上下文）。副作用仅由具体 CardType 覆盖时产生（例如单词型"想到了"次日强制复习）。
- **`isInInbox`**：不在协议要求清单里，由扩展提供。当且仅当 `source == .quickCapture` 且 `addedToQueue == false` 时为真——随手记已捕获、尚未入队。
- **`isGraduated`**：当且仅当 `originQueue == nil` 时为真，表示已走完学习流程、进入长期复习轮转。协议本身声明了这个只读属性，默认实现就是看 `originQueue` 是否为空。

```swift
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

> **本节补全说明**：`FSRSState`/`FSRSCardState`/`FSRSParameters`/`FSRSEngine` 自 v1.0 起历次改版都写"与 v1.0 相同，不重复列出"，从未在当前版本文档正文里出现过完整定义——这是文档遗漏，这里补全，不改变任何既有行为。同时借这次补全，把 v4.3（四、`Unit.desiredRetention`）引入的"目标保留率改为按 Unit 配置"这个变化，同步落实到 `FSRSEngine` 的调用方式上：v1.0 原文里 `requestRetention` 是 `FSRSParameters` 里的固定字段（默认 0.9），v4.3 之后这个值必须来自具体某个 `Unit`，不能再是写死的全局常量，下面的签名已按此调整。

```swift
enum FSRSCardState: Int, Codable {
    case new = 0
    case learning = 1
    case review = 2
    case relearning = 3
}

struct FSRSState: Codable {
    var stability: Double = 0
    var difficulty: Double = 0
    var elapsedDays: Int = 0
    var scheduledDays: Int = 0
    var reps: Int = 0
    var lapses: Int = 0
    var dueDate: Date?
    var lastReview: Date?
    var state: FSRSCardState = .new
    var dueDateOverridden: Bool = false   // 特殊规则触发的调度覆盖标记（如单词型"想到了"次日强制复习）
}

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

/// 论文默认 19 个权重与最大间隔，这两项是全局常量，不随 Unit 变化。
/// requestRetention 不再放在这个类型里——v4.3 起改为每个 Unit 各自的 desiredRetention（四），
/// 调用 nextInterval 时必须显式传入，不能再依赖某个默认值。
struct FSRSParameters {
    var weights: [Double] = [
        0.40255, 1.18385, 3.173, 15.69105,
        7.1949, 0.5345, 1.4604, 0.0046,
        1.54575, 0.1192, 1.01925, 1.9395,
        0.11, 0.29605, 2.2698, 0.2315,
        2.9898, 0.51655, 0.6621
    ]
    var maximumInterval: Int = 36500
}

struct FSRSEngine {
    static let defaultParams = FSRSParameters()

    /// FSRS-5 遗忘曲线的形状参数，`nextInterval`（正向定义 stability）与
    /// `forgetRate`（反向查询 retrievability）共享同一套常量，保证两处基于
    /// 同一条曲线——v4.8 之前 `forgetRate` 曾误用 decay=-1 的旧曲线，
    /// 与 `nextInterval` 的 decay=-0.5 不一致，已统一。
    ///
    /// `stabilityAnchorRetention = 0.9` 是 stability 的**定义锚点**
    /// （"stability = 可提取性衰减到 90% 所需的天数"），与 `Unit.desiredRetention`
    /// 无关，任何情况下都不得替换成 desiredRetention——即使 v4.3 之后 retention
    /// 已经改为按 Unit 配置，这个 0.9 仍然是固定的数学常量。
    /// v4.9：从 `private` 提升为 `internal`，供 `Unit.masteredStabilityThreshold`（四）
    /// 直接引用，不再各自维护一份数值相同的字面量（十四节原第 7 条遗留，已解决）。
    static let decay = -0.5
    static let stabilityAnchorRetention = 0.9
    static let factor = pow(stabilityAnchorRetention, 1.0 / decay) - 1

    /// - Parameter desiredRetention: 调用方必须传入该卡所属 Unit 的 desiredRetention（四），
    ///   v4.3 起这不再有全局默认值——每个 Unit 创建时通过滑块各自设置（80%–97%，默认 90%）。
    static func initialize(_ state: inout FSRSState, rating: FSRSRating, desiredRetention: Double)
    static func update(_ state: inout FSRSState, rating: FSRSRating, desiredRetention: Double)
    private static func nextInterval(stability: Double, desiredRetention: Double) -> Int
    private static func forgetRate(elapsed: Int, stability: Double) -> Double
    private static func elapsedDays(from lastReview: Date?, to now: Date) -> Int
    private static func initDifficulty(rating: FSRSRating) -> Double
    private static func nextDifficulty(difficulty: Double, rating: FSRSRating) -> Double
    private static func recallStability(difficulty: Double, stability: Double, retrievability: Double, rating: FSRSRating) -> Double
    private static func forgetStability(difficulty: Double, stability: Double, retrievability: Double) -> Double
}
```

`FSRSRating` 对 `FSRSRatingConvertible` 的实现：直接返回自身。单词型的 `LearningRouteTable.FinishedPayload` 直接实例化为 `FSRSRating`（见 husk-word-card-code.md），天然满足这个约束。如果未来某个 CardType 学完时需要携带比单纯 Rating 更多的信息（比如连带一些统计元数据），可以定义自己的类型去遵循 `FSRSRatingConvertible`，只要求提供"怎么从这个类型算出一个 FSRSRating"，不强制"这个类型必须就是 FSRSRating 本身"。

### `FSRSEngine.initialize`

- **做什么**：卡片第一次被评分时调用（新卡入库）。此时没有历史 stability/difficulty 可参考，所以直接用第一次评分查表得到初始 stability，用 `initDifficulty` 公式算出初始 difficulty，再据此排出第一个复习日期。学习引擎学完时调用（见六、6.3）。
- **输入**：待写入的 `FSRSState`（inout）、本次学完对应的 `FSRSRating`、该卡所属 Unit 的 `desiredRetention`。
- **输出/副作用**：就地改写 `state`，不另返回值。
  - `stability` 取 `defaultParams.weights[rating.rawValue - 1]`（again/hard/good/easy 对应 `weights[0...3]`）。没有额外的初始 stability 下限。
  - `difficulty` 由 `initDifficulty(rating:)` 算出（公式不在此展开，见下）。
  - `reps = 1`，`lapses = 0`，`lastReview` 为当前时刻，`state = .review`。
  - `scheduledDays` 由刚算出的 `stability` 经 `nextInterval(stability:desiredRetention:)` 得到。
  - `dueDate` 为当前日历日加上 `scheduledDays` 天（`Calendar.current.date(byAdding: .day, ...)`）。
- **注意事项**：调用方必须显式传入 Unit 的 `desiredRetention`，不能依赖全局默认值。

### `FSRSEngine.update`

- **做什么**：卡片已有历史状态时的复习更新。核心思路是"先算这次复习前卡片被记住的概率（retrievability），再根据这次评分把 stability/difficulty 往前推一步"，最后用新的 stability 重新排期。复习引擎学完时调用（见七）。
- **输入**：已有的 `FSRSState`（inout）、本次评分、该卡所属 Unit 的 `desiredRetention`。
- **输出/副作用**：就地改写 `state`。
  1. 用内部辅助 `elapsedDays(from:to:)` 由 `lastReview` 算到当前时刻的经过天数，记为 `elapsed`。retrievability 和"遗忘"都相对这个间隔计算。
  2. `retrievability = forgetRate(elapsed:stability:)`。与 `nextInterval` 共用同一条 FSRS-5 曲线（`decay`/`factor`，见上）；间隔越长、原先的 stability 越低，这个值就越小。
  3. 写入 `elapsedDays = elapsed`；`difficulty = nextDifficulty(d:rating:)`（公式不在此展开）。difficulty 每次复习都会调整，往用户实际感受到的难度方向靠拢。
  4. 若 `rating == .again`：选了"忘记"，走"遗忘后重新建立记忆"的 stability 公式（通常会显著降低 stability）——`stability = forgetStability(...)`，`lapses` 加 1，`state = .relearning`。否则（hard/good/easy）：记住了，用"成功回忆后 stability 如何增长"的公式，评分越高（easy）增长越多，评分越低（hard）增长越保守——`stability = recallStability(...)`，`state = .review`。
  5. `reps` 加 1；`lastReview` 改为当前时刻。
  6. 用更新后的 stability 重新算下一次复习该隔多少天：`scheduledDays = nextInterval(...)`；`dueDate` 为当前日历日加上 `scheduledDays` 天。
  7. `dueDateOverridden` 置为 `false`（这次是正常算法排期，不是特殊规则强制覆盖的日期，所以清掉覆盖标记）。
- **注意事项**：`elapsedDays(from:to:)` 是引擎内部辅助，本文档不展开其日历日算法。

### `FSRSEngine.nextInterval`

- **做什么**：反推：要让"到期那天"的 retrievability 刚好等于 `desiredRetention`，间隔该排多少天。stability 越大、desiredRetention 越低，算出来的间隔越长。
- **输入**：`stability`、`desiredRetention`。
- **输出**：夹紧后的整数天数。
- **公式**（与 `forgetRate` 同一条 FSRS-5 曲线的反解）：
  1. 先把 `desiredRetention` clamp 到 `[0.70, 0.99]`，得到 `clampedRetention`。
  2. `interval = stability × (clampedRetention^(1/decay) - 1) / factor`，其中 `decay`、`factor` 即引擎静态常量（`factor` 由 `stabilityAnchorRetention = 0.9` 算出，底数不是 `desiredRetention`）。
  3. 四舍五入为整数后夹紧到 `[1, defaultParams.maximumInterval]`（`maximumInterval` 默认 36500，即 100 年），避免算出离谱的值。
- **注意事项（v4.8 clamp）**：UI 滑块限制在 80%–97%，但这道防线只护住创建流程；读盘异常或未来别的写入路径仍可能带来非法值（0、负数、>1），会让 `pow` 产生 `inf`，`Int(round(inf))` 在 Swift 里是 trap 而非饱和截断，会直接崩溃。这里 clamp 到比产品滑块范围更宽松的 `[0.70, 0.99]`，只为兜底极端脏数据，不代表放宽产品允许的选择范围。

### `FSRSEngine.forgetRate`

- **做什么**：遗忘曲线：给定"已经过去多久"和"当前 stability"，估计这一刻还记得的概率（retrievability）。
- **输入**：`elapsed`（整数天）、`stability`。
- **输出**：`Double`。`elapsed` 为 0 时结果为 1（刚复习完必然记得）；`elapsed` 相对 stability 越大，结果越接近 0。
- **公式**（v4.8：与 `nextInterval` 同一条 FSRS-5 曲线；此前误用 decay=-1 的旧曲线 `(1+t/9S)^-1`，与调度实际使用的曲线不一致，已统一）：
  - `(1 + factor × elapsed / stability)^decay`
  - `factor`、`decay` 与 `nextInterval` 共享，不得再写一套独立的 `9` 或 `-1`。

### `FSRSEngine.elapsedDays(from:to:)`

- **做什么**：由上次复习时刻算到本次更新时刻，得到 `update` 写入 `elapsedDays`、并交给 `forgetRate` 的经过天数。
- **输入**：`lastReview`（可能为 nil）、当前时刻 `now`。
- **输出**：非负整数天。`lastReview == nil` 时为 0。
- **注意事项**：具体按本地日历日还是墙钟 24 小时计算，留给编码阶段与 `dueDate` 的日历加法对齐；本文档不展开日历算法。

`initDifficulty` / `nextDifficulty` / `recallStability` / `forgetStability`：`initialize`/`update` 会调用它们。公式本身不受本次架构调整影响，参考 https://github.com/open-spaced-repetition/ts-fsrs 翻译实现，具体系数不在此重复展开。

**待编码阶段确认**：`initialize`/`update` 签名新增 `desiredRetention` 参数后，六、6.3 的 `process` 方法与七的 `ReviewEngine.run` 里实际调用 `FSRSEngine.update`/`.initialize` 的地方，需要同步补上"从 `card.unitID` 找到对应 `Unit` 再取 `desiredRetention`"这一步——本文档目前六、七两节的规格描述里这两处调用尚未更新参数列表，属于本次补全遗留的一处待办，建议连同十四节的遗留清单一起处理。

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
/// 具体的写盘时机与恢复流程见七、ReviewEngine.run 的规格。
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

    @Transient lazy var learningEngine: LearningEngine
    @Transient lazy var reviewEngine: ReviewEngine

    init(cardType: CardType, name: String, desiredRetention: Double = 0.90)

    func resolvedLearningGoal(settings: AppSettings) -> Int
    var reviewCount: Int { get }
    var learningCount: Int { get }
    func removeFromReview(_ card: any Card)
    func requeueToReview(_ card: any Card)
    var masteredStabilityThreshold: Double { get }
}
```

- **`init`**：输入 `cardType`、`name`、可选 `desiredRetention`（默认 0.90）。副作用：生成新 `id`（UUID）、写入 `cardType`/`name`、`createdAt` 为当前时刻、`learningSlots` 用 `LearningSlotChain(cardType:)` 建一条空链、把传入的 `desiredRetention` 赋给不可变字段。`icon`/`accentColor`/`dailyLearningGoal` 不在此初始化。引擎字段为 `@Transient lazy`，首次访问时分别构造 `LearningEngine(unit: self)` / `ReviewEngine(unit: self)`。`desiredRetention` 创建后不可修改，合法范围 0.80–0.97，默认 0.90。
- **`resolvedLearningGoal(settings:)`**：解析本 Unit 实际生效的学习目标。若 `dailyLearningGoal` 非 nil 用自己的，否则回退 `settings.defaultDailyLearningGoal`。
- **`reviewCount`**：等于 `reviewQueue.count`。
- **`learningCount`**：等于 `learningSlots.totalCardCount`。
- **`removeFromReview(_:)`**：从 `reviewQueue` 按 `card.id` 全部移除，并把该卡 `originQueue` 置为 `nil`。
- **`requeueToReview(_:)`**：先 `removeFromReview`，再把卡追加到 `reviewQueue` 末尾，并把 `originQueue` 设为 `.review`。**v4.8 补充调用方说明**：此前全文档没有任何地方调用这个方法——一张卡学完学习流程后 `originQueue` 变 `nil`，但从未被真正放回过 `reviewQueue`。v4.8 起明确由后台定时任务 `DueCardScheduler`（七、7.x）负责按 `fsrs.dueDate` 扫描并调用这个方法，不再是一个孤立的、未被使用的工具方法。
- **`masteredStabilityThreshold`**：某张卡在这个 Unit 的 `desiredRetention` 下，stability 达到多少就意味着下一次复习间隔已经自然拉长到约一年（365 天）以后——统一以"间隔 ≥ 365 天"作为跨 Unit 可比的"学完不再复习"判定标准（见架构设计文档十）。retention 越高，需要越高的 stability 才能撑出同样长的间隔，所以这个阈值随 `desiredRetention` 变化，不是固定天数。这是纯计算属性，不持久化、不缓存——`fsrs.stability` 随复习不断变化，每次需要判定时直接现算即可，不存在数据不同步的问题。
  - **v4.8 修正**：原公式用的是 `interval = stability × 9 × (1/R - 1)`（decay=-1 的旧曲线），与 `FSRSEngine.nextInterval` 实际调度用的 decay=-0.5 曲线不一致，R 偏离默认值 0.90 时阈值有 4%–7% 的偏差。现在直接对 `nextInterval` 的公式反解 stability，两者恒等自洽：
    - `nextInterval`：`interval = stability × (R^(1/decay) - 1) / factor`
    - 固定 `interval = 365`，解出 `stability = 365 × factor / (R^(1/decay) - 1)`
  - 其中 `factor`、`decay` 与 `FSRSEngine.nextInterval` 内部使用的完全相同（FSRS-5 曲线，`decay = -0.5`，`factor` 由 stability 定义锚点 0.9 算出）。R = 0.90 时代入得 365，与旧公式在默认值处的结果一致，偏离处不再有偏差。
  - **v4.9**：直接引用 `FSRSEngine.factor`/`FSRSEngine.decay`（二，已从 `private` 提升为 `internal static let`），不再在 `Unit` 侧维护一份数值相同的独立字面量：`365.0 * FSRSEngine.factor / (pow(desiredRetention, 1.0 / FSRSEngine.decay) - 1)`。

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
func resolveRoute<Rule: RouteRuleMatching>(candidates: [Rule]) -> Rule?
```

- **做什么**：在已经筛过的候选规则里选出特异性最高的一行。
- **输入**：`candidates`——调用方应先按 `matchesKey` + `matchesConditions` 滤出合格行，再交给本函数。
- **输出**：特异性最大的那一行；候选为空则为空。
- **注意事项**：真正实现里，取最大值之前必须先做"是否存在并列最高特异性"的检查（见 5.2 的 DEBUG 断言）。单纯取 max 在并列时会静默选其中一个，不能直接依赖它来解决冲突。这里只规定查表核心是"特异性最高者胜"，冲突检测是独立步骤。

### 5.2 冲突检测：DEBUG 断言

同一组"键字段相同"的规则行里，如果存在两行**条件互不矛盾**（存在某种真实状态能同时满足两行各自已填的条件字段）、**特异性相同**、但**结果不同**，这是一处规则冲突——查表时无法确定该用哪一行。这种情况不应该被静默地选一个了事，而应该在 App 启动时的 DEBUG 断言里直接检测出来并 crash，逼迫开发阶段发现并修正。

```swift
/// 在 DEBUG 构建下，App 启动时对每个 CardType 的规则表调用一次，
/// 检测是否存在"同键、同特异性、条件不互斥、结果却不同"的行对。
/// Release 构建不运行这个检查（假设已经在开发阶段修正过），避免运行时开销。
func assertNoRouteRuleConflicts<Rule: RouteRuleMatching>(_ rules: [Rule])
```

- **做什么**：静态检查规则表是否存在冲突行对。
- **输入**：某个 CardType 的完整规则数组。
- **输出/副作用**：DEBUG 构建下若发现冲突则断言失败（开发期 crash）；Release 构建不运行，无运行时开销。
- **判定算法**（编码阶段实现细节，见十四节第 1 条）：按键字段分组；组内两两比较——两行条件"相容"当且仅当每个条件字段要么至少一方是 nil，要么双方非 nil 且值相等（即存在实际状态能同时满足两者）；若再叠加 specificity 相等、但 target/signal 不同，即命中冲突。
- **注意事项**：应在 App 启动时对每个 CardType 的规则表调用一次（例如放在 AppSettings 或规则表本身的静态初始化里触发）。本文档只规定这个检查必须存在、必须仅 DEBUG 运行。

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

`EngineJudge.evaluate(action:input:) -> ActionResult` 是 `StepAction` 判定环节的通用出口——不论具体 CardType，任何一个 Step 答完后，都先经过这一步产出一个 `ActionResult`，再由各 CardType 自己的 `outcomeKey(from:)` 翻译成具体的查表用 outcome。这个类型本身此前只以 `.boolResult`/`.timedAssessmentResult`/`.checklistResult`/`.listeningCheckResult` 等 case 的形式散落在各处分支里出现，从未给出过 enum 本身的声明，这里补上：

```swift
/// EngineJudge.evaluate 的统一返回类型。case 与 StepAction 的具体形式一一对应
/// （见 StepAction 各 case），新增一种 StepAction 形式时需要在这里同步新增一个 case。
enum ActionResult {
    case boolResult(Bool)
    // 用于一次性对/错判定的 Step（如拼写测试、选词题），true=答对。

    case timedAssessmentResult(TimedAssessment)
    // 用于限时自测类 Step（如单词型 Step0），payload 是具体选中的自测档位。
    // TimedAssessment 本体见 husk-word-card-code.md 二、2.3（目前只有单词型使用该四分支自测）。

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
    static func evaluate(action: StepAction, input: ActionInput) -> ActionResult
}
```

**`evaluate` 映射表**（action 与 input 必须成对出现，错配视为编程错误，不是用户作答错误）：

| `StepAction` | `ActionInput` | `ActionResult` |
|---|---|---|
| `.multipleChoice(_, correctIndex)` | `.selectedIndex(i)` | `.boolResult(i == correctIndex)` |
| `.spelling(correct, tolerance)` | `.typedText(text)` | `.boolResult`（见下方拼写比对） |
| `.timedSelfAssessment` | `.timedChoice(choice, elapsedMs)` | `.timedAssessmentResult(choice)`（`elapsedMs` 不参与判定） |
| `.binarySelfAssessment` | `.binaryChoice(choice)` | `.listeningCheckResult(choice)` |
| `.checklistConfirm` | `.checklistSelection(unchecked)` | `.checklistResult(uncheckedItems: unchecked)` |
| 其他组合 | — | 编程错误：UI 层把错误类型的 input 交给了该 action |

拼写比对：

- `.exact`：输入字符串与正确答案完全相等（区分大小写）。
- `.caseInsensitive`：双方都转成小写后再比较是否相等。

**与 8/15 早期草稿的一处命名订正**：早期草稿里 `binarySelfAssessment` 分支产出的是 `.binaryAssessmentResult(ListeningSelfCheck)`，v4.4 正式声明 `ActionResult`（5.4.1）时把这个 case 改名为 `.listeningCheckResult(ListeningSelfCheck)`，语义更贴合"这是 Step6 的听音自测专用结果"。上面映射已按 v4.4 的正式命名书写，不是历史遗留的旧名字。

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

因为所有 CardType 共用同一个泛型 `RouteTarget<FinishedPayload>`，引擎可以直接识别 `.stepWithFollowUp` 这个 case，**不需要任何跨类型识别的协议**（v4.1 早前草稿设想的 `FollowUpExtractable` 协议因此被取消，见十三"已解决问题"记录）。这个机制是通用的，不知道"检查页"这种具体细节——引擎只认"target 是 stepWithFollowUp 就再多问一轮、再查一次表"这条规则，具体触发条件（自测选了想到了）、具体多问的是什么（检查页）完全由单词型自己的规则表决定。

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

v4.0 的引擎规格（六、七节）直接调用了 `ruleTable.resolve(...)`/`ruleTable.outcomeKey(...)` 等方法，但没有给出正式的协议定义，这里补全：

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
/// 复习侧的循环结构本身就是持续推进，直接在循环内展开这次追加交互即可，
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

### 6.1 StepSlot / 槽位处理阈值 / LearningSlotChain（补全，此前只写"与 v3.0 相同不重复列出"）

`StepSlot`、`shouldProcess`、`LearningSlotChain` 自 v1.0 起就被 `Unit.learningSlots` 和六、6.3 的调度规格使用，但历次改版只写"与 v3.0 相同，不重复列出"，从未在当前版本文档正文出现过。这里按本文档其余各处的实际调用补全声明，不改变既有调度行为。

```swift
struct StepSlot {
    let stepID: StepID
    init(stepID: StepID)
    func peekFirst() -> UUID?
    func enqueue(_ cardID: UUID)
    func dequeue() -> UUID?
    func remove(_ cardID: UUID)
    var count: Int { get }
}

struct LearningSlotChain {
    var slots: [StepID: StepSlot]
    var orderedStepIDs: [StepID]
    var nonThresholdStepIDs: Set<StepID>
    var currentStepID: StepID
    var totalCardCount: Int { get }
    init(cardType: CardType)
    func advancePointer()
    func removeCompletedCard(_ cardID: UUID, from stepID: StepID)
    func moveCard(_ cardID: UUID, from: StepID, to: StepID)
    func enqueueFullRelearn(_ cardID: UUID, atStepID: StepID)
}

func shouldProcess(slot: StepSlot, stepID: StepID, nonThresholdStepIDs: Set<StepID>) -> Bool
```

**`StepSlot`**：学习传送带上某一个 Step 位置当前排队的卡片队列。

- **存什么**：该槽位排队中的卡片 ID，先进先出。`stepID` 标明这个槽位对应哪一步。
- **`init(stepID:)`**：建一个空队列。引擎在 `slots[stepID]` 缺失时用 `StepSlot(stepID:)` 视为空槽位。
- **`peekFirst()`**：看队首 ID，不移除；空队列返回 nil。引擎用它判断"这个槽位有没有卡可以处理"。
- **`enqueue` / `dequeue`**：入队、出队。编码阶段可按 Swift 队列惯用法命名，但必须能完成这两类操作。
- **`remove(_:)`**：按 ID 从本槽位移除一张卡（`process` 里 `fetchCard` 失败时会用到）。
- **`count`**：本槽位排队张数，供 `shouldProcess` 的阈值判断使用。

**`LearningSlotChain`**：一个 Unit 的整条学习传送带。

- **`slots`**：每个 StepID 对应的槽位；尚未有卡到达过的 Step 视为空槽位。
- **`orderedStepIDs`**：槽位链的物理顺序，指针沿这个数组移动。**可变**——`LearningStepFactory.buildSequence` 组装出的顺序，在学习会话开始且当前链为空时写入这里。
- **`nonThresholdStepIDs`**：同样来自 `LearningStepSequence`，会话开始时一并写入。标记哪些 Step 是"非空即处理"，其余走默认阈值。
- **`currentStepID`**：指针当前指向的槽位。
- **`totalCardCount`**：链上所有槽位排队中的卡片总数（`Unit.learningCount` 用它）。
- **`init(cardType:)`**：按 CardType 建一条空链（`orderedStepIDs` / `nonThresholdStepIDs` 留空，等会话开始由 Factory 填入）。
- **`advancePointer()`**：把指针移到 `orderedStepIDs` 中的下一个位置；到末尾后回到开头（传送带循环）。
- **`removeCompletedCard(_:from:)`**：把指定卡片从指定 Step 槽位拿掉（学完跳出传送带，见单词卡文档"标熟"）。
- **`moveCard(_:from:to:)`**：把一张卡从当前槽位挪到目标槽位（查表结果为 `.step` 时）。
- **`enqueueFullRelearn(_:atStepID:)`**：完整重学入队——把卡放进指定入口 Step 的槽位（见八）。

**`shouldProcess(slot:stepID:nonThresholdStepIDs:)`**

- **做什么**：指针停在某个槽位时，判断该处理队首，还是直接 `advancePointer()` 跳过。
- **输入**：当前槽位、该槽位的 StepID、本链的非阈值 Step 集合。
- **输出**：布尔值。
- **规则**：若 `stepID` 属于 `nonThresholdStepIDs`，槽位非空就处理（非空即处理）。否则（默认阈值型）槽位张数达到阈值才处理；阈值默认 2，未达标则跳过。阈值是否做成可配置项留给编码阶段。
- **注意事项**：阈值型用来制造间隔，非阈值型（例如流程末端收尾）来一张处理一张。产品动机见架构设计文档。

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

    init(unit: Unit)

    /// v4.1：step()/process() 改为对 RouteTable 关联类型使用泛型约束（而不是 any LearningRouteTable
    /// 存在型），因为 process 内部需要直接识别 RouteTarget<FinishedPayload> 的 case，
    /// 存在型会丢失这个具体类型信息，泛型能保留。调用方在实例化时传入具体的 RouteTable 实现
    /// （如 WordCardLearningRouteTable），编译期就能确定 FinishedPayload 具体是什么类型。
    ///
    /// v4.2：学完一张卡（.finished 分支）后检查是否达到本轮学习目标，达标则返回
    /// `.sessionGoalReached`，调用方（UI层）据此结束本轮会话、展示汇总页，
    /// 不再继续调用 step()。这个检查放在"学完一张卡之后"这个时间点，不会在半路打断
    /// 一张正在进行中的卡——因为只有 .finished 分支才会做这个判断，卡片答错排队、
    /// 推进到下一个 Step 都不受影响，可以正常继续。
    func step<Table: LearningRouteTable>(factory: any LearningStepFactory, settings: AppSettings,
                                          ruleTable: Table, on renderer: StepRenderer) async -> LearningStepResult

    /// 会话结束（用户点"返回本子首页"或本身正常收尾）时调用，重置计数，
    /// 供"再学一轮"或下次重新进入学习界面时重新开始计数
    func resetSessionCount()

    private func extractCardID(from result: LearningStepResult) -> UUID

    private func process<Table: LearningRouteTable>(cardID: UUID, stepID: StepID, sequence: LearningStepSequence,
                                                      ruleTable: Table, unit: Unit, renderer: StepRenderer, settings: AppSettings) async -> LearningStepResult

    /// v4.1：处理"判定→查表→如果是stepWithFollowUp则再问一轮→再查表"的完整循环。
    /// 因为 RouteTarget<FinishedPayload> 现在是真正的泛型类型（不是 Any），
    /// 这里可以直接识别 case，不再需要额外的协议或提取方法。
    /// 递归深度理论上应该很浅（目前唯一用例 Step0 只需要一轮 followUp），
    /// 但仍加一个保护上限，避免规则表设计错误导致无限循环。
    private func resolveWithFollowUp<Table: LearningRouteTable>(
        step: Step, stepID: StepID, progress: LearningProgress, ruleTable: Table, renderer: StepRenderer, settings: AppSettings, depth: Int = 0
    ) async -> (resolved: (target: RouteTarget<Table.FinishedPayload>, signal: FailureSignal), progress: LearningProgress)

    private func presentSignal(_ signal: FailureSignal, card: any Card, step: Step, renderer: StepRenderer) async
    private func fetchCard(id: UUID, unit: Unit) -> (any Card)?
    private func fetchLearningProgress(cardID: UUID) -> LearningProgress?
    private func saveLearningProgress(_ progress: LearningProgress)
    private func clearLearningProgress(cardID: UUID)
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

#### `init(unit:)`

- **做什么**：把引擎绑到某个 Unit（弱引用，避免与 Unit 上的 `@Transient lazy` 引擎字段互相强持有）。
- **输入**：所属 `Unit`。
- **输出/副作用**：`completedInSession` 从 0 开始。

#### `step(factory:settings:ruleTable:on:)`

- **做什么**：处理传送带上"下一次该处理的那一次交互"。不知道"这一轮学习会话"的存在；会话目标只通过返回 `.sessionGoalReached` 通知调用方。
- **输入**：`LearningStepFactory`、`AppSettings`、具体的 `LearningRouteTable` 实现、`StepRenderer`。
- **输出**：一个 `LearningStepResult`。
- **步骤**：
  1. 若 `unit` 已释放，返回 `.chainEmpty`。
  2. 用 `factory.buildSequence(for: unit.cardType, settings:)` 得到物理槽位链模板。
  3. 若当前 `unit.learningSlots.orderedStepIDs` 为空（会话开始且链尚未定型），把模板的 `orderedStepIDs` 与 `nonThresholdStepIDs` 写入链上。
  4. 沿传送带扫描，扫描次数上限为当前 `orderedStepIDs.count`（防止空转死循环）：
     - 取指针所在 `currentStepID` 对应槽位；没有则视为空的 `StepSlot(stepID:)`。
     - 若 `shouldProcess` 为假，或队首没有卡：`advancePointer()`，继续扫下一个槽位。
     - 否则调用 `process(...)` 处理队首那张卡。
     - 若结果是 `.cardCompleted`：`completedInSession` 加 1；用 `unit.resolvedLearningGoal(settings:)` 得到本轮目标；若已学完数 ≥ 目标，返回 `.sessionGoalReached(completedCount:cardID:)`（`cardID` 由 `extractCardID` 从这次 `.cardCompleted` 取出）。未达标则直接把这次 `.cardCompleted` 返回给调用方。
     - 其他结果（推进、失败、空链等）立刻返回，不再继续扫槽位。
  5. 扫完整圈仍没有可处理的卡，返回 `.chainEmpty`。
- **注意事项**：达标检查只发生在"一张卡已经学完"之后，不会打断半路上的卡。`desiredRetention` 不在本方法里使用，学完初始化 FSRS 发生在 `process` 的 `.finished` 分支。

#### `resetSessionCount()`

- **做什么**：把 `completedInSession` 清零。
- **输入**：无。
- **输出/副作用**：仅改内存计数。用户点"再学一轮"或下次重新进入学习界面前，由调用方调用。

#### `extractCardID(from:)`

- **做什么**：从 `.cardCompleted` 结果里取出 `cardID`，供 `.sessionGoalReached` 携带。
- **输入**：必须已经是 `.cardCompleted` 的 `LearningStepResult`。
- **输出**：该卡 UUID。
- **注意事项**：在其他 case 上调用视为编程错误。

#### `process(...)`

- **做什么**：对传送带队首的一张卡，完成"展示 → 判定 → 查表（含 follow-up）→ 按去向改槽位/FSRS/进度"这一整步。
- **输入**：`cardID`、当前槽位 `stepID`、`sequence`、规则表、所属 `unit`、渲染器、`settings`。
- **输出**：`LearningStepResult`。
- **步骤**：
  1. `fetchCard`：找不到这张卡时，从当前槽位移除该 `cardID`，返回 `.chainEmpty`。
  2. 从 `sequence.steps[stepID]` 取 Step 定义；没有对应定义视为编程错误（槽位物理顺序与 Step 表不一致）。
  3. `fetchLearningProgress`：正在学习中的卡必须已有进度；没有视为数据不一致（编程/持久化错误）。
  4. 调用 `resolveWithFollowUp`（传入同一份 `settings`），得到终态 `(target, signal)` 与更新后的 `LearningProgress`。
  5. 按 `target` 分支：
     - **`.finished(payload)`**：用 `payload.fsrsRating`（`FSRSRatingConvertible`，编译期保证，不再 `as! FSRSRating`）和 `unit.desiredRetention` 调用 `FSRSEngine.initialize`（v4.6 起签名含 `desiredRetention`，从卡片所属 unit 读取）；`removeCompletedCard` 从当前槽位拿掉该卡；`card.originQueue = nil`；`clearLearningProgress`；`advancePointer()`；返回 `.cardCompleted`。**本分支不调用 `presentSignal`。**
     - **`.step(targetStepID)`**：先 `presentSignal`；把卡从当前槽位挪到目标槽位（`moveCard`）；`progress.currentStepID = targetStepID` 并 `saveLearningProgress`；`advancePointer()`。若 `signal == .none` 返回 `.cardAdvanced`，否则返回 `.cardFailed(atStep: targetStepID)`。
     - **`.stepWithFollowUp`**：正常流程不应再看到——`resolveWithFollowUp` 内部必须已消化到终态；出现即视为规则表设计错误。
- **注意事项**：`.finished` 使用 `initialize` 而不是 `update`（学习流程首次进入 FSRS）。写盘发生在 `.step` 分支（每次推进都保存进度）；`.finished` 是清除进度而不是再写一份。

#### `resolveWithFollowUp(...)`

- **做什么**：判定 → 查表 → 若是 follow-up 再问一轮再查表，直到得到非 `.stepWithFollowUp` 的终态。
- **输入**：当前展示用的 `Step`、查表用的原 `stepID`（follow-up 再查时仍用原 Step 的 ID，不用 follow-up Step 自己的 id）、当前 `LearningProgress`、规则表、渲染器、`settings`、递归深度（默认 0）。
- **输出**：终态 `(target, signal)` 以及规则表 `updateProgress` 之后的进度。
- **步骤**：
  1. 深度 ≥ 5：视为规则表设计错误（防止无限循环）。目前唯一用例（Step0 一轮检查页）深度很浅。
  2. `renderer.present(step)` 得到 `ActionInput`；`EngineJudge.evaluate` 得到 `ActionResult`；`ruleTable.outcomeKey(from:)` 得到查表用 outcome。
  3. `ruleTable.resolve(step:outcome:progress:settings:)`；匹配不到任何行视为该 CardType 规则表遗漏。
  4. `ruleTable.updateProgress` 得到更新后的进度。
  5. 若 target 是 `.stepWithFollowUp(followUpStep)`：用 `followUpStep` 作为下一步要展示的 Step，**查表键仍是原来的 `stepID`**，进度换成更新后的，深度 +1，递归；递归时必须继续传入同一份 `settings`（是 `process` 已经持有的同一份，不引入新的依赖来源）。
  6. 否则返回当前 resolved 与更新后进度。

#### `presentSignal`

- **做什么**：按规则表给出的失败反馈程度打扰用户（在执行"去向"之前，见 5.6）。
- **输入**：`FailureSignal`、当前卡、当前 Step、渲染器。
- **输出/副作用**：
  - `.none`：什么都不做。
  - `.lightHint`：调用 `renderer.presentLightweightFailureHint()`。
  - `.detailPage`：`card.fullDetailContent()` 后调用 `presentDetailInterrupt`，高亮 `step.highlightSectionID`。

#### `fetchCard` / `fetchLearningProgress` / `saveLearningProgress` / `clearLearningProgress`

- **做什么**：读卡、读/写/删 `LearningProgress`。
- **注意事项**：依赖 SwiftData 或其他持久化方案，本文档留空，见十四节第 2 条。写盘原则：每次 `.step` 推进都保存；学完则清除。

---

## 七、复习流程：ReviewEngine（调度节奏不变，路由判断改为查表）

### 7.0 `ReviewStepFactory`（补全，此前只被引用从未正式声明）

`ReviewEngine.run`/`resolveWithFollowUp`（下方）签名里一直使用 `any ReviewStepFactory`，但协议本身此前从未在文档正文声明过——`LearningStepFactory`（六、6.2）有对应声明，其复习侧版本被漏掉了。根据 `WordCardReviewStepFactory`（husk-word-card-code.md 五）的实际实现（`startStepID(for:)`、`buildStep(id:for:)`）补全，与 `LearningStepFactory` 结构对称：

```swift
/// 复习流程对应 LearningStepFactory 的角色：只负责"给定 CardType，
/// 复习该从哪个 StepID 开始""给定 StepID，组装出对应的 Step"，
/// 不承担任何路由判断（路由统一交给 ReviewRouteRule，见五）。
protocol ReviewStepFactory {
    func startStepID(for cardType: CardType) -> StepID
    func buildStep(id: StepID, for cardType: CardType) -> Step
}
```

- **`startStepID(for:)`**：复习会话第一次创建时（`run` 里 `fetchReviewSession` 查不到记录），用这个方法得到初始 `currentStepID`。
- **`buildStep(id:for:)`**：复习循环每一轮都用当前 `session.currentStepID` 调用这个方法，拿到该展示的具体 `Step`。

```swift
final class ReviewEngine {
    private weak var unit: Unit?

    init(unit: Unit)

    /// v4.1：与 LearningEngine.step 同理，改为对 Table: ReviewRouteTable 使用泛型约束
    /// （而不是 any ReviewRouteTable 存在型），因为需要保留 Table.FinishedPayload
    /// 的具体类型信息，才能在 .finished 分支里安全调用 .fsrsRating。
    // v4.3：补上 settings 参数，与 LearningEngine.step(factory:settings:...) 对齐
    // （见五、5.7 resolve 协议签名订正说明）。
    func run<Table: ReviewRouteTable>(card: any Card, factory: any ReviewStepFactory,
                                       ruleTable: Table, on renderer: StepRenderer, settings: AppSettings) async

    /// 与 LearningEngine.resolveWithFollowUp（六、6.3）同构：处理"判定→查表→如果是
    /// stepWithFollowUp则再问一轮→再查表"的完整循环。单词型复习流程目前唯一的用例是
    /// "认识（即时）→ 确认页"（见 husk-word-card-code.md 四、4.3），递归深度同样很浅，
    /// 加同样的保护上限防止规则表设计错误导致无限循环。
    private func resolveWithFollowUp<Table: ReviewRouteTable>(
        step: Step, stepID: StepID, session: ReviewSession, ruleTable: Table,
        factory: any ReviewStepFactory, renderer: StepRenderer, settings: AppSettings, depth: Int = 0
    ) async -> (resolved: (target: ReviewRouteTarget<Table.FinishedPayload>, signal: FailureSignal), session: ReviewSession)

    private func presentSignal(_ signal: FailureSignal, card: any Card, step: Step, renderer: StepRenderer) async
    private func fetchReviewSession(cardID: UUID) -> ReviewSession?
    private func saveReviewSession(_ session: ReviewSession)
    private func clearReviewSession(cardID: UUID)
}
```

#### `init(unit:)`

- **做什么**：弱引用所属 Unit。
- **输入**：`Unit`。

#### `run(card:factory:ruleTable:on:settings:)`

- **做什么**：对**一张卡**跑完一次复习会话（调度节奏仍是单卡会话内自测→拼写等步骤连续推进，不走学习传送带）。
- **输入**：要复习的卡、`ReviewStepFactory`、具体 `ReviewRouteTable`、渲染器、`AppSettings`。
- **输出/副作用**：会话正常结束或转入完整重学后返回；中途每次推进都写盘。
- **步骤**：
  1. 若 `unit` 已释放，直接返回。
  2. **恢复或新建 session**（v4.1）：先 `fetchReviewSession(cardID:)`；若有未完成记录则从中断处继续；没有则新建 `ReviewSession(cardID:currentStepID:)`，起点为 `factory.startStepID(for: unit.cardType)`。无论新旧，立刻 `saveReviewSession`，确保哪怕第一步就被中断也已有可恢复记录。不要无条件 new。
  3. 循环直到会话结束：
     - 用 `factory.buildStep(id: session.currentStepID, for: unit.cardType)` 得到当前 Step。
     - `resolveWithFollowUp`（传入 `settings`）得到终态与更新后的 session。
     - **`.finished(payload)`**：先 `presentSignal`；用 `payload.fsrsRating` 与 `unit.desiredRetention` 调用 `FSRSEngine.update`（不是 initialize；v4.6 起签名含 `desiredRetention`，从卡片所属 unit 读取）；`card.postFSRSUpdateHook(context: session)`；`unit.removeFromReview(card)`；`clearReviewSession`；结束。
     - **`.step(nextStepID)`**：`presentSignal`；`session.currentStepID = nextStepID`；`saveReviewSession`（每次推进都写盘）；继续循环。
     - **`.transferToFullRelearn`**：`presentSignal`；`transitionToFullRelearn(card:unit:session:entryStepID:)`（入槽步见第八节签名中的 `entryStepID`）；`clearReviewSession`；结束。
     - **`.stepWithFollowUp`**：正常流程不应到达——应已被 `resolveWithFollowUp` 消化；出现即视为编程/规则表错误。
- **注意事项**：复习学完走 `update` 而不是 `initialize`。学习引擎 `.finished` 不展示 signal，复习引擎 `.finished` **要**展示。`desiredRetention` 从卡片所属 `unit` 读取。

#### `resolveWithFollowUp`（复习侧）

- **做什么**：与学习侧同构的"判定→查表→follow-up 再问一轮→再查表"。
- **输入**：当前 Step、查表用的原 `stepID`、当前 `ReviewSession`、规则表、factory、渲染器、`settings`、深度（默认 0）。
- **输出**：终态 `(target, signal)` 与更新后的 session。
- **步骤**：
  1. 深度 ≥ 5：规则表可能存在设计错误。
  2. present → `EngineJudge.evaluate` → `outcomeKey`。
  3. `ruleTable.resolve(step:outcome:session:settings:)`；匹配不到视为该 CardType 复习规则表遗漏。
  4. `ruleTable.updateSession`。
  5. 若 `.stepWithFollowUp(followUpStep)`：用 follow-up Step 再递归，**查表键仍是原来的 `stepID`**，深度 +1，继续传入同一份 `settings`。
  6. 否则返回当前 resolved 与更新后 session。
- **注意事项**：单词型目前唯一用例是"认识（即时）→ 确认页"。

#### `presentSignal`

与学习引擎相同：`.none` 无操作；`.lightHint` 轻提示；`.detailPage` 用 `fullDetailContent` + `highlightSectionID` 打断展示。

#### `fetchReviewSession` / `saveReviewSession` / `clearReviewSession`

依赖具体持久化实现，与 `fetchLearningProgress` 用同一套机制，本文档留空（十四节第 2 条）。

**写盘时机的选择**：每次成功推进到下一个 Step（`.step` 分支）就写一次盘，而不是等到整个复习会话结束才写——理由是复习流程只有两步（自测→拼写），写盘开销可以忽略，选择"更频繁、更安全"而不是"更少 I/O 但中断粒度更粗"。这跟 `LearningProgress` 的写盘策略（六、6.3 的 `process` 方法里，每次 `.step` 分支会调用 `saveLearningProgress`，`.finished` 则清除）保持一致的原则。

**中断后的恢复体验**：本文档选择"无感恢复"——重新打开这张卡的复习时，`fetchReviewSession` 若查到未清除的记录，直接从 `currentStepID` 指示的那一步继续，不会额外弹出"是否继续上次复习"之类的确认对话框。这是因为复习会话很短（两步）、中断到恢复之间的用户心智负担很低，主动询问反而增加了不必要的交互成本；如果编码阶段发现这个假设不成立（比如实际体验下来用户会困惑"怎么直接跳到了拼写测试"），可以在渲染层加一个不打断流程的提示，不需要改动这里的引擎逻辑。

**v4.0 变化**：`ReviewEngine` 不再持有 `stateKeyPath: ReferenceWritableKeyPath<Unit, EngineState>`——运行时状态现在是方法内的 `session: ReviewSession`，而不是挂在 `Unit` 上的一份持久化状态。这带来一个需要在编码阶段确认的取舍：**如果复习会话在中途被中断（切后台、关App），仅作为局部变量的 `session` 会丢失**，之前 v1.0-v3.0 的 `EngineState` 是持久化的，能在中断后恢复。v4.0 的 `ReviewSession` 虽然类型定义上标了 `Codable`（三、3.2），但早期规格曾把它当纯局部变量、没有在每次循环写盘、也没有在方法开头尝试恢复——这是本文档遗留过的一个实现细节。**v4.1 已解决**（见十四节"已解决问题"：会话开始 `fetchReviewSession`，每次 `.step` 写盘，正常结束/转入完整重学时清除）。

### 7.x 到期卡定时入队（v4.8 新增）

**问题**：一张卡学完学习流程后 `card.originQueue = nil`（一），从此只剩 `fsrs.dueDate` 记着"什么时候该复习"，不再挂在任何队列上。`Unit.requeueToReview`（四）负责把卡放回 `reviewQueue`，但此前全文档没有任何地方调用它——`fsrs.dueDate` 到了之后，没有机制真正把卡放进复习队列，`Unit.reviewQueue`/`reviewCount` 会一直卡在旧数字，单词学习设计文档 6.4 要求的"今日新到期的 FSRS 词进入今日复习队列"没有落点。

**方案**：由一个**后台定时任务**负责这一步，不放在引擎的调用路径里（引擎只在用户主动进入学习/复习界面时才运行，不适合承担"随时间推移触发"这种职责）。

```swift
/// v4.8 新增。职责单一：扫描所有 Unit 里"已毕业但到期"的卡，
/// 搬进对应 Unit 的 reviewQueue。不做任何 FSRS 计算、不碰 originQueue==nil
/// 之外的卡——学习流程内的卡（.newCards/.fullRelearn）完全不归这个任务管。
enum DueCardScheduler {
    /// 触发时机：编码阶段确认，候选方案包括 App 进入前台时跑一次、
    /// 或注册一个后台任务（BGTaskScheduler）在系统允许的时机跑。
    /// 两者不互斥，可以都加，谁先触发都行——这个任务是幂等的，
    /// 重复调用不会导致重复入队。
    static func run(units: [Unit], now: Date = .now)

    /// 查询"这个 Unit 下 originQueue == nil 的卡"，具体实现依赖持久化方案
    /// （SwiftData 的话大概率是一条 Predicate 查询）。
    private static func fetchGraduatedCards(unitID: UUID) -> [any Card]
}
```

#### `DueCardScheduler.run(units:now:)`

- **做什么**：扫描所有传入 Unit 里已毕业且到期的卡，调用 `Unit.requeueToReview` 放进复习队列。
- **输入**：当前要扫描的 `units`；`now` 默认当前时刻，便于测试注入。
- **输出/副作用**：对每张命中的卡调用一次 `unit.requeueToReview(card)`；不做 FSRS 计算。
- **步骤**：
  1. 遍历每个 `unit`。
  2. 对该 Unit 调用 `fetchGraduatedCards(unitID:)`，拿到 `originQueue == nil` 的卡。
  3. 对每张卡做防御性确认：`card.isGraduated` 为假则跳过。
  4. 若 `card.fsrs.dueDate` 为空，或 `due > now`，跳过。
  5. 否则 `unit.requeueToReview(card)`。
- **注意事项**：学习流程内的卡（`.newCards` / `.fullRelearn`）完全不归这个任务管。

#### `fetchGraduatedCards(unitID:)`

- **做什么**：查出该 Unit 下已毕业的卡。
- **输入**：`unitID`。
- **输出**：`originQueue == nil` 的卡片列表。
- **注意事项**：不能查询 `unit.reviewQueue ∪ unit.learningSlots` 之外的全集再在内存里过滤，那意味着要把所有卡都载入内存；应该直接按 `originQueue == nil` 查询。依赖具体持久化方案，本文档留空。

**幂等性**：`requeueToReview` 内部先 `removeFromReview` 再 `append`（四），所以同一张卡被重复排查到也不会在 `reviewQueue` 里出现两次，`DueCardScheduler.run` 可以被安全地多次调用（比如用户短时间内多次打开 App），不需要额外加锁或去重逻辑。

**与复习会话的边界**：这个任务只负责"入队"，不负责"出队"。卡片被复习完之后从 `reviewQueue` 移除、`fsrs` 更新出新的 `dueDate`，这部分是 `ReviewEngine.run`（本节前文）的职责，两者不重叠。

**待编码阶段确认**：具体用 `BGAppRefreshTask` 还是简单的"每次 App 进入前台时同步跑一次"，取决于对"卡到期后多久必须出现在复习队列里"的产品要求有多严格——如果用户只在主动打开 Unit 复习页时才关心这个数字，进入前台时跑一次已经够用，不需要引入后台任务调度的复杂度。已记入十四节遗留清单。

---

## 八、完整重学：从复习流程移交给学习引擎

```swift
func transitionToFullRelearn(card: any Card, unit: Unit, session: ReviewSession, entryStepID: StepID)
```

- **做什么**：复习判定需要完整重学时，把这张卡从复习队列交给学习传送带，并建立一份可恢复的 `LearningProgress`。
- **输入**：卡、所属 Unit、当前复习 `session`、入学习链的 `entryStepID`。
- **输出/副作用**（按此顺序）：
  1. `unit.removeFromReview(card)`（卡离开复习队列，`originQueue` 先被置 nil）。
  2. `card.originQueue = .fullRelearn`。
  3. `unit.learningSlots.enqueueFullRelearn(card.id, atStepID: entryStepID)`。
  4. 新建 `LearningProgress(cardID:currentStepID:)`，`currentStepID` 为 `entryStepID`。
  5. `saveLearningProgress`（与六、6.3 同一套持久化）。
- **注意事项**：`session` 本身由调用方在移交后 `clearReviewSession` 清除（见七 `.transferToFullRelearn` 分支）。复习会话到此结束，不再带到学习引擎。

---

## 九、随手记捕获

> **本节补全说明**：此前只写"与 v1.0 相同"，没有正文，是本次查缺补漏一并发现的遗漏，这里补全 v1.0 原文，不改变任何既有行为。

```swift
enum QuickCaptureFlow {
    case promptCreateUnit(cardType: CardType)
    case captureInto(Unit)
    case promptSelectUnit(candidates: [Unit])
}

/// 捕获时归属 Unit 的三态判断（见 husk-architecture-design.md 第四节的理由）：
/// 该类型下没有 Unit → 引导新建；只有一个 → 不弹，直接归入；有多个 → 必须弹出选择，
/// 不做静默的"默认 Unit"兜底。
func quickCapture(cardType: CardType, existingUnits: [Unit]) -> QuickCaptureFlow
```

- **做什么**：决定随手记该归入哪个 Unit（只做归属判断，不创建卡片）。
- **输入**：要捕获的 `cardType`、当前已有的全部 Unit 列表。
- **输出**：三态之一。
  1. 从 `existingUnits` 滤出 `cardType` 相同的集合。
  2. 数量为 0 → `.promptCreateUnit(cardType:)`，引导新建。
  3. 数量为 1 → `.captureInto` 那一个 Unit，不弹窗。
  4. 数量 ≥ 2 → `.promptSelectUnit(candidates:)`，必须让用户选，不做静默默认 Unit。

选定 Unit 后，具体把随手记内容写成一张 `Card` 并标记 `source = .quickCapture`、`isInInbox`（一、`Card` 扩展）为真，属于各 CardType 自己的构造逻辑，本节只覆盖"选哪个 Unit"这一层通用判断。

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

**本节补全说明**：`AppSettings` 自 v1.0 起就作为参数贯穿全文（`resolvedLearningGoal(settings:)`、`LearningRouteTable.resolve(...settings:)`、`ReviewRouteTable.resolve(...settings:)`、`LearningStepFactory.buildSequence(for:settings:)`、`LearningEngine.step(...settings:)`、`ReviewEngine.run(...settings:)` 等），但历次改版只写"与 v1.0 基本相同"，类型本体从未在正文出现。这里补上声明，不改变既有行为。

`AppSettings` 是 App 级用户偏好容器，作为**显式参数**传给需要读设置的方法，不作为各处隐式访问的全局单例。具体存盘方式（`UserDefaults`、SwiftData 单例记录等）留给编码阶段。

```swift
struct AppSettings {
    /// 单次学习目标的全局默认值。Unit 若未单独设置 dailyLearningGoal，
    /// resolvedLearningGoal(settings:)（见四）会回退到这个值。
    /// 具体默认数字（如 10）留给编码阶段结合学习节奏确定，见十四第 5 条。
    var defaultDailyLearningGoal: Int
}
```

架构层本体只放跨 CardType 通用字段（目前仅此一个）。某个 CardType 专属设置（例如单词型的 `definitionTestMode`，见 husk-word-card-code.md 二）用 `extension AppSettings` 补充，不写进这个本体。

**为什么显式传参、不用全局单例**：签名上就能看出"这个方法依赖用户设置"；测试可以构造临时实例传入；单词卡文档曾因假定内部读单例而导致 `resolve` 缺 `settings` 参数，这类遗漏要避免再出现。

## 十二、删除 Unit：级联删除 + 前置确认

```swift
enum UnitDeletion {
    static func requestDeletion(for unit: Unit) -> DeletionConfirmation
    static func confirmDeletion(for unit: Unit, context: ModelContext)
}

struct DeletionConfirmation {
    let unitName: String
    let cardCount: Int
}
```

- **`requestDeletion(for:)`**：为删除确认 UI 准备数据。输入是待删 Unit。输出 `DeletionConfirmation`：`unitName` 为 `unit.name`；`cardCount` 为 `unit.learningSlots.totalCardCount + unit.reviewQueue.count`（学习链上排队的卡 + 复习队列里的卡）。
- **`confirmDeletion(for:context:)`**：用户确认后执行删除。输入是 Unit 与 SwiftData `ModelContext`。副作用：`context.delete(unit)`（级联删除细节留给建模阶段，本节只规定从 context 删除该 Unit）。

---

## 十三、单次学习目标（会话调用方视角）

对应设计文档 6.3.1。本节说明 UI 层应该如何驱动 `LearningEngine.step`，配合十四的 `sessionGoalReached` 结果。

调用方（ViewModel/View 层）驱动一轮学习会话的节奏如下——这是调用节奏说明，不是引擎内部实现。

1. 循环调用 `unit.learningEngine.step(factory:settings:ruleTable:on:)`，每次只处理一次交互。
2. 若返回 **`.chainEmpty`**：待学队列已耗尽（本身就没到目标数量），正常结束。无需汇总页的"达标"措辞；可以复用同一个汇总页组件，只是文案上"已学 N 个"里 N 小于目标值。结束本轮。
3. 若返回 **`.sessionGoalReached(completedCount, _)`**：展示汇总页（设计文档 6.3.1），等待用户选择"返回首页"或"再学一轮"。若选择"再学一轮"，调用方在再次进入循环前调用一次 `unit.learningEngine.resetSessionCount()`，计数清零重新开始。本轮先结束。
4. 若返回 **`.cardAdvanced` / `.cardCompleted` / `.cardFailed`**：正常推进，继续下一次 `step()`。

**关键点**：`step()` 本身仍然是"处理一次交互"的粒度，不知道"这一轮学习会话"的存在——目标达成的判断被封装在 `LearningEngine` 内部的 `completedInSession` 计数里，`step()` 的返回值只是多了一种可能性（`.sessionGoalReached`），调用方据此决定要不要继续循环调用，职责边界依然清楚：引擎管"一步怎么处理"，调用方（UI层）管"什么时候该停、要不要开始新一轮"。

---

## 十四、本文档遗留的实现细节（需要在编码阶段敲定）

按重要程度排序：

1. **`assertNoRouteRuleConflicts` 的具体比对算法**：五、5.2 只给了函数签名和调用时机，具体"如何判断两行条件互不矛盾"的算法留空，需要编码阶段实现。
2. **`fetchCard`/`fetchLearningProgress`/`saveLearningProgress`/`clearLearningProgress`/`fetchReviewSession`/`saveReviewSession`/`clearReviewSession` 的具体实现**：均依赖 SwiftData 或其他持久化方案，本文档留空。
3. **`any LearningTypeContext`/`any ReviewTypeContext` 的 `Codable` 落地**：与历次遗留问题相同，需要手写编解码 + 类型 tag 注册表。
4. **`LearningEngine.step()`/`ReviewEngine.run()` 的调用节奏**：UI 层自行决定何时调用。**遗留一个缺口**：十三节给出了学习会话调用节奏作为 `LearningEngine.step` 的调用方规格描述，但 `ReviewEngine.run` 目前没有对应的 `runReviewSession` 级别规格描述——本次给 `run` 补上 `settings` 参数后，这个缺失的调用方规格就成了唯一一处"`settings` 从哪里传进来"没有落地的地方。编码阶段需要照着学习会话调用节奏补一份 `runReviewSession`（或等价的调用方逻辑），确保 `settings` 有真实来源，而不是让 `run` 的 `settings` 参数变成一个没人真正传值的签名。
5. **`AppSettings.defaultDailyLearningGoal` 的具体默认数值**：v4.2 只定义了字段存在，没有规定默认值该是多少（比如 10 或其他），需要结合实际学习节奏测试后确定，属于产品参数调优而非架构决策。
6. **六、6.3 的 `process` 方法与七、`ReviewEngine.run` 里调用 `FSRSEngine.initialize`/`.update` 的地方，需要补上 `desiredRetention` 参数**：v4.6 给这两个方法的签名加上了 `desiredRetention: Double`（二），但本文档六、七两节规格描述里实际的调用点还是旧签名，需要编码阶段同步改成"先由 `card.unitID` 查到所属 `Unit`，取其 `desiredRetention` 再传入"。
7. **`DueCardScheduler`（七、7.x）的触发时机与持久化查询**：`fetchGraduatedCards` 依赖具体持久化方案实现按 `originQueue == nil` 的查询，本文档留空；触发时机是"App 进入前台时跑一次"还是引入 `BGAppRefreshTask` 之类的后台任务，取决于对到期延迟的产品要求，需要编码阶段结合实际测试确定。
8. **`FSRSEngine.nextInterval` 的 `desiredRetention` clamp 范围 `[0.70, 0.99]`（二）是防御性兜底值，不是产品允许范围**：产品层面仍然只允许 Unit 创建时在 `[0.80, 0.97]` 之间选择（四）。编码阶段如果决定在 `Unit.init` 或解码入口也加一道断言/clamp（比如防止未来某处绕过滑块直接构造 `Unit` 传入非法值），要确认两处范围不要写反或用混，`nextInterval` 那道更宽松的范围只是最后一道防止崩溃的防线。

**v4.0 遗留、已在 v4.1 解决的问题**（记录于此，避免以后误查旧版本文档产生困惑）：
- ~~`Step.action` 如何表达"复合交互"~~ → 改为不扩展 `StepAction`，用泛型 `RouteTarget<FinishedPayload>.stepWithFollowUp` 表达（见五、5.5）
- ~~`LearningStepFactory.buildSequence` 缺少 `settings` 参数~~ → 已补上（见六、6.2）
- ~~检查页勾选结果如何转换成规则表可查的 outcome~~ → 明确为 `LearningRouteTable.outcomeKey(from:)` 的职责，由各 CardType 自己实现这个转换（见五、5.7）
- ~~`FollowUpExtractable` 协议未定义~~ → 不再需要这个协议：`RouteTarget<FinishedPayload>` 改为架构层统一提供的泛型类型（不是每个 CardType 各自定义结构相同的枚举），`.stepWithFollowUp` 是所有 CardType 共用的同一个 case，引擎可以直接 `switch` 识别，不需要跨类型识别机制（见五、5.5、六、6.3）
- ~~`ReviewSession` 的持久化时机没有在 `ReviewEngine.run` 里落实~~ → 已补上：会话开始时先尝试 `fetchReviewSession` 恢复，每次推进到下一步就 `saveReviewSession` 写盘，正常结束或转入完整重学时 `clearReviewSession` 清除（见七）
- ~~`FSRSEngine.initialize`/`.update` 需要 `payload as! FSRSRating` 强转~~ → 给 `LearningRouteTable`/`ReviewRouteTable` 的 `FinishedPayload` 关联类型加上 `FSRSRatingConvertible` 协议约束（见二），编译期即可保证拿到 `FSRSRating`，`process`/`run` 直接调用 `.fsrsRating`，不再需要运行时强转（见二、五、5.7、六、6.3、七）

**v4.8 遗留、已在 v4.9 解决的问题**：
- ~~`Unit.masteredStabilityThreshold`（四）与 `FSRSEngine.nextInterval`（二）里的 `factor`/`decay` 是两份独立字面量~~ → `FSRSEngine.decay`/`stabilityAnchorRetention`/`factor` 从 `private` 提升为 `internal static let`（见二），`masteredStabilityThreshold` 直接引用 `FSRSEngine.factor`/`FSRSEngine.decay`，不再维护独立字面量（见四）
- ~~`ReviewStepFactory` 协议只被引用从未正式声明~~ → 补全声明，与 `LearningStepFactory` 结构对称（见七、7.0）
