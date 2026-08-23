# Husk 文件夹结构

本文档是源码与文档目录的约定。磁盘路径与 Xcode Group 保持一致（`Husk` target 使用 `PBXFileSystemSynchronizedRootGroup`，按目录自动收录）。

源码模块目录与 `scope/*` **一一对应**：label 为 kebab-case，目录为同一套词的 PascalCase。不按 MVC 切 `Models/` `Views/` `Controllers/`。

## 1. 与 scope 的对应

| 目录 | Label | 职责 |
| :--- | :--- | :--- |
| `Core/` | `scope/core` | 跨 CardType 的核心：Card、Unit、FSRS、持久化、以及两套引擎共用的 Step / 判定 / 详情页调度 |
| `RouteRuleTable/` | `scope/route-rule-table` | 规则表协议、特异性匹配、通用 `RouteTarget` |
| `LearningEngine/` | `scope/learning-engine` | 学习引擎行为 |
| `ReviewingEngine/` | `scope/reviewing-engine` | 复习引擎行为 |
| `WordCard/` | `scope/word-card` | `CardType.word`：卡片、Factory、单词规则表、详情展示 |
| `UI/` | `scope/ui` | 界面与交互，按用户任务分屏 |

没有对应 scope 的目录（入口、资源、文档）不算模块范围，PR/Issue 不打这些路径的 scope。

以后新增 CardType（如短语）时：**先加 `scope/<type>-card`，再加同名 PascalCase 目录**，与 `WordCard/` 并列，不要再套一层没有 scope 的父目录。

## 2. 仓库根

```
Husk/                         # 仓库根
├── Husk.xcodeproj
├── Husk/                     # App 源码 + 文档
├── HuskTests/
└── HuskUITests/
```

本地 AI 工具目录（`CLAUDE.md`、`.wolf/`、`.claude/`）不入库，见根目录 `.gitignore`。

## 3. App 源码（`Husk/`）

```
Husk/
├── App/                      # 入口与依赖注入（无 scope）
│   └── HuskApp.swift
│
├── Core/                     # scope/core
│   ├── Domain/
│   ├── FSRS/
│   ├── Persistence/
│   └── Shared/               # Step、EngineJudge、详情页调度（两引擎共用，属核心）
│
├── RouteRuleTable/           # scope/route-rule-table
│
├── LearningEngine/           # scope/learning-engine
│
├── ReviewingEngine/          # scope/reviewing-engine
│
├── WordCard/                 # scope/word-card
│
├── UI/                       # scope/ui
│   ├── UnitList/
│   ├── UnitHome/
│   ├── LearningSession/
│   ├── ReviewSession/
│   ├── Capture/
│   ├── UnitCreate/
│   └── Settings/
│
├── Resources/                # 无 scope
│   └── Assets.xcassets
│
├── Preview Content/          # 可选
│
└── Docs/                     # 无 scope
    ├── Designs/
    ├── Code/
    └── Rules/
```

`App/`、`Resources/`、`Docs/` 已落地。带 scope 的目录随对应模块首次实现时再建，不要提前堆空文件夹。

## 4. 各目录职责

| 路径 | scope | 放什么 | 不放什么 |
| :--- | :--- | :--- | :--- |
| `App/` | — | `@main`、容器、依赖组装 | 业务 UI、引擎逻辑 |
| `Core/Domain/` | `core` | `Card` 协议、`Unit`、`CardType`、`QueueKind`、`LearningProgress`、`ReviewSession` | 某一种卡片的字段与图 |
| `Core/FSRS/` | `core` | `FSRSState`、`FSRSEngine`、`FSRSRating` | 学习/复习流程调度 |
| `Core/Persistence/` | `core` | 存盘与仓库 | 引擎运行时对象 |
| `Core/Shared/` | `core` | `Step`、`EngineJudge`、失败详情页时机 | 类型专属文案、某一侧引擎的会话循环 |
| `RouteRuleTable/` | `route-rule-table` | 规则表协议、特异性匹配、通用 `RouteTarget` | 单词型具体表行（在 `WordCard/`） |
| `LearningEngine/` | `learning-engine` | `LearningEngine` 行为 | 长期状态（在 `Core`） |
| `ReviewingEngine/` | `reviewing-engine` | `ReviewEngine` 行为 | 同上 |
| `WordCard/` | `word-card` | `WordCard`、Step Factory、单词规则表、详情展示 | 其它 CardType、通用引擎 |
| `UI/` | `ui` | 各任务界面 | 领域模型、路由表 |
| `Resources/` | — | `Assets.xcassets` 等 | Swift 源码 |
| `Docs/` | — | 设计 / 代码接口 / 规范 | 可执行代码 |

## 5. 测试

与带 scope 的源码目录同名镜像：

```
HuskTests/
├── Core/
├── RouteRuleTable/
├── LearningEngine/
├── ReviewingEngine/
└── WordCard/

HuskUITests/
└── Flows/
```

## 6. 约束

1. **目录名 = scope 名的 PascalCase**。增删模块时同时改 GitHub `scope/*`、本文档、版本管理规范里的 label 表。
2. **Xcode Group = 磁盘路径**，不建无路径的虚 Group。
3. **`Core` 不得 import `WordCard`（及其它 `*Card`）**。新类型只加并列目录并在 `App/` 注册。
4. **引擎与状态分目录**：引擎只装行为；`LearningProgress` / `ReviewSession` / `Unit` 持久化字段在 `Core`。
5. **UI 按任务分包**（学、复习、随手记、建 Unit），不设全局 `Views/`、`ViewModels/`、`Helpers/`。
6. **不设跨 Unit 混排入口**。复习只在单个 Unit 内。
7. 新增或移动目录时同步改本文档。

## 7. 与文档的对应

| 文档 | 路径 |
| :--- | :--- |
| 架构设计 | `Docs/Designs/Husk架构设计.md` |
| 架构代码接口 | `Docs/Code/Husk架构代码.md` |
| 单词学习设计 | `Docs/Designs/Husk单词学习设计.md` |
| 单词 Card 代码 | `Docs/Code/Husk单词Card代码.md` |
| 版本管理 | `Docs/Rules/Husk代码版本管理规范.md` |
| 文件夹结构（本文） | `Docs/Rules/Husk文件夹结构.md` |
