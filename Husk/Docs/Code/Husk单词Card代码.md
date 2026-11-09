# Husk 单词学习 · 代码文档

> 版本：v4.7 · 日期：2026-08-24
> 配套设计文档：husk-word-learning-design-v2.md（v1.1，产品逻辑见该文档）
> 依赖：husk-architecture-code.md（v4.9）—— `Card`/`Step`/`LearningProgress`/`ReviewSession`/`LearningRouteRule`/`stepWithFollowUp`/`ReviewRouteTarget.stepWithFollowUp`/`Unit.masteredStabilityThreshold`/`Unit.desiredRetention`/`ActionResult`/`ListeningSelfCheck`/`StepAction`/`EngineJudge`/`FSRSEngine`/`AppSettings`/`ReviewStepFactory` 等协议定义
> 本文档粒度：类型/结构定义用 Swift；算法、逻辑、行为一律用自然语言规格，不含可执行函数体。规则表静态行数据仍用 Swift 字面量列出。
>
> 本次修订只调整文档呈现方式（类型保留字段与签名，算法改为自然语言规格），不改变任何产品逻辑，版本号仍为 v4.7。
>
> **v4.7 变更**（跟进架构代码文档 v4.6：`FSRSEngine.initialize`/`.update` 新增 `desiredRetention` 参数，不改变任何产品逻辑）：
> 1. **四、4.5 `transitionToFullRelearn` 里的 `FSRSEngine.update` 调用**：补上 `desiredRetention: unit.desiredRetention`。
> 2. **五、`handleMarkAsFamiliar` 里的 `FSRSEngine.initialize` 调用**：补上 `desiredRetention: unit.desiredRetention`。
>
> **v4.6 变更**（正式编码前的最后一轮查缺补漏，不改变任何已有产品逻辑）：
> 1. **`LearningPath`/`TimedAssessment`/`DefinitionTestMode` 补上正式声明**（二、2.3）：自 v1.0 起就在使用，历次改版只写"定义不变"，从未出现在当前版本文档正文里。
> 2. **修正 `WordCardReviewRouteTable.resolve` 缺 `settings` 参数的遗留问题**（三、3.5.1）：本文档 3.5 节末尾说明文字早已指出这里需要补上，但实现代码一直没跟上，属于文档内部前后不一致，现已订正为与架构代码文档 v4.5 五、5.7 协议签名一致。
>
> **v4.5 变更**（六节遗留问题第7/8/9条定稿，不改变任何已有代码接口）：
> 1. 第7条（"已学完"UI呈现）：按建议方案定稿。
> 2. 第8条（Unit数量上限）：已定不做，按当前无上限设计上线。
> 3. 第9条（详情页中断持久化）：`PendingDetailPageResolution` 方案定稿。
>
> **v4.4 变更**（本文档六节遗留问题的收尾，详见六节末尾各条）：
> 1. 六、第2条前置缺口已解决：`ActionResult`/`ListeningSelfCheck` 已在架构代码文档 v4.4 五、5.4.1 正式定义，本文档 3.4/3.5 节沿用的 `.listeningCheckResult(ListeningSelfCheck)` 与该定义一致，不需要改动。
> 2. 六、第5/6/7/8/9条（原架构设计文档十一的两条）均已给出具体方案，见六节。
>
> **v4.3 变更**（对接架构代码文档 v4.3）：
> 1. `WordCard` 新增 `isCompletelyLearned(in:)`（一），依据所属 Unit 的 `masteredStabilityThreshold` 判定这张卡是否已经"学完不再需要日常复习"，纯展示层判定，不影响 FSRS 调度或复习队列。
>
> **v4.0 变更总览**（相对 v3.0，对接架构文档 v4.0 的规则表机制）：
> 1. `WordCard` 进一步瘦身：`learningPath`/`step1CorrectOnFirstTry`/`checklistUncheckedSpelling`/`currentStepID` 全部移出，改存 `WordLearningTypeContext`（挂在 `LearningProgress.typeContext` 上）。`WordReviewContext` 改挂在 `ReviewSession.typeContext` 上。
> 2. 新增"学习内容"字段 `learningContent`，默认等于完整内容，检查页勾选部分内容重点学习时被收窄。
> 3. `WordCardStepFactory` 只负责组装 UI 展示内容（页面文案、选项、正确答案），不再有 `route`、不再有任何路由分支判断。
> 4. 新增 `WordLearningRouteRule` 静态数组，把原来分散在各 Step `route` 闭包里的判断，翻译成规则表的行。同样新增 `WordReviewRouteRule`。
>
> **v4.1 补充**（解决 v4.0 遗留的三处衔接问题，对接架构文档 v4.1）：
> 1. Step0 改回普通的 `.timedSelfAssessment` action，检查页作为规则表 `stepWithFollowUp` 触发的追加交互，不再需要扩展 `StepAction`。
> 2. `WordCardStepFactory.buildSequence` 补上 `settings` 参数。
> 3. 新增 `WordCardLearningRouteTable` 的正式实现，`outcomeKey(from:)` 明确了"检查页勾选结果如何转换成规则表可查的 outcome"这一步。
> 4. 补上 `WordLearningTypeContext` 的默认初始化器（`updateProgress` 需要用到）。
>
> **v4.2 变更**（产品逻辑调整，对接架构文档 v4.2）：
> 1. **"认识（即时）"不再是学习流程的独立捷径**：改为触发检查页（`stepWithFollowUp`），与"想到了"共用同一个检查页，区别只在于 `allowEmptySelection`（认识=true，可直接"全部掌握"；想到了=false，必须至少勾一项未掌握）。原 `handleRecognizedInstant` 函数移除，见五。
> 2. **复习流程"认识（即时）"新增确认页**：不再直接进拼写测试，先弹一个确认页（`buildReviewCheckPageStep`，`allowEmptySelection` 恒为 `true`），可以不勾选直接过（进入拼写测试），勾选任意未掌握项则直接转入完整重学。"想到了""模糊""不认识"三个分支不受影响。见四、4.3/4.4。
> 3. `WordReviewOutcomeKey` 新增 `.checklistCompleted` case，`WordCardReviewRouteTable.outcomeKey(from:)` 相应新增对 `.checklistResult` 的处理。

---

## 一、WordCard 数据模型

```swift
import SwiftData
import Foundation

@Model
final class WordCard: Card {
    @Attribute(.unique) var id: UUID
    var cardType: CardType { get }
    var unitID: UUID

    // 基本信息
    var word: String
    var phoneticUS: String?
    var phoneticUK: String?
    var audioUSPath: String?
    var audioUKPath: String?

    // 完整内容（永久不变）
    @Relationship(deleteRule: .cascade) var definitions: [WordDefinition]
    @Relationship(deleteRule: .cascade) var englishDefinitions: [WordEnglishDefinition]
    @Relationship(deleteRule: .cascade) var examples: [WordExample]
    var imageData: Data?

    // v4.0 新增：学习内容。默认与完整内容一致（即 definitions/englishDefinitions 的引用/拷贝），
    // 检查页（"想到了"分支）勾选部分内容重点学习时，被替换为对应内容的子集。
    // 具体表示方式：与其拷贝一份 definitions 数组，不如存"这次学习该覆盖哪些 WordDefinition/
    // WordEnglishDefinition 的 id"，出题时按这份 id 集合从完整内容里筛选——这样不需要额外的
    // 数据冗余，也不用担心内容编辑后两份数据不同步。
    var learningContentDefinitionIDs: Set<UUID>?       // nil = 使用全部 definitions
    var learningContentEnglishDefinitionIDs: Set<UUID>? // nil = 使用全部 englishDefinitions
    // 拼写本身（word 字段）不存在"部分学习"的概念（一个单词的拼写不能只学一半），
    // 所以"学习内容"目前只覆盖释义维度，不需要对 word 字段做类似处理。

    var createdAt: Date
    var firstLearnedAt: Date?

    // FSRS
    var fsrs: FSRSState

    // Card 协议要求
    var source: CardSource = .wordbook
    var sourceContext: String?
    var sourceDocumentTitle: String?
    var sourceDocumentId: String?
    var capturedAt: Date?
    var addedToQueue: Bool = false
    var originQueue: QueueKind?
    // 不再有 learningPath / step1CorrectOnFirstTry / checklistUncheckedSpelling / currentStepID
    // ——全部移入 WordLearningTypeContext（见二、2.1），随 LearningProgress 存取

    func reviewPrompt() -> ReviewPrompt
    func fullDetailContent() -> DetailContent
    func learningDefinitions() -> [WordDefinition]
    func learningEnglishDefinitions() -> [WordEnglishDefinition]
    func narrowLearningContent(toDefinitionIDs defIDs: Set<UUID>?, englishDefinitionIDs enDefIDs: Set<UUID>?)
    func resetLearningContent()
    func isCompletelyLearned(in unit: Unit) -> Bool
    init(word: String, unitID: UUID)
}

@Model
final class WordDefinition {
    @Attribute(.unique) var id: UUID
    var partOfSpeech: String
    var meaning: String
    var order: Int
}

@Model
final class WordEnglishDefinition {
    @Attribute(.unique) var id: UUID
    var content: String
    var order: Int
}

@Model
final class WordExample {
    @Attribute(.unique) var id: UUID
    var sentence: String
    var translation: String?
    var audioPath: String?
    var source: String?
}
```

