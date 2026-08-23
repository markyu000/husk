# Husk 文件夹结构

本文档是源码与文档目录的约定。磁盘路径与 Xcode Group 保持一致（`Husk` target 使用 `PBXFileSystemSynchronizedRootGroup`，按目录自动收录）。

按架构分层 + 按 `CardType` 分包，不按 MVC 的 `Models/` `Views/` `Controllers/` 切。范围与 `scope/*` label 对齐。

## 1. 仓库根

```
Husk/                         # 仓库根
├── Husk.xcodeproj
├── Husk/                     # App 源码 + 文档
├── HuskTests/
└── HuskUITests/
```

本地 AI 工具目录（`CLAUDE.md`、`.wolf/`、`.claude/`）不入库，见根目录 `.gitignore`。

## 2. App 源码（`Husk/`）

```
Husk/
├── App/                      # 入口与依赖注入
│   └── HuskApp.swift
│
├── Core/                     # scope/core
│   ├── Domain/               # Card、Unit、CardType、队列与临时状态
│   ├── FSRS/
│   └── Persistence/          # SwiftData / 仓库
│
├── RouteRules/               # scope/route-rule-table
│
├── Engines/
│   ├── Shared/               # Step、判定、失败详情页调度
│   ├── Learning/             # scope/learning-engine
│   └── Reviewing/            # scope/reviewing-engine
│
├── CardTypes/                # 一种类型一个包，包之间互不引用
│   ├── Word/                 # scope/word-card
│   └── Phrase/               # 未实现时可不建
│
├── Features/                 # scope/ui，按用户任务分屏，不按控件类型
│   ├── UnitList/
│   ├── UnitHome/
│   ├── LearningSession/
│   ├── ReviewSession/
│   ├── Capture/
│   ├── UnitCreate/
│   └── Settings/
│
├── Resources/
│   └── Assets.xcassets
│
├── Preview Content/          # 可选，Preview 假数据
│
└── Docs/
    ├── Designs/
    ├── Code/
    └── Rules/
```

`App/`、`Resources/`、`Docs/` 已落地。其余目录随对应模块首次实现时再建，不要提前堆空文件夹。

## 3. 各目录职责

| 路径 | scope | 放什么 | 不放什么 |
| :--- | :--- | :--- | :--- |
| `App/` | — | `@main`、容器、依赖组装 | 业务 UI、引擎逻辑 |
| `Core/Domain/` | `core` | `Card` 协议、`Unit`、`CardType`、`QueueKind`、`LearningProgress`、`ReviewSession` | 某一种卡片的字段与图 |
| `Core/FSRS/` | `core` | `FSRSState`、`FSRSEngine`、`FSRSRating` | 学习/复习流程调度 |
| `Core/Persistence/` | `core` | 存盘与仓库 | 引擎运行时对象 |
| `RouteRules/` | `route-rule-table` | 规则表协议、特异性匹配、通用 `RouteTarget` | 单词型具体表行（在 `CardTypes/Word/`） |
| `Engines/Shared/` | `learning-engine` / `reviewing-engine` | `Step`、`EngineJudge`、详情页时机 | 类型专属文案 |
| `Engines/Learning/` | `learning-engine` | `LearningEngine` 行为 | 长期状态（状态在 `Core`） |
| `Engines/Reviewing/` | `reviewing-engine` | `ReviewEngine` 行为 | 同上 |
| `CardTypes/Word/` | `word-card` | `WordCard`、Step Factory、单词规则表、详情展示 | 其它 CardType、通用引擎 |
| `Features/` | `ui` | 各任务界面 | 领域模型、路由表 |
| `Resources/` | — | 资源目录（`Assets.xcassets` 等） | Swift 源码 |
| `Docs/` | — | 设计 / 代码接口 / 规范 | 可执行代码 |

## 4. 测试

与源码树镜像，避免单文件堆测试：

```
HuskTests/
├── Core/
├── RouteRules/
├── Engines/
└── CardTypes/Word/

HuskUITests/
└── Flows/
```

## 5. 约束

1. **Xcode Group = 磁盘路径**，不建无路径的虚 Group。
2. **`Core` 不得 import `CardTypes`**。新类型只加 `CardTypes/<Type>/` 并在入口注册，不改内核去认识具体类型。
3. **引擎与状态分目录**：引擎只装行为；`LearningProgress` / `ReviewSession` / `Unit` 持久化字段在 `Core`。
4. **一种 `CardType` 一个文件夹**，该类型的图、规则表、Factory 只改本包。
5. **UI 按任务分包**（学、复习、随手记、建 Unit），不设全局 `Views/`、`ViewModels/`、`Helpers/`。
6. **不设跨 Unit 混排入口**。复习只在单个 Unit 内，主界面是各 Unit 各自入口。
7. 新增或移动目录时同步改本文档。

## 6. 与文档的对应

| 文档 | 路径 |
| :--- | :--- |
| 架构设计 | `Docs/Designs/Husk架构设计.md` |
| 架构代码接口 | `Docs/Code/Husk架构代码.md` |
| 单词学习设计 | `Docs/Designs/Husk单词学习设计.md` |
| 单词 Card 代码 | `Docs/Code/Husk单词Card代码.md` |
| 版本管理 | `Docs/Rules/Husk代码版本管理规范.md` |
| 文件夹结构（本文） | `Docs/Rules/Husk文件夹结构.md` |
