# Notte Git 操作规范

> 适用阶段：MVP 全程及后续迭代  
> 适用规模：1 人主导开发，最多 2 人协作  
> 最后更新：2026-03

---

## 目录

1. [分支结构](#1-分支结构)
2. [分支命名规则](#2-分支命名规则)
3. [工作流程](#3-工作流程)
4. [Commit 规范](#4-commit-规范)
5. [PR / 合并规则](#5-pr--合并规则)
6. [版本 Tag 规范](#6-版本-tag-规范)
7. [.gitignore 要求](#7-gitignore-要求)
8. [死规则](#8-死规则)
9. [常用命令速查](#9-常用命令速查)

---

## 1. 分支结构

Notte 采用轻量级三层分支模型，不引入复杂的 GitFlow，够用即可。

```
main
 └── develop
       ├── feature/node-editor-core
       ├── feature/onboarding-flow
       ├── fix/page-list-refresh
       └── ...（完成即删）
```

### main

- **性质**：永远稳定，代表可对外展示的版本。
- **来源**：只接受从 `develop` 合并，禁止直接 push。
- **动作**：每次合并后打一个版本 tag（见第 6 节）。
- **保护**：建议在 GitHub 开启 branch protection，强制 PR 合并。

### develop

- **性质**：日常开发的集成主干。
- **单人开发时**：小改动可直接 push，不强制走分支。
- **两人协作时**：禁止直接 push，所有变更通过 feature/* 或 fix/* 的 PR 合并。
- **状态要求**：应保持随时可构建、可运行，不允许长期处于破损状态。

### feature/*

- **用途**：一个独立功能对应一个分支。
- **生命周期**：从 `develop` 创建 → 开发 → PR 合并回 `develop` → **立即删除**。
- **粒度**：对应工程文档中的一个完整阶段目标，或一个独立的业务模块（如 Collection 模块、Node Editor Core）。

### fix/*

- **用途**：修复 bug，包括测试过程中发现的问题。
- **生命周期**：从 `develop` 创建 → 修复 → PR 合并回 `develop` → **立即删除**。
- **紧急修复**：若 main 上线后发现严重 bug，可从 `main` 创建 `hotfix/*` 分支，修复后同时合并回 `main` 和 `develop`，并打新 tag。

---

## 2. 分支命名规则

格式：`类型/简短描述`，用 `-` 连接单词，全小写，不用下划线。

| 类型 | 示例 |
|---|---|
| `feature/` | `feature/collection-list-ui` |
| `feature/` | `feature/node-editor-core` |
| `feature/` | `feature/icloud-sync-beta` |
| `fix/` | `fix/page-delete-crash` |
| `fix/` | `fix/node-sortindex-normalize` |
| `hotfix/` | `hotfix/testflight-launch-crash` |

**命名要求**：

- 描述部分应对应一个明确的功能或问题，不要用 `test`、`temp`、`my-branch` 这类模糊名称。
- 长度控制在 5 个单词以内，足够看懂即可。

---

## 3. 工作流程

### 3.1 单人开发（日常模式）

适用于 MVP 大部分阶段，一人主导时的推荐节奏：

```
1. 小改动（<1 天工作量）：直接在 develop 上提交
2. 独立功能模块：从 develop 拉 feature/* 分支开发，完成后合并回 develop
3. 阶段里程碑完成：将 develop 合并到 main，打 tag
```

示意流程：

```
develop ──●──●──●──────────────────●── (merge to main, tag v0.2.0)
               \                  /
                feature/node-editor-core
                  ●──●──●──●──●──/
```

### 3.2 两人协作（PR 模式）

当有第二人参与开发时，切换为以下流程：

```
1. 两人都从 develop 拉各自的 feature/* 分支
2. 开发完成后发起 PR，目标分支为 develop
3. 对方 review 后合并，自动或手动删除源分支
4. 定期同步：开始新功能前先 pull develop 的最新状态
```

**rebase 还是 merge？**

- feature → develop：用 **squash merge**（GitHub PR 合并选 "Squash and merge"），保持 develop 历史整洁。
- develop → main：用普通 **merge commit**，保留完整历史，方便版本对比。

---

## 4. Commit 规范

采用 [Conventional Commits](https://www.conventionalcommits.org/) 简化版。

### 格式

```
<类型>: <简短描述>

[可选正文：补充说明，每行不超过 72 字符]

[可选 footer：关联 issue，如 Closes #42]
```

### 类型列表

| 类型 | 含义 | 示例 |
|---|---|---|
| `feat` | 新功能 | `feat: add node collapse toggle` |
| `fix` | 修 bug | `fix: resolve page list not refreshing after delete` |
| `refactor` | 重构（不改行为） | `refactor: split NodeEditorViewModel into engine + service` |
| `style` | 视觉/间距/排版调整，不改逻辑 | `style: adjust collection card corner radius` |
| `test` | 增加或修改测试 | `test: add node indent command unit tests` |
| `docs` | 文档、注释、README | `docs: update mvp scope in readme` |
| `chore` | 依赖更新、构建配置、杂务 | `chore: update swift package dependencies` |
| `wip` | 开发中临时存档 | `wip: node editor engine skeleton` |
| `merge` | 合并时描述被合并分支内容、目的 | `merge: complete the whole mvp features` |

### 规范细则

- 描述用英文，动词开头，小写，不加句号。
- 简短描述控制在 50 个字符以内。
- `wip` commit 仅用于个人分支内部，**不允许出现在 develop 和 main** 的最终历史中（合并前需 squash 或 rebase 整理）。
- 不写无意义的 commit，如 `update`、`fix bug`、`aaa`、`test`。

### 好的示例

```
feat: add collection reorder with sortIndex

Uses fractional sortIndex to support stable ordering without
renormalizing the entire list on every move.

fix: resolve crash when deleting last node on page

Closes #17

refactor: extract NodeQueryService from PageEditorViewModel

Separates tree-building and visibility logic for easier testing.
```

### 坏的示例

```
update stuff          ← 无意义
fix bug               ← 不知道修了什么
wip wip wip           ← 没有描述
final final 2         ← 典型错误
Add feature           ← 首字母大写、加了句号
```

---

## 5. PR / 合并规则

### 5.1 单人开发时的 PR

- develop 直接 push 小改动不需要 PR。
- 较大功能模块（feature/* 分支）建议在 GitHub 创建 PR，哪怕自己 review，也方便：
  - 记录这个功能做了什么
  - 保留 diff 记录，方便后续排查
  - 验收通过后关闭分支更整洁

### 5.2 两人协作时的 PR 要求

**发 PR 前**，开发者本人需确认：

- [ ] 本地已跑通主流程，没有明显崩溃
- [ ] 已 rebase 到最新 develop，解决冲突
- [ ] wip commit 已整理（squash 或 rebase -i 清理）
- [ ] PR 标题符合 commit 规范格式（如 `feat: node editor core complete`）

**PR 描述模板**：

```markdown
## 做了什么
简要说明本次变更的内容。

## 如何测试
1. 步骤一
2. 步骤二
3. 预期结果

## 相关 issue
Closes #xx（如有）

## 备注
需要特别注意的地方，或后续要跟进的内容。
```

**Review 要求**（两人协作时）：

- 对方必须至少看一遍 diff，留一条 comment 或 approve。
- 不允许自己 approve 自己的 PR 后合并（除非对方明确说 LGTM 后无法操作）。
- Review 重点：逻辑是否正确、有没有明显遗漏、数据结构变更是否会影响同步。

### 5.3 合并策略

| 场景 | 策略 |
|---|---|
| feature/* → develop | Squash and merge（压缩成一个 commit） |
| fix/* → develop | Squash and merge |
| develop → main | Merge commit（保留完整历史） |
| hotfix/* → main | Merge commit，同时 cherry-pick 或 merge 回 develop |

---

## 6. 版本 Tag 规范

### 格式

```
vMAJOR.MINOR.PATCH
```

MVP 阶段统一使用 `v0.x.x`，正式上线后视情况升到 `v1.0.0`。

| 字段 | 含义 | 触发时机 |
|---|---|---|
| PATCH | 小修复、UI 微调、文字修改 | 每次修复合并到 main 后 |
| MINOR | 一个完整开发阶段完成 | 工程文档中每个阶段里程碑 |
| MAJOR | 重大重构或正式对外发布 | 慎用 |

### Tag 示例

```
v0.1.0 — M1 Foundation + M2 Collections done
v0.2.0 — M4 Node Editor Core done
v0.2.1 — fix: crash on empty page exit
v0.3.0 — M6 Onboarding & Settings done
v0.4.0 — M7 iCloud Sync Beta done
v0.5.0 — M8 QA & TestFlight release
```

### 打 Tag 的方式

```bash
# 打带说明的 annotated tag（推荐）
git tag -a v0.2.0 -m "M4 Node Editor Core done"

# 推送 tag 到远程
git push origin v0.2.0

# 推送所有本地 tag
git push origin --tags
```

**Tag 和 TestFlight 构建号对应**：每次 TestFlight 发布时，在 Xcode 的 Build 号中写入对应 tag 版本，方便用户反馈 bug 时定位代码版本。

---

## 7. .gitignore 要求

Notte 项目 `.gitignore` 必须包含以下内容：

```gitignore
# Xcode
*.xcuserstate
xcuserdata/
DerivedData/
*.moved-aside
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3

# Swift Package Manager
.build/
.swiftpm/

# macOS
.DS_Store
.AppleDouble
.LSOverride
Thumbs.db

# 调试与测试产物
*.xcresult

# Fastlane（如后续引入）
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots/**/*.png
fastlane/test_output/

# 环境配置（不提交密钥）
*.env
Config.xcconfig
Secrets.swift
```

**绝对不能提交的东西**：

- API Key、CloudKit token、任何认证凭据
- 个人 Xcode 用户配置（`xcuserdata/`）
- 构建缓存（`DerivedData/`）
- `.DS_Store`

---

## 8. 死规则

以下规则不允许在任何情况下破例：

1. **main 禁止直接 push**。只接受从 develop 合并，无论多紧急。
2. **wip commit 不进 develop 和 main**。合并前必须整理干净。
3. **feature/* 和 fix/* 分支完成合并后立即删除**。不留僵尸分支。
4. **同步相关的实验性代码不进 develop**。开专门分支测完再决定是否合并，失败直接删掉分支。
5. **不提交 Xcode 自动生成的用户数据**。`.gitignore` 配好就不会有问题。
6. **tag 只在 main 上打**。不在 develop 或 feature 分支上打版本 tag。
7. **凭据和密钥不进仓库**。包括 CloudKit container identifier 以外的任何敏感配置。

---

## 9. 常用命令速查

### 日常开发

```bash
# 拉取最新代码
git pull origin develop

# 创建功能分支
git checkout -b feature/node-indent-command develop

# 查看当前状态
git status

# 暂存并提交
git add .
git commit -m "feat: add node indent command"

# 推送到远程
git push origin feature/node-indent-command
```

### 合并与清理

```bash
# 合并前先同步 develop
git checkout develop
git pull origin develop
git checkout feature/node-indent-command
git rebase develop

# 推送（rebase 后需要 force push，仅自己的分支）
git push --force-with-lease origin feature/node-indent-command

# 本地删除已合并的分支
git branch -d feature/node-indent-command

# 删除远程分支
git push origin --delete feature/node-indent-command
```

### Commit 整理（合并前清理 wip）

```bash
# 交互式 rebase，整理最近 N 个 commit
git rebase -i HEAD~5

# 在编辑器中把 wip commit 改为 squash (s) 或 fixup (f)
# 保留最上面一个有意义的 commit，其余合并进去
```

### Tag 操作

```bash
# 查看所有 tag
git tag

# 打带说明的 tag
git tag -a v0.2.0 -m "M4 Node Editor Core done"

# 推送指定 tag
git push origin v0.2.0

# 删除错误的 tag（本地 + 远程）
git tag -d v0.2.0
git push origin --delete v0.2.0
```

### 紧急情况

```bash
# 查看最近 commit 历史
git log --oneline -10

# 撤销最后一次 commit（保留文件改动）
git reset --soft HEAD~1

# 临时保存改动切换分支（不想 commit 时）
git stash
git stash pop   # 恢复

# 查看某个文件的改动历史
git log --follow -p -- Sources/Notte/Features/NodeEditor/NodeEditorEngine.swift
```

---

## 附：MVP 阶段分支节奏参考

对应工程文档的 8 个开发阶段，建议按如下节奏操作分支和 tag：

| 阶段 | 分支建议 | Tag |
|---|---|---|
| 阶段 1：工程底座 | develop 直接提交 | — |
| 阶段 2：Collection 模块 | `feature/collection-module` | `v0.1.0` |
| 阶段 3：Page 模块 | `feature/page-module` | `v0.2.0` |
| 阶段 4：Node Editor Core | `feature/node-editor-core` | `v0.3.0` |
| 阶段 5：Node Editor UX | `feature/node-editor-ux` | `v0.3.1` |
| 阶段 6：Onboarding & Settings | `feature/onboarding-settings` | `v0.4.0` |
| 阶段 7：iCloud Sync Beta | `feature/icloud-sync-beta` | `v0.5.0` |
| 阶段 8：QA & Release | `fix/*` 为主 | `v0.5.x` → TestFlight |

---

*本文档随项目演进持续更新。如引入 CI/CD（如 Fastlane + GitHub Actions），另行补充自动化流程章节。*