**`cardType`**：恒为 `.word`。

**`reviewPrompt()`**  
做什么：给出复习时的线索。  
输入：无（读卡片自身音标与音频路径）。  
输出：`ReviewPrompt.audio`。音标优先 `phoneticUS`，否则 `phoneticUK`，再否则空字符串；音频路径用 `audioUSPath`。

**`fullDetailContent()`**  
做什么：组装详情页完整内容，按固定四个 `DetailSection` 输出。  
输入：无。  
输出：`DetailContent`，四个 section 的 id / 标题 / 内容分别为：

- `meaning` / 「中文含义」：`definitions` 各条 `meaning` 用换行拼接
- `englishMeaning` / 「英文释义」：`englishDefinitions` 各条 `content` 用换行拼接
- `listening` / 「发音」：`phoneticUS`，否则 `phoneticUK`，再否则空字符串
- `spelling` / 「拼写」：`word` 字段本身

**`learningDefinitions()`**  
做什么：按当前「学习内容」筛出题用的中文释义，而不是直接用完整 `definitions`。  
输入：无。  
输出：`[WordDefinition]`。`learningContentDefinitionIDs == nil` 表示使用全部 `definitions`；非 nil 时只保留 id 落在该集合里的释义。

**`learningEnglishDefinitions()`**  
做什么：同上，针对英文释义。  
输入：无。  
输出：`[WordEnglishDefinition]`。`learningContentEnglishDefinitionIDs == nil` 表示全部 `englishDefinitions`；非 nil 时按 id 集合筛选。

**`narrowLearningContent(toDefinitionIDs:englishDefinitionIDs:)`**  
做什么：检查页勾选「部分内容重点学习」时收窄学习内容。  
输入：中文释义 id 集合、英文释义 id 集合（均可为 nil）。  
输出：无。把两个字段分别写成传入值。

**`resetLearningContent()`**  
做什么：每次新一轮学习开始（比如这张卡重新进入 Step0）时，把学习内容重置为默认（=完整内容）。  
输入：无。  
输出：无。两个学习内容 id 集合都写成 nil。

**`isCompletelyLearned(in:)`**（v4.3）  
做什么：纯展示层判定这张卡是否已经「学完，不再需要日常复习」（架构设计文档十）。不影响 FSRS 调度或复习队列。  
输入：卡片所属的 `Unit`（由调用方传入，本方法不按 `unitID` 做持久化查询）。  
输出：`Bool`。比较 `fsrs.stability` 与 `unit.masteredStabilityThreshold`：stability 大于等于阈值即为学完。该阈值已经把这个 Unit 的 `desiredRetention` 换算进去，这里不重复计算。

**`init(word:unitID:)`**  
做什么：新建一张单词卡。  
输入：词形、所属 Unit id。  
注意事项：生成新 `id`；`definitions` / `englishDefinitions` / `examples` 为空数组；`createdAt` 为当前时间；`fsrs` 为默认 `FSRSState()`。其余字段用类型上的默认值（如 `source = .wordbook`、`addedToQueue = false`）。学习内容两个 id 集合未写入，保持 nil（即完整内容）。

`WordDefinition` / `WordEnglishDefinition` / `WordExample` 只有字段，没有方法。

---

## 二、临时状态类型

### 2.1 WordLearningTypeContext：挂在 LearningProgress 上

```swift
/// 单词型学习流程的临时状态，遵循架构层 LearningTypeContext 协议。
/// 存在 LearningProgress.typeContext 里，不是 WordCard 自己的字段。
struct WordLearningTypeContext: LearningTypeContext {
    var learningPath: LearningPath?
    var step1CorrectOnFirstTry: Bool?
    // checklistUncheckedSpelling 不再需要单独存——检查页勾选结果直接决定了
    // learningContentDefinitionIDs/learningContentEnglishDefinitionIDs（写在 WordCard 上）
    // 以及要不要经过 Step7，这个"要不要经过 Step7"的判断现在是规则表的一个条件字段
    // （见三、3.4 的 uncheckedSpelling 字段），不需要在 typeContext 里重复记录

    /// 默认初始化器：供 WordCardLearningRouteTable.updateProgress 在
    /// progress.typeContext 还是 nil 时构造一个空的初始值
    init(learningPath: LearningPath? = nil, step1CorrectOnFirstTry: Bool? = nil)
}
```

两个参数都可以省略，缺省都是 nil。`WordCardLearningRouteTable.updateProgress` 在 `progress.typeContext` 仍为 nil 时，必须用这个默认值构造一份空的 `WordLearningTypeContext`，再按 3.5 写入路径/首试标记。

### 2.2 WordReviewContext：挂在 ReviewSession 上

```swift
/// 单词型复习流程的会话上下文，遵循架构层 ReviewTypeContext 协议
struct WordReviewContext: ReviewTypeContext {
    var assessment: TimedAssessment
}
```

### 2.3 单词型专属枚举（补全正式定义，此前只写"与 v1.0 相同不重复列出"，从未在当前版本文档正文出现）

```swift
enum LearningPath: Int, Codable {
    case full = 0                 // 不认识：完整流程（释义→听音→拼写）
    case vagueMini = 1            // 模糊：仅 Step2 + Step5，然后拼写阶段
    case checkPageRemedial = 2    // 想到了/认识但检查页有未掌握项：释义阶段和/或拼写阶段，不含听音阶段
}

/// 学前自测 / 复习自测（限时自测）
enum TimedAssessment: Int, Codable {
    case unknown = 1              // 不认识
    case vague = 2                // 模糊
    case recalledDelayed = 3      // 想到了（3秒后点击）
    case recognizedInstant = 4    // 认识（3秒内点击）

    var fsrsRating: FSRSRating { get }
}

/// 释义测试模式（设置项）
enum DefinitionTestMode: Int, Codable {
    case off = 0            // 关闭：纯中文释义，仅 Step1(英→中) + Step2(中→英)
    case replace = 1        // 替换释义：用英文释义替换中文释义测试，仅 Step1+Step2，无独立 Step3
    case separateStep = 2   // 单独步骤（默认）：Step1(英→中) + Step2(中→英) + Step3(英英→中)
}
```

`TimedAssessment.fsrsRating` 的映射（不是可执行 `switch`，实现时按此表转换）：

- `recognizedInstant`、`recalledDelayed` → `easy`
- `vague` → `good`
- `unknown` → `again`

`ListeningSelfCheck` 定义见 husk-architecture-code.md 五、5.4.1（架构层类型，因其是 `ActionResult` 一个 case 的 payload，不在此重复）。

`AppSettings` 本体见架构代码文档十一。单词型在其上补充专属字段：

```swift
extension AppSettings {
    var definitionTestMode: DefinitionTestMode { get set }
}
```

该字段默认值为 `.separateStep`。学习规则表的 `definitionTestMode` 条件、以及 Factory 是否把 Step3 编入槽位链，都读这个字段，不另设隐式单例。

---

## 三、学习流程：Step 定义与规则表

### 3.1 StepID 命名约定

```swift
extension StepID {
    static let step0 = StepID(rawValue: "word.step0")
    static let step1 = StepID(rawValue: "word.step1")
    static let step2 = StepID(rawValue: "word.step2")
    static let step3 = StepID(rawValue: "word.step3")
    static let step4 = StepID(rawValue: "word.step4")
    static let step5 = StepID(rawValue: "word.step5")
    static let step6 = StepID(rawValue: "word.step6")
    static let step7 = StepID(rawValue: "word.step7")
    static let step7a = StepID(rawValue: "word.step7a")
}
```

### 3.2 Step 的静态定义（纯展示，不含路由逻辑）

```swift
let wordCardOrderedStepIDs: [StepID] = [
    .step0, .step1, .step2, .step3, .step4, .step5, .step6, .step7, .step7a
]

let wordCardNonThresholdStepIDs: Set<StepID> = [.step0, .step7a]
```

