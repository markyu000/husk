# Husk 配色文档

> 版本：v1.0 · 日期：2026-05-23
> 主题色：#61FF00 · 灰黑白系沿用 Notte

---

## 一、色彩哲学

Husk 的配色继承 Notte 的纯灰黑白底色系，以荧光草绿 `#61FF00` 作为唯一强调色。

- **底色**：纯黑白，无色偏，与 Notte 共用同一套中性灰
- **强调色**：仅 `#61FF00`，只点在最高优先级的元素上
- **克制原则**：绿色面积越小，张力越强；不用绿色填充大面积背景

---

## 二、完整色板

### 2.1 主题色

| 变量名 | 色值 | 用途 |
|--------|------|------|
| `--husk-green` | `#61FF00` | App 名、主按钮背景、图标强调、active tab、打卡点、数字强调 |
| `--husk-green-dim` | `rgba(97,255,0,0.10)` | 主卡图标背景、绿色微底 |
| `--husk-green-border` | `rgba(97,255,0,0.22)` | 主卡描边 |

### 2.2 Dark Mode（默认）

| 变量名 | 色值 | 来源 | 用途 |
|--------|------|------|------|
| `--bg-primary` | `#000000` | Notte `Label` dark | 页面主背景 |
| `--bg-secondary` | `#1C1C1E` | Notte `SecondaryBackground` dark | 卡片、surface |
| `--border` | `#3A3A3C` | Notte `SecondaryLabel` dark | 分割线、描边 |
| `--text-primary` | `#FFFFFF` | Notte `Label` dark | 主文字 |
| `--text-secondary` | `#636366` | Notte `TertiaryLabel` dark | 次级文字、muted |

### 2.3 Light Mode

| 变量名 | 色值 | 来源 | 用途 |
|--------|------|------|------|
| `--bg-primary` | `#FFFFFF` | Notte `Label` light | 页面主背景 |
| `--bg-secondary` | `#F5F5F5` | Notte `SecondaryBackground` light | 卡片、surface |
| `--border` | `#E0E0E0` | Notte `SecondaryLabel` light | 分割线、描边 |
| `--text-primary` | `#000000` | Notte `Label` light | 主文字 |
| `--text-secondary` | `#8E8E93` | Notte `TertiaryLabel` light | 次级文字、muted |

---

## 三、Swift 变量定义

```swift
extension Color {
    // 主题色
    static let huskGreen = Color(red: 97/255, green: 255/255, blue: 0/255)

    // 语义色（自适应 light/dark）
    static let huskBackground      = Color(.systemBackground)
    static let huskSecondary       = Color(.secondarySystemBackground)
    static let huskBorder          = Color(.separator)
    static let huskTextPrimary     = Color(.label)
    static let huskTextSecondary   = Color(.tertiaryLabel)
}
```

> `systemBackground` / `secondarySystemBackground` / `separator` / `label` / `tertiaryLabel`
> 均为 iOS 原生语义色，与 Notte 的 Contents.json 完全对应，自动适配深浅色。

---

## 四、使用规则

### 绿色使用场景（允许）

- App 名 `Husk` 文字
- 主操作按钮背景（开始复习）
- 当前 Tab 图标
- 主卡左侧图标背景（10% 透明度）及描边（22% 透明度）
- 强调数字（复习数量）
- 连续打卡圆点
- 答题正确反馈色

### 绿色禁止场景

- 大面积背景填充
- 次级按钮
- 非强调文字
- 图标默认态（未选中 tab、普通操作图标）

### 主按钮文字色

主按钮（绿底）的文字用 `#052000`（深墨绿），而非纯黑 `#000000`。
保持色相统一，避免纯黑在绿底上显得割裂。

---

## 五、与 Notte 的关系

| | Notte | Husk |
|---|---|---|
| 底色系 | 纯灰黑白 | 同上，完全共用 |
| 主题色 | `#FFD60A` 铬黄 | `#61FF00` 荧光草绿 |
| 色相关系 | — | 邻近色，同属"酸亮"糖果色系 |
| 家族感 | 温暖、思考 | 清醒、生长 |

两个 App 放在同一个界面（如系统设置、Spotlight）时，主题色互为邻近色，有家族感但各自独立。
