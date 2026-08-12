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

| Label 名称    | 颜色      | 作用     |
| :------------ | :-------- | :------- |
| `type/feat`   | `#2EA44F` | 新功能   |
| `type/fix`    | `#D73A4A` | Bug修复  |
| `type/refact` | `#8250DF` | 重构     |
| `type/docs`   | `#0075CA` | 文档更改 |
| `type/test`   | `#FBCA04` | 测试     |
| `type/appear` | `#D4C5F9` | UI       |

## 4. Issue

所有issue依据模版创建，设置assignees、label、estimate、size、时间期限