Step0 是普通的 `.timedSelfAssessment`，不需要任何复合 action（v4.1 起不再需要，见架构代码文档 v4.1 五、5.5 的 `stepWithFollowUp` 机制）。各 Step 的 `prompt` 在渲染时结合具体 card 现填，静态定义里是空的 `PromptContent()`。选择题的 `options` / `correctIndex`、拼写的 `correctAnswer` 同样是模板占位，真实内容由六、第3条的 `fill` 在渲染前填入。

检查页不是传送带上的独立槽位，是规则表通过 `stepWithFollowUp` 触发的一段「追加交互」。**v1.1 变化**：不再只有「想到了」才触发——「认识（即时）」现在也会触发同一个检查页（见 3.4 规则表，`.assessment(.recognizedInstant)` 与 `.assessment(.recalledDelayed)` 都指向 `stepWithFollowUp`）。两者的区别只在于 `allowEmptySelection` 这个参数：

- 来自「认识（即时）」→ `true`，检查页「全部掌握」按钮可用，允许不勾选任何项直接通过
- 来自「想到了」→ `false`，检查页「全部掌握」按钮禁用，必须至少勾选一项未掌握

这个参数不属于 Step 的静态描述（Step 本身仍然是纯展示），而是构造 `checklistConfirm` action 时的一个附加配置，随 action 一起传给渲染层决定按钮是否可点。StepID 用一个不出现在 `wordCardOrderedStepIDs` 里的值，明确它不是物理槽位。

```swift
let checkPageStepID = StepID(rawValue: "word.step0.checkPage")
```

各 Step 静态形状：

| 名称 | id | action | highlightSectionID | 是否物理槽位 |
| --- | --- | --- | --- | --- |
| Step0 学前自测 | `.step0` | `.timedSelfAssessment` | nil | 是 |
| 检查页 | `checkPageStepID`（`word.step0.checkPage`） | `.checklistConfirm`（items 渲染时填；`allowEmptySelection` 见上） | nil | 否（`stepWithFollowUp` 携带） |
| Step1 | `.step1` | `.multipleChoice` | `"meaning"` | 是 |
| Step2 | `.step2` | `.multipleChoice` | `"meaning"` | 是 |
| Step3 | `.step3` | `.multipleChoice` | `"meaning"` | 是（仅 `definitionTestMode == .separateStep` 时编入槽位链，见 3.6） |
| Step4 | `.step4` | `.multipleChoice` | `"listening"` | 是 |
| Step5 | `.step5` | `.multipleChoice` | `"listening"` | 是 |
| Step6 | `.step6` | `.binarySelfAssessment` | `"listening"` | 是 |
| Step7 | `.step7` | `.spelling`（`toleranceRule: .exact`） | `"spelling"` | 是 |
| Step7a | `.step7a` | `.multipleChoice` | `"spelling"` | 是 |

3.4 规则表行里的 `buildCheckPageStep(allowEmptySelection:)` 指的就是上表「检查页」这一份静态形状，按入口传入对应的 `allowEmptySelection`。它不是独立物理工位，也不出现在 Factory 的槽位字典里。

**对比 v3.0**：每个 Step 的构造不再需要 `settings: AppSettings` 参数——原来 `definitionTestMode` 会影响 Step1/2/3 具体测什么、Step3 存不存在，这部分判断现在完全交给规则表（`definitionTestMode` 作为规则表的条件字段，见 3.4），`Step` 本身只是「这个 StepID 对应一个什么形式的交互」的静态占位，不需要知道设置内容。**Step 是否要编入 `LearningStepSequence.steps` 字典**（比如 `.off`/`.replace` 模式下 Step3 是否存在）这件事，本文档在 3.6 节的 Factory 组装里仍然需要根据设置做一次性判断——这不是「路由逻辑」，是「这个 CardType 在当前配置下，物理槽位链里到底有没有 Step3 这个工位」的结构性决定，跟「某张卡具体怎么从一个 Step 走到下一个」是两回事。

### 3.3 LearningOutcomeKey：查表用的判定结果枚举

```swift
enum WordLearningOutcomeKey: Codable, Equatable {
    case correct
    case incorrect
    // Step0 自测的四分支（v1.1：认识/想到了都会走到检查页，都需要在这里表达），
    // 以及检查页勾选结果
    case assessment(TimedAssessment)
    case checklistCompleted(uncheckedMeaning: Bool, uncheckedSpelling: Bool)
    // Step6 听音自测专用，语义独立于 Step0 的 TimedAssessment 四分支，
    // 不复用 .assessment（本文档六、第2条实现细节）
    case listeningCheck(ListeningSelfCheck)
    // 学习界面"标熟"按钮仍不经过规则表，见五（"认识即时"不再是捷径，已并入检查页流程）
}
```

### 3.4 WordLearningRouteRule：单词型学习流程规则表

```swift
struct WordLearningRouteRule: RouteRuleMatching {
    let step: StepID
    let outcome: WordLearningOutcomeKey

    // 条件字段，nil = 通配
    let learningPath: LearningPath?
    let definitionTestMode: DefinitionTestMode?
    let step1FirstTry: Bool?

    /// v4.1：不再是单词型自己定义的 WordRouteTarget，改用架构层的泛型
    /// RouteTarget<FSRSRating>（见 husk-architecture-code.md v4.1 五、5.5）——
    /// .step / .finished(FSRSRating) / .stepWithFollowUp 三个 case 都是
    /// 架构层统一提供的，单词型不需要重新定义这个枚举结构。
    let target: RouteTarget<FSRSRating>
    let signal: FailureSignal

    func matchesKey<Key: Equatable>(_ key: Key) -> Bool
    func matchesConditions(against state: Any) -> Bool
    var specificity: Int { get }
}
```

`RouteRuleMatching` 在本类型上的含义：键是 `(step, outcome)` 必须精确相等；条件吻合指 `learningPath` / `definitionTestMode` / `step1FirstTry` 为 nil 则通配，非 nil 则分别与当前 `WordLearningTypeContext.learningPath`、`AppSettings.definitionTestMode`、`step1CorrectOnFirstTry` 一致；`specificity` 为这三个条件字段里非 nil 的个数。

