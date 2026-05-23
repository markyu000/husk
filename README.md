# Husk

> 智能英语单词记忆应用 · Intelligent English Vocabulary Learning App

---

## 中文

### 项目简介

Husk 是一款基于 iOS/macOS 的英语单词学习应用，作为 Notte 系列学习工具的姊妹产品开发。它结合**三阶段掌握体系**与 **FSRS-5 间隔重复算法**，帮助用户从释义、听音、拼写三个维度全面掌握词汇。

### 核心特性

**三阶段学习体系**
| 阶段 | 内容 |
|------|------|
| 释义阶段 | 英译中、中译英、英文释义→中文翻译 |
| 听音阶段 | 音标辨认与基于发音的单词识别 |
| 拼写阶段 | 键盘输入拼写验证，支持渐进式提示 |

**FSRS-5 间隔重复**
- 19 个可调权重，目标记忆保留率 90%
- 四级自评（认识 / 模糊 / 想想 / 不认识）映射到 FSRS 评分
- 最大复习间隔 100 年，智能调度每日学习量

**错误队列管理**
- 失败单词追加至队列末尾而非立即重复，避免短时强化干扰间隔效果
- 跨日持久化：记录失败断点，下次学习从中断阶段恢复
- 独立的复习模式与新学模式

**每日仪表盘**
- 实时显示今日学习目标、待复习数量与学习连续天数
- 区分"复习"（已调度）与"学习"（新词 + 失败复学）两个入口

### 技术栈

- **语言**: Swift
- **UI 框架**: SwiftUI
- **数据库**: SwiftData
- **平台**: iOS / macOS
- **算法**: FSRS-5 (Free Spaced Repetition Scheduler v5)
- **构建工具**: Xcode

### 设计系统

| 元素 | 规范 |
|------|------|
| 主色调 | `#61FF00` 霓虹草绿 |
| 辅助色 | 纯黑 / 纯白中性色 |
| 主题 | 深色模式（默认）/ 浅色模式 |
| 字体 | iOS 系统字体（Inter 字族，Semi Bold） |

### 项目结构

```
Husk/
├── Husk/
│   ├── HuskApp.swift          # 应用入口，SwiftData 初始化
│   ├── ContentView.swift      # 主界面（导航分栏视图）
│   ├── Item.swift             # 基础数据模型
│   ├── Assets.xcassets/       # 图标与配色资源
│   └── Docs/
│       ├── Husk单词学习逻辑文档.md  # 完整功能规范（含伪代码）
│       ├── Husk配色文档.md          # 品牌配色与设计规范
│       └── HuskGit规范.md           # Git 工作流与提交规范
├── HuskTests/                 # 单元测试
├── HuskUITests/               # UI 自动化测试
└── Husk.xcodeproj/            # Xcode 工程配置
```

### 快速开始

1. 克隆仓库
   ```bash
   git clone <repo-url>
   cd Husk
   ```
2. 使用 Xcode 打开 `Husk.xcodeproj`
3. 选择目标设备（iOS Simulator 或真机）
4. 按 `⌘R` 构建并运行

> 需要 Xcode 26+ 及 iOS 26+

### 内部文档

- `Docs/Husk单词学习逻辑文档.md` — 完整学习流程规范、数据结构与 FSRS 集成细节
- `Docs/Husk配色文档.md` — 配色使用规则与深浅色模式语义色定义
- `Docs/HuskGit规范.md` — 团队 Git 分支策略与提交信息规范

---

## English

### Overview

Husk is an iOS/macOS vocabulary learning app and sister product to the Notte learning suite. It combines a **three-phase mastery system** with the **FSRS-5 spaced repetition algorithm** to help users achieve comprehensive word mastery across meaning, listening, and spelling dimensions.

### Core Features

**Three-Phase Learning System**
| Phase | Content |
|-------|---------|
| Meaning | English→Chinese, Chinese→English, English definition→Chinese translation |
| Listening | Phonetic recognition and audio-based word identification |
| Spelling | Keyboard input with progressive hint assistance |

**FSRS-5 Spaced Repetition**
- 19 adjustable weights with a 90% target retention rate
- Four self-assessment levels (Know / Vague / Think / Don't Know) mapped to FSRS ratings
- Up to 100-year max interval; intelligent daily load scheduling

**Error Queue Management**
- Failed words are appended to the end of the queue rather than repeated immediately, preserving the spacing effect
- Cross-day persistence: remembers which learning stage failed; resumes from that exact point next session
- Separate Review mode (scheduled cards) and Learning mode (new words + failed recalls)

**Daily Dashboard**
- Live display of daily learning targets, review count, and streak
- Two distinct entry points: Review (scheduled) and Learn (new + remediation)

### Tech Stack

- **Language**: Swift
- **UI Framework**: SwiftUI
- **Database**: SwiftData
- **Platform**: iOS / macOS
- **Algorithm**: FSRS-5 (Free Spaced Repetition Scheduler v5)
- **Build Tool**: Xcode

### Design System

| Element | Spec |
|---------|------|
| Primary color | `#61FF00` neon grass green |
| Neutral colors | Pure black / pure white |
| Themes | Dark mode (default) / Light mode |
| Typography | iOS system font (Inter family, Semi Bold) |

### Project Structure

```
Husk/
├── Husk/
│   ├── HuskApp.swift          # App entry point, SwiftData setup
│   ├── ContentView.swift      # Main UI (NavigationSplitView)
│   ├── Item.swift             # Base data model
│   ├── Assets.xcassets/       # Icons and color assets
│   └── Docs/
│       ├── Husk单词学习逻辑文档.md  # Full feature spec (with pseudocode)
│       ├── Husk配色文档.md          # Brand colors and design rules
│       └── HuskGit规范.md           # Git workflow and commit conventions
├── HuskTests/                 # Unit tests
├── HuskUITests/               # UI automation tests
└── Husk.xcodeproj/            # Xcode project configuration
```

### Getting Started

1. Clone the repository
   ```bash
   git clone <repo-url>
   cd Husk
   ```
2. Open `Husk.xcodeproj` in Xcode
3. Select a target device (iOS Simulator or physical device)
4. Press `⌘R` to build and run

> Requires Xcode 26+ and iOS 26+

### Internal Documentation

- `Docs/Husk单词学习逻辑文档.md` — Full learning flow specification, data structures, and FSRS integration details
- `Docs/Husk配色文档.md` — Color usage rules and semantic color definitions for dark/light mode
- `Docs/HuskGit规范.md` — Team Git branching strategy and commit message conventions

---

## License

Copyright © 2025 Mark. All rights reserved.
