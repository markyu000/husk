# Husk代码版本管理规范

## 1. 分支

### 1.1 分支列表

|     分支     |                      作用                      |
| :----------: | :--------------------------------------------: |
|    `main`    |                     主分支                     |
|  `develop`   |                   开发主分支                   |
| `feature/*`  |                   新功能分支                   |
|   `fix/*`    |                  修复Bug分支                   |
| `refactor/*` |                    重构分支                    |
|   `docs/*`   | 文档定义分支（主要用于大版本前的功能明确细化） |

### 1.2 分支名

分支名全小写，使用`-`间隔

### 1.3 主分支

`main` 为主分支，仅从`develop`合并

### 1.4 合并

所有分支合并通过PR进行记录

## 2. Commit

### 2.1 Commit标题及内容

标题使用`<类型>:<简短标题>`格式

### 2.2 类型

| 类型名称  |     作用      |
| :-------: | :-----------: |
| `reposit` |   仓库管理    |
|  `feat`   |    新功能     |
|   `fix`   |    Bug修复    |
| `refact`  |     重构      |
|  `docs`   |   文档更改    |
|  `xcode`  | xcode配置修改 |
|  `test`   |     测试      |
| `appear`  |      UI       |

## 3. PR

所有PR依据模版创建，设置assignees、label、development

### 3.1 Label

Label 按 `/` 前缀分组，同一前缀组内统一一个颜色，用于区分"类型"与"范围"两个维度。

#### type/*：变更类型（同 2.2 Commit 类型对应新功能/修复/重构/文档/测试/UI 六类）

| Label 名称    | 颜色      | 作用     |
| :------------ | :-------- | :------- |
| `type/feat`   | `#D93F0B` | 新功能   |
| `type/fix`    | `#D93F0B` | Bug修复  |
| `type/refact` | `#D93F0B` | 重构     |
| `type/docs`   | `#D93F0B` | 文档更改 |
| `type/test`   | `#D93F0B` | 测试     |
| `type/appear` | `#D93F0B` | UI       |

#### scope/*：影响范围（对应架构中的模块划分）

| Label 名称                | 颜色      | 作用                                   |
| :------------------------ | :-------- | :------------------------------------- |
| `scope/core`               | `#0E8A16` | 跨 CardType 的核心基础设施（Card/Unit/FSRS等） |
| `scope/route-rule-table`   | `#0E8A16` | 规则表机制（RouteRuleMatching/规则数据等）      |
| `scope/learning-engine`    | `#0E8A16` | 学习引擎                                |
| `scope/reviewing-engine`   | `#0E8A16` | 复习引擎                                |
| `scope/word-card`          | `#0E8A16` | 单词型（CardType.word）具体实现          |
| `scope/ui`                 | `#0E8A16` | 界面与交互                              |

## 4. Issue

所有issue依据模版创建，设置assignees、label、milestone；并在 GitHub Project「Husk Feature Releasing Board」中设置 Priority、Size、Estimate（不需要设置时间期限）

### 4.1 Label

同PR（type/* + scope/*，一个 issue 可以有多个 scope）

### 4.2 Milestone

Milestone 按实现阶段划分（依赖顺序自上而下）：

| Milestone      | 作用                                             |
| :------------- | :----------------------------------------------- |
| 阶段一：基础架构层 | Card/Unit/FSRS 基础数据模型、规则表通用机制、临时状态存储 |
| 阶段二：引擎层     | 学习引擎、复习引擎、失败详情页机制                 |
| 阶段三：单词型实现 | WordCard 数据模型、单词型规则表、Step 定义与 Factory |
| 阶段四：UI 层      | Unit 主界面、学习/复习流程 UI、Unit 创建删除、随手记捕获等 |

### 4.3 Project 字段

| 字段       | 说明                                       |
| :--------- | :----------------------------------------- |
| `Priority` | `P0`/`P1`/`P2`，越小越优先                  |
| `Size`     | `XS`/`S`/`M`/`L`/`XL`，工作量估算档位        |
| `Estimate` | 故事点（数字），细粒度工作量估算              |