```swift
/// 完整规则表。按 Step 分组注释，方便对照设计文档附录A逐条核对。
let wordLearningRouteTable: [WordLearningRouteRule] = [

    // ── Step0：自测四分支（v1.1：认识/想到了都触发检查页，不再有"认识直接学完"的捷径）──

    .init(step: .step0, outcome: .assessment(.recognizedInstant), learningPath: nil, definitionTestMode: nil, step1FirstTry: nil,
          target: .stepWithFollowUp(followUpStep: buildCheckPageStep(allowEmptySelection: true)), signal: .none),
          // "认识（即时）"：检查页允许不勾选任何项直接"全部掌握"通过。

    .init(step: .step0, outcome: .assessment(.recalledDelayed), learningPath: nil, definitionTestMode: nil, step1FirstTry: nil,
          target: .stepWithFollowUp(followUpStep: buildCheckPageStep(allowEmptySelection: false)), signal: .none),
          // "想到了"：检查页禁止空选，必须至少勾选一项未掌握。
          // 两行的 target 都不是终态，是"接着弹检查页"。引擎收到这个 target 后，
          // 会展示对应的 buildCheckPageStep(allowEmptySelection:)，拿到
          // .checklistResult(uncheckedItems:) 后，通过 WordCardLearningRouteTable.
          // outcomeKey(from:) 转换成下面这几行对应的 .checklistCompleted(...) outcome，
          // 再查一次本表（查询键固定用 step: .step0——检查页在逻辑上仍属于 Step0 这一步
          // 的延伸，不是新的 StepID）。"全部掌握"与"至少勾一项"这条约束由渲染层根据
          // allowEmptySelection 控制按钮可用性来保证，规则表本身不需要再校验这条约束
          // ——不合法的空选状态在 UI 层就已经被挡住，不会产生一个"想到了+全空"的
          // outcome 传回来查表。

    .init(step: .step0, outcome: .assessment(.vague), learningPath: nil, definitionTestMode: nil, step1FirstTry: nil,
          target: .step(.step2), signal: .none),

    .init(step: .step0, outcome: .assessment(.unknown), learningPath: nil, definitionTestMode: nil, step1FirstTry: nil,
          target: .step(.step1), signal: .none),

    // ── 检查页结果（第二次查表，键仍是 step: .step0）──
    // "全部掌握"通过（.easy）这一行只可能从"认识"入口产生（"想到了"入口该按钮禁用，
    // UI 层保证不会产生这个 uncheckedMeaning/uncheckedSpelling 皆为 false 的 outcome）。
    .init(step: .step0, outcome: .checklistCompleted(uncheckedMeaning: false, uncheckedSpelling: false),
          learningPath: nil, definitionTestMode: nil, step1FirstTry: nil,
          target: .finished(.easy), signal: .none),

    .init(step: .step0, outcome: .checklistCompleted(uncheckedMeaning: true, uncheckedSpelling: false),
          learningPath: nil, definitionTestMode: nil, step1FirstTry: nil,
          target: .step(.step1), signal: .none),

    .init(step: .step0, outcome: .checklistCompleted(uncheckedMeaning: false, uncheckedSpelling: true),
          learningPath: nil, definitionTestMode: nil, step1FirstTry: nil,
          target: .step(.step7), signal: .none),

    .init(step: .step0, outcome: .checklistCompleted(uncheckedMeaning: true, uncheckedSpelling: true),
          learningPath: nil, definitionTestMode: nil, step1FirstTry: nil,
          target: .step(.step1), signal: .none),
          // 同时未掌握两类：先释义后拼写，释义阶段走完后由 Step2 的规则（见下）决定要不要接 Step7

    // ── Step1 ──
    .init(step: .step1, outcome: .correct, learningPath: nil, definitionTestMode: nil, step1FirstTry: nil,
          target: .step(.step2), signal: .none),
    .init(step: .step1, outcome: .incorrect, learningPath: nil, definitionTestMode: nil, step1FirstTry: nil,
          target: .step(.step1), signal: .detailPage),

    // ── Step2：全表里条件分支最多的一个 Step ──
    .init(step: .step2, outcome: .incorrect, learningPath: nil, definitionTestMode: nil, step1FirstTry: nil,
          target: .step(.step2), signal: .detailPage),

    .init(step: .step2, outcome: .correct, learningPath: .vagueMini, definitionTestMode: nil, step1FirstTry: nil,
          target: .step(.step5), signal: .none),

    .init(step: .step2, outcome: .correct, learningPath: .checkPageRemedial, definitionTestMode: nil, step1FirstTry: nil,
          target: .step(.step7), signal: .none),
          // 注：checkPageRemedial 路径下 Step2 完成后是否接 Step7，取决于检查页当初是否
          // 勾了拼写未掌握——这个信息已经通过"检查页那一步直接决定入口是 Step1 还是 Step7"
          // （见上面 checklistCompleted 那几行）表达过了，若入口就是 Step1（说明拼写也未掌握），
          // Step2 完成后接 Step7 是确定的；若拼写已掌握，检查页那一步就不会进 Step1，
          // 也就不会走到这一行。这里这一行因此可以直接写死 target: .step(.step7)，
          // 不需要再额外一个 uncheckedSpelling 条件字段——检查页环节已经把分支处理完了。

    .init(step: .step2, outcome: .correct, learningPath: .full, definitionTestMode: .separateStep, step1FirstTry: nil,
          target: .step(.step3), signal: .none),
    .init(step: .step2, outcome: .correct, learningPath: nil, definitionTestMode: .separateStep, step1FirstTry: nil,
          target: .step(.step3), signal: .none),
          // learningPath为nil（未设置，理论上不会发生在真实流程里，防御性兜底行，
          // 与上面 .full 那行结果相同，为清楚起见都显式列出）

    .init(step: .step2, outcome: .correct, learningPath: .full, definitionTestMode: .off, step1FirstTry: true,
          target: .step(.step5), signal: .none),
    .init(step: .step2, outcome: .correct, learningPath: .full, definitionTestMode: .off, step1FirstTry: false,
          target: .step(.step4), signal: .none),
    .init(step: .step2, outcome: .correct, learningPath: .full, definitionTestMode: .replace, step1FirstTry: true,
          target: .step(.step5), signal: .none),
    .init(step: .step2, outcome: .correct, learningPath: .full, definitionTestMode: .replace, step1FirstTry: false,
          target: .step(.step4), signal: .none),

    // ── Step3（仅 separateStep 模式存在）──
    .init(step: .step3, outcome: .incorrect, learningPath: nil, definitionTestMode: nil, step1FirstTry: nil,
          target: .step(.step3), signal: .detailPage),
    .init(step: .step3, outcome: .correct, learningPath: nil, definitionTestMode: nil, step1FirstTry: true,
          target: .step(.step5), signal: .none),
    .init(step: .step3, outcome: .correct, learningPath: nil, definitionTestMode: nil, step1FirstTry: false,
          target: .step(.step4), signal: .none),

    // ── Step4 ──
    .init(step: .step4, outcome: .correct, learningPath: nil, definitionTestMode: nil, step1FirstTry: nil,
          target: .step(.step5), signal: .none),
    .init(step: .step4, outcome: .incorrect, learningPath: nil, definitionTestMode: nil, step1FirstTry: nil,
          target: .step(.step4), signal: .detailPage),

    // ── Step5 ──
    .init(step: .step5, outcome: .incorrect, learningPath: nil, definitionTestMode: nil, step1FirstTry: nil,
          target: .step(.step5), signal: .detailPage),
    .init(step: .step5, outcome: .correct, learningPath: .vagueMini, definitionTestMode: nil, step1FirstTry: nil,
          target: .step(.step7), signal: .none),
    .init(step: .step5, outcome: .correct, learningPath: nil, definitionTestMode: nil, step1FirstTry: nil,
          target: .step(.step6), signal: .none),   // 通配：full/checkPageRemedial 都走 Step6

    // ── Step6 ──
    // 用 ListeningSelfCheck（已有的二值枚举，语义是"听音自测：听懂了/没听懂"）
    // 取代此前借用的 TimedAssessment.recognizedInstant/.unknown——Step6 本身不是
    // 限时四分支自测，借用四分支类型的两个 case 表达二选一语义不贴切，
    // 也容易让人误以为 Step6 和 Step0 共享同一套判定逻辑。改用 ListeningSelfCheck
    // 后，WordLearningOutcomeKey 需要新增 .listeningCheck(ListeningSelfCheck) 这个
    // case（与 .assessment(TimedAssessment) 平行，互不复用），Step6 对应的
    // outcomeKey(from:) 转换分支相应改为识别这个新 case（3.5 节）。
    .init(step: .step6, outcome: .listeningCheck(.recognized), learningPath: nil, definitionTestMode: nil, step1FirstTry: nil,
          target: .step(.step7), signal: .none),
    .init(step: .step6, outcome: .listeningCheck(.notRecognized), learningPath: nil, definitionTestMode: nil, step1FirstTry: nil,
          target: .step(.step6), signal: .detailPage),

    // ── Step7 ──
    .init(step: .step7, outcome: .correct, learningPath: .full, definitionTestMode: nil, step1FirstTry: nil,
          target: .finished(.again), signal: .none),
    .init(step: .step7, outcome: .correct, learningPath: .vagueMini, definitionTestMode: nil, step1FirstTry: nil,
          target: .finished(.good), signal: .none),
    .init(step: .step7, outcome: .correct, learningPath: .checkPageRemedial, definitionTestMode: nil, step1FirstTry: nil,
          target: .finished(.easy), signal: .none),
    .init(step: .step7, outcome: .incorrect, learningPath: nil, definitionTestMode: nil, step1FirstTry: nil,
          target: .step(.step7a), signal: .lightHint),

    // ── Step7a ──
    .init(step: .step7a, outcome: .correct, learningPath: .full, definitionTestMode: nil, step1FirstTry: nil,
          target: .finished(.again), signal: .none),
    .init(step: .step7a, outcome: .correct, learningPath: .vagueMini, definitionTestMode: nil, step1FirstTry: nil,
          target: .finished(.good), signal: .none),
    .init(step: .step7a, outcome: .correct, learningPath: .checkPageRemedial, definitionTestMode: nil, step1FirstTry: nil,
          target: .finished(.easy), signal: .none),
    .init(step: .step7a, outcome: .incorrect, learningPath: nil, definitionTestMode: nil, step1FirstTry: nil,
          target: .step(.step7), signal: .detailPage),
]
```

> **表末尾说明**：Step7/Step7a 的 `.correct` 分支按 `learningPath` 区分了三行（对应三种 FSRS Rating），这跟"结果相同的行要合并通配"的原则似乎矛盾——但这里三行的**结果本身就不同**（`.again`/`.good`/`.easy` 三个不同 Rating），不属于"可合并"的情形，合并通配只适用于"多种条件取值对应同一个结果"的场景（比如 5.2 节 ReviewRouteRule 里"认识"和"模糊"都对应 `.easy` 那种情况），这里没有可合并的空间，如实列出三行是正确的写法。

### 3.5 WordCardLearningRouteTable：查表实现，含 outcomeKey 转换

```swift
/// 遵循架构层 LearningRouteTable 协议（见 husk-architecture-code.md v4.1 五、5.7）。
/// FinishedPayload 关联类型实例化为 FSRSRating——单词型学完时携带的信息就是这个 Rating。
/// FSRSRating 已经在架构层遵循 FSRSRatingConvertible（见架构代码文档 v4.1 二），
/// 这里的 typealias 天然满足协议对 FinishedPayload 的约束，不需要额外实现。
struct WordCardLearningRouteTable: LearningRouteTable {
    typealias FinishedPayload = FSRSRating

    func outcomeKey(from result: ActionResult) -> WordLearningOutcomeKey
    func resolve(step: StepID, outcome: WordLearningOutcomeKey, progress: LearningProgress, settings: AppSettings) -> (target: RouteTarget<FSRSRating>, signal: FailureSignal)?
    func updateProgress(_ progress: LearningProgress, step: StepID, outcome: WordLearningOutcomeKey) -> LearningProgress
}
```

**`outcomeKey(from:)`**  
做什么：把 `EngineJudge.evaluate` 产出的通用 `ActionResult` 转成单词型自己的 outcome 枚举。这是「检查页勾选结果如何转换成规则表可查的 outcome」的落地（v4.1）。  
输入：一次作答的 `ActionResult`。  
输出：`WordLearningOutcomeKey`。对应关系：

- `.boolResult`：`true` → `.correct`，`false` → `.incorrect`
- `.timedAssessmentResult`：原样包进 `.assessment(...)`
- `.listeningCheckResult`：原样包进 `.listeningCheck(...)`。这是 Step6 专用（本文档六、第2条）。假定 `EngineJudge.evaluate` 已经区分 Step0 的限时自测与 Step6 的听音自测，产出不同的 `ActionResult` case——两者虽然都是「用户点了两个选项之一」，但语义、时限规则不同，由 EngineJudge 层面就分开，而不是在这里靠 step 参数反推。
- `.checklistResult`：看 `uncheckedItems` 里是否含有 id 为 `"meaning"` 的项 → `uncheckedMeaning`；是否含有 id 为 `"spelling"` 的项 → `uncheckedSpelling`；产出 `.checklistCompleted(uncheckedMeaning:uncheckedSpelling:)`
- 其它 `ActionResult` case：单词型学习流程不会产生，视为编程错误

**`resolve(step:outcome:progress:settings:)`**  
做什么：按当前步、outcome、进度上下文和设置，从 `wordLearningRouteTable` 查出唯一生效行。签名已补上 `settings` 参数，不再依赖内部的 `currentDefinitionTestMode()` 隐式读取全局状态。  
输入：当前 `StepID`、已转换的 outcome、`LearningProgress`、`AppSettings`。  
输出：命中行的 `(target, signal)`；没有可解析行则为 nil。  
注意事项：从 `progress.typeContext` 取出 `WordLearningTypeContext`（可能为 nil）。先按「step 相等、outcome 相等、以及各可选条件」过滤：规则行的 `learningPath` / `definitionTestMode` / `step1FirstTry` 为 nil 表示通配，非 nil 则分别与 `context?.learningPath`、`settings.definitionTestMode`、`context?.step1CorrectOnFirstTry` 比较。过滤后的候选交给架构层 `resolveRoute(candidates:)` 做特异性匹配，取中的那一行给出 target 与 signal。`settings` 必须由调用方传入，禁止在内部隐式读全局单例（订正说明见本节末尾）。

**`updateProgress(_:step:outcome:)`**  
做什么：根据「刚完成的 (step, outcome)」回写本轮学习临时状态。  
输入：当前 `LearningProgress`、刚完成的 Step、对应 outcome。  
输出：写回 `typeContext` 后的 `LearningProgress`。  
注意事项：若 `progress.typeContext` 还不是 `WordLearningTypeContext`（含 nil），先用 2.1 的默认初始化器得到空上下文，再按下表写入：

- Step0 + `.assessment(.vague)` → `learningPath = .vagueMini`
- Step0 + `.assessment(.unknown)` → `learningPath = .full`
- Step0 + `.checklistCompleted`（不区分是「认识」还是「想到了」触发的检查页）→ `learningPath = .checkPageRemedial`。只要检查页产生了 `.checklistCompleted` 这个 outcome（意味着走到了重点学习分支，而不是「认识」入口全空直接 `.finished` 的那一行），学习路径统一记为检查页补学。「认识 + 全部掌握」直接 `target: .finished`，`updateProgress` 根本不会被调用到这一步，不需要在这里额外分支。
- Step1 + `.correct`，且当前 `step1CorrectOnFirstTry == nil` → 记 `true`（只在尚未写过时记首次正确）
- Step1 + `.incorrect` → `step1CorrectOnFirstTry = false`
- 其它 (step, outcome) 不改上下文

写回 `progress.typeContext` 后返回。

> **发现一处协议签名遗漏并订正**：`currentDefinitionTestMode()` 原先设计成不带参数、内部自行读取全局单例，但 `definitionTestMode` 是 `AppSettings` 上的字段（同 `resolvedLearningGoal(settings:)` 等其他读取 `AppSettings` 的地方一样），而 `LearningRouteTable.resolve(step:outcome:progress:)`（架构代码文档五、5.7）的协议签名里根本没有 `settings` 参数——`buildSequence(for:settings:)` 在 v4.1 已经把 `settings` 补进了 Factory 协议（架构代码文档 v4.1 补充第2条），但同一次补漏漏掉了 `resolve` 这一侧，导致 `resolve` 内部除了自行访问某个隐式单例外无路可走。已按上面的实现订正：`resolve` 协议签名和本文档的具体实现都补上了 `settings: AppSettings` 参数，`ReviewRouteTable.resolve` 同理需要补上（复习流程虽然本次没有条件字段读设置，但协议对称性上应该保持一致，避免以后复习侧需要读设置时又要走一遍这次的弯路）。这个改动也意味着调用方（架构代码文档六 `LearningEngine.process`、七 `ReviewEngine.run`）在调用 `ruleTable.resolve(...)` 时需要多传一个 `settings`——这两处本来就已经持有 `settings`（`step(factory:settings:...)` 的参数列表里已经有），只是原来没有继续往 `resolve` 里传，属于顺手补齐，不引入新的依赖来源。

> `WordLearningTypeContext` 需要一个无参默认初始化器（`init()`），供 `updateProgress` 在 `progress.typeContext` 还是 `nil` 时构造一个空的初始值，二、2.1 节已给出该初始化器的规格。

### 3.6 图的组装：Factory 只管 UI

```swift
struct WordCardStepFactory: LearningStepFactory {
    func buildSequence(for cardType: CardType, settings: AppSettings) -> LearningStepSequence
}
```

**`buildSequence(for:settings:)`**  
做什么：按当前设置组装单词型的物理槽位链（只决定「有哪些工位」，不做路由）。  
输入：`CardType`、`AppSettings`。  
输出：`LearningStepSequence`，其中 `orderedStepIDs` 用 `wordCardOrderedStepIDs`，`nonThresholdStepIDs` 用 `wordCardNonThresholdStepIDs`，`steps` 字典按 3.2 的静态形状填入 Step0/1/2/4/5/6/7/7a。  
注意事项：`cardType` 必须是 `.word`，否则视为编程错误（类型不匹配）。**仅当** `settings.definitionTestMode == .separateStep` 时才把 Step3 编入 `steps` 字典。Step3 是否进槽位链是「这个 CardType 在当前配置下物理槽位链的结构」，不是路由逻辑，Factory 仍做这一次判断。

---

## 四、复习流程：规则表与 Factory

### 4.1 StepID

```swift
extension StepID {
    static let reviewAssessment = StepID(rawValue: "word.review.assessment")
    static let reviewSpelling = StepID(rawValue: "word.review.spelling")
}

/// v4.2 新增：复习确认页，与学习流程的 checkPageStepID 同构——不是传送带上的
/// 独立槽位（复习流程本来就不用槽位排队），是规则表通过 stepWithFollowUp 触发的
/// 一段追加交互，只有复习自测判定为"认识（即时）"时才会被引擎调用（见 4.4 规则表）。
let reviewCheckPageStepID = StepID(rawValue: "word.review.checkPage")
```

### 4.2 ReviewOutcomeKey

```swift
enum WordReviewOutcomeKey: Codable, Equatable {
    case assessment(TimedAssessment)
    case correct
    case incorrect
    /// v4.2 新增：复习确认页勾选结果。复用学习流程 checklistCompleted 同样的字段形状
    /// （是否有未掌握的释义项 / 拼写项），但复习流程不区分"释义/拼写该怎么分别处理"——
    /// 复习确认页只有一个用途：判断这次"认识"是否成立。只要 uncheckedMeaning 或
    /// uncheckedSpelling 任一为 true，就代表这次自测不成立，规则表见 4.4。
    case checklistCompleted(uncheckedMeaning: Bool, uncheckedSpelling: Bool)
}
```

### 4.3 WordReviewRouteRule

```swift
struct WordReviewRouteRule: RouteRuleMatching {
    let step: StepID
    let outcome: WordReviewOutcomeKey
    let assessmentSource: TimedAssessment?   // 条件字段，nil = 通配

    /// v4.1：改用架构层的泛型 ReviewRouteTarget<FSRSRating>（见 husk-architecture-code.md
    /// v4.1 五、5.7），不再单独定义 WordReviewRouteTarget——结构完全一致，没有理由重复定义。
    let target: ReviewRouteTarget<FSRSRating>
    let signal: FailureSignal

    func matchesKey<Key: Equatable>(_ key: Key) -> Bool
    func matchesConditions(against state: Any) -> Bool
    var specificity: Int { get }
}
```

键是 `(step, outcome)` 必须精确相等；条件字段只有 `assessmentSource`（nil 通配，非 nil 则与 `WordReviewContext.assessment` 一致）；`specificity` 为该字段非 nil 则 1，否则 0。

```swift
let wordReviewRouteTable: [WordReviewRouteRule] = [
    // ── 复习自测 ──
    .init(step: .reviewAssessment, outcome: .assessment(.recognizedInstant), assessmentSource: nil,
          target: .stepWithFollowUp(followUpStep: buildReviewCheckPageStep()), signal: .none),
          // v4.2：认识（即时）不再直接进拼写测试，先弹确认页（可不勾选直接过）。
          // 这一行的 target 不是终态，引擎收到后展示确认页，拿到 .checklistResult
          // 后经 outcomeKey(from:) 转换成下面 .checklistCompleted(...) 对应的行，
          // 再查一次本表（查询键固定用 step: .reviewAssessment）。

    .init(step: .reviewAssessment, outcome: .assessment(.recalledDelayed), assessmentSource: nil,
          target: .step(.reviewSpelling), signal: .none),
          // "想到了"不弹确认页，直接进拼写测试（见设计文档 5.1 的说明：
          // 复习流程为保持"最多两步"的节奏，只有"认识"这个最高置信度分支才需要
          // 用确认页二次校验，"想到了"本身已经代表置信度不足，靠拼写测试结果说话即可）

    .init(step: .reviewAssessment, outcome: .assessment(.vague), assessmentSource: nil,
          target: .step(.reviewSpelling), signal: .lightHint),
          // "模糊"原设计是"排到复习队列末尾，轮到时进拼写测试"——但复习流程调度节奏
          // 不用槽位排队（维持单卡一次会话跑完的模型），所以这里直接是"继续走到拼写测试"，
          // 不是"排队"。lightHint 对应"模糊"这个判定本身需要给用户一点反馈的产品意图，
          // 具体是否需要这个 signal、要不要改成 .none，可以在实现时依据实际交互反馈调整。
    .init(step: .reviewAssessment, outcome: .assessment(.unknown), assessmentSource: nil,
          target: .transferToFullRelearn, signal: .detailPage),

    // ── 复习确认页结果（第二次查表，键仍是 step: .reviewAssessment）──
    .init(step: .reviewAssessment, outcome: .checklistCompleted(uncheckedMeaning: false, uncheckedSpelling: false),
          assessmentSource: nil,
          target: .step(.reviewSpelling), signal: .none),
          // 不勾选任何项，"全部掌握"通过 → 视为这次认识判断成立，进入拼写测试

    .init(step: .reviewAssessment, outcome: .checklistCompleted(uncheckedMeaning: true, uncheckedSpelling: false),
          assessmentSource: nil,
          target: .transferToFullRelearn, signal: .detailPage),
    .init(step: .reviewAssessment, outcome: .checklistCompleted(uncheckedMeaning: false, uncheckedSpelling: true),
          assessmentSource: nil,
          target: .transferToFullRelearn, signal: .detailPage),
    .init(step: .reviewAssessment, outcome: .checklistCompleted(uncheckedMeaning: true, uncheckedSpelling: true),
          assessmentSource: nil,
          target: .transferToFullRelearn, signal: .detailPage),
          // 只要勾选了任意未掌握项，这次"认识"判断就不成立，不再给拼写测试的机会，
          // 直接转入完整重学——这跟拼写测试真正答错走向相同，只是提前在确认页这一步
          // 就发现了问题，不需要再多耗一次拼写测试的交互

    // ── 拼写测试 ──
    .init(step: .reviewSpelling, outcome: .correct, assessmentSource: .recalledDelayed,
          target: .finished(.hard), signal: .none),
    .init(step: .reviewSpelling, outcome: .correct, assessmentSource: nil,
          target: .finished(.easy), signal: .none),
          // 通配覆盖"认识（确认页全部掌握后）"和"模糊"两种来源，两者结果相同（.easy），不重复写两行
    .init(step: .reviewSpelling, outcome: .incorrect, assessmentSource: nil,
          target: .transferToFullRelearn, signal: .detailPage),
]
```

### 3.5.1 WordCardReviewRouteTable：复习流程查表实现（补齐此前遗漏）

```swift
/// 遵循架构层 ReviewRouteTable 协议。此前版本遗漏了这个具体实现，
/// 只给了规则数据（wordReviewRouteTable），架构文档七节的 ReviewEngine.run
/// 实际调用的 ruleTable.resolve/.outcomeKey/.updateSession 需要这个类型来提供。
/// FinishedPayload 同样实例化为 FSRSRating，天然满足 FSRSRatingConvertible 约束。
struct WordCardReviewRouteTable: ReviewRouteTable {
    typealias FinishedPayload = FSRSRating

    func outcomeKey(from result: ActionResult) -> WordReviewOutcomeKey
    func resolve(step: StepID, outcome: WordReviewOutcomeKey, session: ReviewSession, settings: AppSettings) -> (target: ReviewRouteTarget<FSRSRating>, signal: FailureSignal)?
    func updateSession(_ session: ReviewSession, step: StepID, outcome: WordReviewOutcomeKey) -> ReviewSession
}
```

**`outcomeKey(from:)`**  
做什么：把通用 `ActionResult` 转成复习用 outcome。  
输入：`ActionResult`。  
输出：`WordReviewOutcomeKey`。对应关系：

- `.boolResult`：`true` → `.correct`，`false` → `.incorrect`
- `.timedAssessmentResult`：包进 `.assessment(...)`
- `.checklistResult`：与学习流程 3.5 同构，用 `"meaning"` / `"spelling"` 两个 DetailSection id 判定 `uncheckedMeaning` / `uncheckedSpelling`，产出 `.checklistCompleted`（v4.2：复习确认页 `reviewCheckPageStepID` 的结果转换）

**`resolve(step:outcome:session:settings:)`**  
做什么：从 `wordReviewRouteTable` 查生效行。  
输入：当前 Step、outcome、`ReviewSession`、`AppSettings`。  
输出：`(target, signal)` 或 nil。  
注意事项：v4.6 订正后签名含 `settings`，遵循架构代码文档 v4.4 五、5.7 的协议签名（`ReviewRouteTable.resolve` 要求 settings 参数，与 `LearningRouteTable.resolve` 对称）。此前这里遗漏了这个参数——本文档三、3.5 节末尾的说明文字早已指出「ReviewRouteTable.resolve 同理需要补上」，属于文档内部前后不一致，这里订正。单词型复习规则表目前没有条件字段依赖 settings，这次订正不影响任何现有规则行为，只是让签名与协议保持一致。从 `session.typeContext` 取出 `WordReviewContext`。过滤条件：step 相等、outcome 相等；规则行 `assessmentSource` 为 nil 则通配，否则必须等于 `context?.assessment`。候选再交给架构层 `resolveRoute`。

**`updateSession(_:step:outcome:)`**  
做什么：复习自测完成后，把这次限时判定写入会话上下文，供拼写步按 `assessmentSource` 查表。  
输入：当前 `ReviewSession`、刚完成的 Step、outcome。  
输出：可能已写入 `typeContext` 的 `ReviewSession`。  
注意事项：仅当 outcome 是 `.assessment(某 TimedAssessment)` **并且** step 是 `.reviewAssessment` 时，把 `session.typeContext` 写成 `WordReviewContext(assessment:)`；其它情况原样返回。

### 4.4 Step 定义与 Factory

复习侧各 Step 静态形状：

| 名称 | id | action | highlightSectionID | 是否物理槽位 |
| --- | --- | --- | --- | --- |
| 复习自测 | `.reviewAssessment` | `.timedSelfAssessment` | nil | 是（复习会话入口） |
| 复习拼写 | `.reviewSpelling` | `.spelling`（`toleranceRule: .exact`） | `"spelling"` | 是 |
| 复习确认页 | `reviewCheckPageStepID`（`word.review.checkPage`） | `.checklistConfirm`，`allowEmptySelection` **恒为 true** | nil | 否（`stepWithFollowUp` 携带） |

复习确认页仅「认识（即时）」分支通过 `stepWithFollowUp` 触发（见 4.3）。复用学习流程检查页同款 action（`.checklistConfirm`），但这里始终 `allowEmptySelection: true`——复习确认页的语境本身就是「可以不勾选，默认按你刚才选的认识算」，不存在「想到了」那种强制勾选的分支（复习流程的「想到了」根本不经过这个页面，见 4.3）。展示内容范围（完整 vs 收窄后）遵循与失败详情页相同的规则：若这张卡当前 `learningContentDefinitionIDs` / `learningContentEnglishDefinitionIDs` 非 nil，只展示收窄后的部分，否则展示完整内容（渲染时结合 `card.learningDefinitions()` / `card.learningEnglishDefinitions()` 生成，具体见六遗留细节）。4.3 规则表行里的 `buildReviewCheckPageStep()` 指的就是这一份静态形状。

```swift
struct WordCardReviewStepFactory: ReviewStepFactory {
    func startStepID(for cardType: CardType) -> StepID
    func buildStep(id: StepID, for cardType: CardType) -> Step
}
```

**`startStepID(for:)`**  
输出：恒为 `.reviewAssessment`。

**`buildStep(id:for:)`**  
做什么：按 StepID 给出复习流程里 Factory 负责的物理步。  
输入：StepID、CardType。  
输出：对应 Step（形状见上表）。  
注意事项：只认识 `.reviewAssessment` 与 `.reviewSpelling`。未知 id 视为编程错误。

> **注意**：`reviewCheckPageStepID` 不会出现在 `WordCardReviewStepFactory.buildStep(id:for:)` 的分发里——跟学习流程的 `checkPageStepID` 一样，它不是 Factory 按 StepID 查询组装的物理槽位，而是规则表里 `stepWithFollowUp(followUpStep:)` 直接携带的 Step 值（构造时已经是 4.4 确认页那份静态形状），引擎收到后直接展示，不会反过来问 Factory「这个 StepID 对应什么 Step」。

### 4.5 转入完整重学 / 「想到了」次日覆盖

**`transitionToFullRelearn(card:unit:session:)`**  
做什么：复习侧决定转入完整重学时，准备单词型自己的入口进度，并按 again 更新 FSRS。  
输入：当前 `WordCard`、所属 `Unit`、当前 `ReviewSession`。  
输出：无（副作用：写入学习进度、更新卡片 FSRS）。  
注意事项：槽位入队、`originQueue` / `LearningProgress` 的实际持久化由架构层 `transitionToFullRelearn(card:unit:session:entryStepID:)` 完成（见架构代码文档 v4.0 八）。单词型要准备的进度是：`currentStepID = .step2`，`typeContext` 为 `WordLearningTypeContext(learningPath: .vagueMini, step1CorrectOnFirstTry: nil)`——即从 Step2 进入、走模糊迷你路径。实际写入由架构层持久化接口完成。然后对 `card.fsrs` 做 `FSRSEngine.update`，rating 为 `.again`，`desiredRetention` 取 `unit.desiredRetention`（v4.6：`update` 新增该参数，架构代码文档二，从卡片所属 unit 读取）。

**`WordCard.postFSRSUpdateHook(context:)`**  
做什么：FSRS 更新之后的单词型附加覆盖。  
输入：可选的 `ReviewSession`（`ReviewSession?`）。  
输出：无。  
注意事项：仅当 `context?.typeContext` 能当成 `WordReviewContext`，且其中 `assessment == .recalledDelayed` 时生效：把 `fsrs.dueDate` 强制写成「今天起加 1 个日历日」，并置 `fsrs.dueDateOverridden = true`。其它自测结果不改 dueDate。

---

## 五、独立捷径（不查表）

学习界面「标熟」按钮：用户在 Unit 主界面/学习列表里主动操作，不依赖任何具体 Step 的判定，直接判学完，不经过 `wordLearningRouteTable`。本次只覆盖学习流程中的卡（`originQueue` 为 `.newCards` 或 `.fullRelearn` 的卡），复习流程的类似捷径本次不做。

v4.2 变化：Step0 自测选「认识（即时）」不再是独立捷径——现在会触发检查页（见三、3.4 规则表 `.stepWithFollowUp`），跟「想到了」共用同一套 `stepWithFollowUp` 机制，只是检查页的 `allowEmptySelection` 参数不同。原来的 `handleRecognizedInstant` 已移除，「认识（即时）+ 检查页全部掌握」这条路径现在完全由规则表驱动（见三、3.4 的 `.checklistCompleted(false, false)` 那一行，`target: .finished(.easy)`），不需要引擎层的特殊捷径分支。

**`handleMarkAsFamiliar(card:unit:)`**  
做什么：把当前这张学习中的卡直接标熟并学完。  
输入：`WordCard`、所属 `Unit`。  
输出：无。  
注意事项，按顺序：

1. **入口守卫**：仅当 `card.originQueue` 为 `.newCards` 或 `.fullRelearn` 才继续；否则直接返回。
2. **查进度**：用 `fetchLearningProgress(cardID:)` 取这份未完成的 `LearningProgress`。槽位来自 `LearningProgress.currentStepID`（架构代码文档四：它是这张卡当前排在哪个 Step 槽位的唯一权威来源，见该文档 v4.0 变更 2），而不是重新推导或假设固定入口——「标熟」可能发生在学习流程的任意一步。查不到视为数据不一致（能在学习列表里看到这张卡，理论上一定有未完成进度），交给上层按异常处理，这里不静默兜底，直接返回。
3. **出槽**：`unit.learningSlots.removeCompletedCard(card.id, from: progress.currentStepID)`。
4. **FSRS 初始化**：`FSRSEngine.initialize`，rating 为 `.easy`，`desiredRetention` 取 `unit.desiredRetention`（v4.6：`initialize` 新增该参数，架构代码文档二，从卡片所属 unit 读取）。
5. **清队列标记**：`card.originQueue = nil`。
6. **清临时状态**：`clearLearningProgress(cardID:)`，卡片已学完，A 部分的临时状态存储同步清理。

---

## 六、本文档遗留的实现细节（需要在真正编码前敲定）

按重要程度排序：

1. ~~`handleMarkAsFamiliar` 里"先查出卡当前所在槽位"的具体实现~~ → 已给出（见五），通过 `fetchLearningProgress(cardID:)` 查出 `LearningProgress.currentStepID`，查不到视为数据不一致，交给上层按异常处理，不静默兜底。学完后同步调用 `clearLearningProgress(cardID:)` 清理临时状态存储。
2. ~~`Step6` 复用 `TimedAssessment.recognizedInstant`/`.unknown` 表达二选一的语义借用~~ → 已改用 `ListeningSelfCheck`，`WordLearningOutcomeKey` 新增 `.listeningCheck(ListeningSelfCheck)` case，`outcomeKey(from:)` 相应新增 `.listeningCheckResult` 分支（见三、3.4、3.5）。**前置缺口已解决**：`ActionResult`（含 `.listeningCheckResult(ListeningSelfCheck)`）与 `ListeningSelfCheck` 本身已在架构代码文档 v4.4 五、5.4.1 正式定义，`ListeningSelfCheck` 的具体 case 是 `.recognized`/`.notRecognized`，与本文档 3.4/3.5 节已经在用的名字一致，不需要改动。
3. **`definitionOptions`/`wordChoicesForListening`/`spellingChoices` 等选项生成函数**：3.2 的 Step 静态形状产出的是 Step **模板**（`options` / `correctAnswer` 都是占位），这是有意为之——`Step` 本身按架构文档 v4.0 的瘦身原则只描述「这一步是什么形式的交互」，不携带具体某张卡的内容。真正的内容填充发生在渲染时，由 Factory 完成，约定如下：

   - **调用时机**：`LearningStepFactory`（架构代码文档五）在把模板 Step 交给 UI 层之前，用一个统一的 `fill(step:for:settings:) -> Step` 方法二次加工，把空的 `options`/`correctAnswer` 换成真实内容。`fill` 内部按 `step.id` 分发到各个具体的内容生成函数。签名如下（无函数体；正确项下标通过 `correctIndex` 回写）：

     ```swift
     func fill(step: Step, for card: WordCard, settings: AppSettings) -> Step
     func definitionOptions(for card: WordCard, correctIndex: inout Int) -> [String]
     func wordChoicesForListening(for card: WordCard, correctIndex: inout Int) -> [String]
     func spellingChoices(for card: WordCard, correctIndex: inout Int) -> [String]
     ```

     - `definitionOptions`：用于 Step1/Step2/Step3，从 `card.learningDefinitions()` 取正确项，干扰项从同 Unit 其他卡的 `learningDefinitions()` 里随机抽取。
     - `wordChoicesForListening`：用于 Step4，同上但取词形而非释义。
     - `spellingChoices`：用于 Step7a，正确拼写 + 若干形近词干扰项。

   - **统一依据**：所有生成函数都从 `card.learningDefinitions()`/`card.learningEnglishDefinitions()`（「学习内容」字段，架构代码文档 v4.0 变更 3）取正确项，不直接用 `card.definitions`（完整内容）——检查页勾选收窄内容后，出题范围要跟着收窄，这条约束通过「生成函数只认学习内容字段」来保证，而不是在每个生成函数内部各自判断「要不要收窄」。
   - **复习确认页同理**：4.4 复习确认页走同一条 `fill` 路径，只是复习流程不涉及「学习内容」收窄（复习不会缩小出题范围），直接用完整内容。
4. ~~`currentDefinitionTestMode()` 的具体实现~~ → 发现是架构层协议签名遗漏（`resolve` 没有 `settings` 参数），已在架构代码文档五、5.7 和本文档 3.5 节订正，`resolve` 直接从新增的 `settings` 参数读取 `definitionTestMode`，不再需要一个隐式读取全局单例的辅助函数。
5. **规则表条目数量**：`wordLearningRouteTable` 目前约 30 行、`wordReviewRouteTable` 目前约 10 行，`assertNoRouteRuleConflicts`（架构代码文档五、5.2）应在开发阶段针对这两份表分别实际跑一次。建议在 DEBUG 构建下，App 启动路径（`AppDelegate`/`App`）调用一次冲突检查：分别对 `wordLearningRouteTable` 和 `wordReviewRouteTable` 跑 `assertNoRouteRuleConflicts`。架构代码文档五、5.2 已注明「App 启动时被调用一次」。这不是一次性检查——**每次改动任意一张规则表（新增/修改行）后都应该重新跑一次**，因为特异性冲突只有在具体的行组合下才会暴露，改表本身就是最容易引入冲突的时机。不需要额外写单元测试专门覆盖这件事：断言本身在 DEBUG 启动时就会 crash，比等 CI 跑测试更早发现问题，这与架构层「Release 不运行、避免运行时开销」的设计意图一致，无需额外产出物。
6. **复习确认页 `checklistItems` 的具体来源**：4.4 复习确认页与学习流程检查页一样依赖勾选项列表，此前两处都留空。统一规格：学习检查页（三、3.2 `checkPageStepID`）与复习确认页（四、4.4）共用同一份勾选项。两处语义一致——都是「释义/拼写各自是否掌握」，**固定两项，不随卡片内容变化**，因此不需要 `card` 参数；`settings` 预留（如果未来某种测试模式下检查页需要隐藏其中一项，从 settings 判断，而不是在调用方各自处理）。

   ```swift
   func checklistItems(settings: AppSettings) -> [ChecklistItem]
   ```

   做什么：生成检查页/复习确认页的勾选项。  
   输入：`AppSettings`（预留）。  
   输出：两项，id 固定为 `"meaning"`（展示文案「释义」）与 `"spelling"`（展示文案「拼写」），与 3.5、3.5.1 节 `outcomeKey(from:)` 里按 `"meaning"` / `"spelling"` 比对 `uncheckedItems` 的既有逻辑直接对应，不需要改动那两处。`label` 是展示文案，实际取值留给编码阶段按 UI 文案规范填（此处「释义」/「拼写」仅为占位示意）。
7. **`isCompletelyLearned(in:)` 在 UI 层的具体呈现**：架构设计文档十提到 Unit 首页可以展示"已学完：N 个"这类统计，具体呈现方式此前未展开。**已定，按以下方案**：

   - **入口位置**：主界面（`husk-word-learning-design-v2.md` 3.1 布局图）"今日已学"/"今日已复习"那一行统计的旁边，新增一项"已学完：N 个"，与现有两项并列展示，不新开一屏，保持"打开 Unit 就能看到关键数字"的一致性。
   - **是否需要单独列表页**：需要，但优先级低于本次 v4.x 的核心改动——"已学完：N 个"本身是个可点击的入口，点进去是一个按字母/最近学完时间排序的卡片列表，复用 Unit 内已有的卡片列表组件（如果存在），不需要新设计一套列表 UI。这一条建议先在 v4.x 落地时只做数字展示，列表页作为后续独立小版本补上，避免这次改动范围扩大。
   - **详情页人话呈现**：不直接展示 `fsrs.stability` 数值，改用设计文档十已经给出的表述方向——"预计能记住一年以上"。具体：卡片详情页在 `isCompletelyLearned(in:)` 为 `true` 时，展示这句固定文案 + 一个小图标（比如对勾或徽章），为 `false` 时不展示这个区块（不展示"还需要 X 天才能学完"这类倒计时式的文案，因为这类文案暗示了一个用户可能会紧盯的进度条，与"不新增状态、只是自然结果"的设计初衷相悖）。

8. **Unit 数量上限的主界面呈现**（架构设计文档十一）：**已定：不做，按当前无上限设计上线**。以下建议方案保留仅供未来参考，不安排开发：

   - **触发阈值**：不设硬性上限，但当 Unit 数量超过某个观感阈值（建议 8-10 个，具体数字看主界面单屏能舒适容纳几个卡片式入口）时，主界面从"平铺列表"切换为"可折叠分组 + 搜索框"，而不是无限往下滚动的单一列表。
   - **分组依据**：不做用户手动分组（增加维护负担，且用户目前的心智模型里 Unit 之间是平权的独立单元），而是按"最近使用时间"自动排序，主界面始终把最近学习/复习过的 Unit 排在前面，超过阈值后折叠展示"更多 Unit"。
   - **搜索**：Unit 数量超过阈值后才在主界面顶部显示搜索框，数量少时不需要，避免界面元素冗余。
   - 未采纳原因：这条建议依赖"用户实际会创建多少个 Unit"这个尚无数据支撑的产品假设，先按当前无上限设计上线，收集实际使用数据后再决定是否需要这套分组机制。

9. **详情页中断状态的可持久化表达**（架构设计文档十一）：失败详情页展示期间 App 被中断，需要记录"确认后要执行哪个失败处理"。**已定，采用以下枚举化方案**：

   先盘点失败处理目前实际有哪些种类。按本文档和架构文档已经出现过的失败路径归纳，只有**有限的几种**，不存在真正意义上的"任意代码逻辑"：

   ```swift
   /// 失败详情页展示期间需要持久化的"确认后要做什么"。之所以能枚举化，
   /// 是因为失败处理的种类本身是架构层规则表机制的产物（去哪个 Step / 转入
   /// 完整重学 / 学完），而不是每个 CardType 自由定义的代码逻辑——这与
   /// RouteTarget<FinishedPayload>（五、5.5）结构一致，可以直接复用。
   enum PendingDetailPageResolution: Codable {
       case resumeAtStep(StepID)
           // 确认后回到某个 Step 继续（多数答错场景）
       case enterFullRelearn
           // 确认后转入完整重学（如复习拼写测试答错、Step0"不认识"分支）
       case markFinished(FinishedPayloadCodableBox)
           // 理论上不应该出现在失败详情页后（详情页只在失败路径触发），
           // 保留这个 case 仅为了类型上与 RouteTarget 保持结构对称，
           // 实际使用中可以在 DEBUG 断言里禁止这个 case 出现在这里
   }
   ```

   `FinishedPayloadCodableBox` 是因为 `RouteTarget<FinishedPayload>` 的 `FinishedPayload` 是范型、不天然 `Codable`，需要一个装箱类型把 `FSRSRating` 这类具体值包装成可持久化的形式——这属于编码阶段的样板代码，不是设计决策，此处不展开。

   持久化时机：`RouteTarget`/`ReviewRouteTarget` 查表得到结果、且 `signal == .detailPage` 时，把这次查表结果转换成 `PendingDetailPageResolution` 立即写盘（而不是等用户在详情页停留期间才写），App 恢复时优先检查是否存在未清理的 `PendingDetailPageResolution`，存在则直接跳回详情页确认环节，不重新走一次判定。
