---
name: web-video-presentation
description: >
  口播节拍驱动的交互式叙事编排系统：将文章/口播稿转为可录屏的 16:9 网页演示。

  【核心约束（不可违反）】
  ✓ step = 节拍（每屏一个聚焦想法，narrations.ts 是时间轴唯一真相源）
  ✓ outline 只规划信息架构，不写动画（防止 AI 退化为模板翻译机）
  ✓ 第 1 章必须主线程完成并验收（作为后续章节的风格 anchor）
  ✓ Checkpoint 硬节点不可跳过（Plan / Audio 两个用户对齐点）
  ✓ 每个产出物完成后必须走 Validation Protocol（script → outline → chapter）

  适用场景：视频式网页演示 / B站 YouTube 抖音录屏教程 / 电影感产品 demo /
  talk 展示 / 将口播稿或文章转为可交互的解说内容。
---

# Web Video Presentation

把一篇文章或口播稿，一步步做成可录屏的"伪装成视频的网页"，可选合成口播音频。
产出物 = Vite + React + TS 项目 + 按章节切分的音频。

## 适用场景

- "我有口播稿 / 一篇文章，帮我做成视频" —— 口播驱动的内容
- 想做"动态 PPT"，16:9 横屏录屏，大字、留白、每屏都要有动效
- 教学 / 产品演示 / keynote 想要电影感
- B 站 / YouTube / 抖音视频内容

---

## 工作流总览

```
Phase 0   启动前准备（条件执行）
   判断：article.md 是否已存在？
   ├─ ✅ 存在（用户提供的干净版本）→ 跳过，直接进 Phase 1
   └─ ❌ 不存在（只有 article-full.md 等原始素材）→ 【硬节点⚠️】必须执行：
       0.1  按 presets 模板对原始素材预处理
       0.2  清理噪音、补全结构并提取视觉素材
       0.3  产出 article.md + MATERIAL-INDEX.md
       ▼ 通过 Phase 0 验收清单后才能进入 Phase 1
Phase 1   内容编写
   1.1  识别用户输入
   1.2  一次产出 script.md + outline.md
   ▼
[Checkpoint Plan] ← 硬节点，5 件事一次对齐
   ▼
Phase 2   网页开发
   2.1  脚手架（按选定主题）
   2.2  第 1 章 = 主线程 + 完整版本（强制 anchor）
        ▼ 用户验收第 1 章（有降级路径，见下文）
   2.3  第 2~N 章（按选定模式 A / B / C）
   ▼
[Checkpoint Audio] ← 硬节点，是否合成音频
   ▼
Phase 3   音频合成（可选）
   ▼
Phase 4   录屏 + 后期
```

工作目录约定：

```
my-video/
├── article.md          # 用户给原文时必有 —— 不删！开发阶段画面信息源
├── script.md           # 必有：B 站风格口播稿（决定节拍）
├── outline.md          # 必有：开发计划（章节切分 + 每步内容 + 信息池）
└── presentation/       # 脚手架产出的 Vite + React + TS 项目
    ├── src/chapters/<NN>-<id>/
    │   ├── <Chapter>.tsx     # 视觉实现
    │   ├── <Chapter>.css
    │   └── narrations.ts     # ★ step 数 + 口播文本的唯一真相源
    ├── scripts/
    │   ├── extract-narrations.ts
    │   └── synthesize-audio.sh
    ├── audio-segments.json
    └── public/audio/<id>/<N>.mp3
```

> **关键**：`narrations.ts` 是 step 数和音频合成的**唯一真相源**。
> 章节 `.tsx` 里 `if (step === N)` 出现的最大 N + 1 必须等于 `narrations.length`。

---

## Phase Router

> **核心原则：当前任务只加载当前 Phase 的规则。不读 = 不污染注意力。**

```
我在做什么？                    →  读哪个 Phase？
─────────────────────────────────────────────────
处理原始文章 / 清理噪音          →  Content Phase
写 script.md + outline.md       →  Content Phase（同上）
写完 script/outline             →  Boundary: Checkpoint Plan
实现一个章节的 TSX + CSS        →  Chapter Phase ← 最频繁操作
章节全部完成                    →  Boundary: Checkpoint Audio
合成音频 / 录屏                  →  Production Phase
修 bug / 排查问题               →  按错误类型查 Failure Owner Map（CHAPTER-RULES-MINI §3）
```

---

## Shared Contract（全局约束摘要）

> 以下规则跨 Phase 生效，所有 Phase 都要遵守。**详细定义在对应 references 文件中，此处仅摘要。**

| 契约 | 摘要 | 详细定义 |
|------|------|---------|
| **H1-H7 硬规则** | STEP-SYNC / FOCUS / ADDITIVE / NO-OVERLOAD / REVEAL / TRUTHFUL / VALID | `CHAPTER-RULES-MINI §1` |
| **T1-T5 架构约束** | 16:9 固定画布 / step 纯函数 / FullScene / opacity:0 默认 / 无 header-footer | `SKILL.md §覆盖与安全` → 详见 `CORE-PRINCIPLES.md` |
| **Checkpoint 不可跳过** | Plan（5 件事对齐）和 Audio（是否合成）必须停等用户确认 | Boundary 节点 |
| **Validation 必须跑** | 产出物 → 自检 → 修复 → 再汇报（不允许带 fail 项汇报） | `SKILL.md §Validation Protocol` |
| **Failure Owner Map** | 出了问题按坑类型找 owner 文件，不全文搜索 | `CHAPTER-RULES-MINI §3` |
| **覆盖与安全** | T1-T5 不可覆盖；开发模式/音频/主题/单章设计可覆盖（需显式确认） | `SKILL.md §覆盖与安全` |

---

## Content Phase（文章 → 口播 → 大纲 → 素材）

### 加载清单

| | 内容 |
|---|------|
| **什么时候进** | `article.md` 不存在，或用户给了原始素材；写 `script.md` + `outline.md` |
| **目标产出** | `article.md` + `script.md` + `outline.md` + `MATERIAL-INDEX.md` |
| **必读** | `references/ARTICLE-PROCESS-GUIDE.md` + 匹配的 `presets/` 模板 |
| **必读** | `references/SCRIPT-STYLE.md` + `references/OUTLINE-FORMAT.md` |
| **禁读** | ❌ CHAPTER-RULES-MINI（视觉规则与内容准备无关）<br>❌ ANCHOR-CARD（还没到章节实现）<br>❌ primitives 组件表<br>❌ AUDIO.md / RECORDING.md |
| **验收** | Phase 0 验收清单 → Validation Protocol → 进 Checkpoint Plan |

### Phase 0 —— 启动前准备（条件执行）

> 仅当 `article.md` **不存在**时执行，否则跳过。
> 详细操作见 [`references/ARTICLE-PROCESS-GUIDE.md`](references/ARTICLE-PROCESS-GUIDE.md)

**Phase 0 产出验收清单**（agent 自检后告知用户再进入 Phase 1）：

- [ ] `article.md` 每 H2 至少 3 个视觉元素
- [ ] `MATERIAL-INDEX.md` 按章节编号索引，每章有可用素材路径
- [ ] 无 HTML 标签 / 引流语 / 广告文案残留
- [ ] 字数：原始素材的 60%~80%（超出 = 过度压缩，触发 R11 风险）
- [ ] 结构完整，H2 层级与内容主干匹配

> ⚠️ 预处理风险：过度压缩（R11）/ presets 不匹配（R12）详见 `WORKFLOW.md §十一`

### Phase 1 —— 内容编写

#### 1.1 识别用户输入

| 用户给的内容 | 操作 |
|-------------|------|
| 含噪音的原始文章（公众号/掘金/带 HTML） | ⚠️ **先走 Phase 0** 预处理 → 产出 `article.md` → 再进 1.2 |
| 干净文章（`article.md` 已存在） | 直接进 1.2 |
| 直接的口播稿 / 视频脚本 | 落盘 `script.md`，简化版 `outline.md`，过 Checkpoint Plan |
| 啥都没有，只说"帮我做个 X 主题的视频" | **反问**：先给一段素材或大纲。Skill 不替用户构思内容 |

#### 1.2 一次产出 script.md + outline.md

1. **`script.md`**：按 [`references/SCRIPT-STYLE.md`](references/SCRIPT-STYLE.md) 转 B 站风口播稿，**保留 `article.md` 不删**
2. **`outline.md`**：按 [`references/OUTLINE-FORMAT.md`](references/OUTLINE-FORMAT.md) 切章节 + 切 step + 每章首段抽信息池

**outline 边界**：只写"什么"（章节/step/信息池），不写"怎么做"（动画类型/CSS 实现/时长数值）。

落盘后先走 Validation Protocol，修复完再进入 Boundary: Checkpoint Plan。

---

## Boundary 1: Checkpoint Plan（Content → Chapter）

> 🚧 **HARD STOP: 不得进入 Chapter Phase，直到用户确认。**

### 预备工作

1. 读所有 `themes/*/theme.json`，拿 `nameZh` / `descriptionZh` / `bestFor` / `mood`（不硬编码清单）
2. 根据 `script.md` 内容类型主动推荐 2~3 套最匹配主题
3. 扫 `outline.md` 末尾素材清单

##### 5 件事对齐模板

```
内容计划写完，产出文件：
  📄 script.md      {X} 字 / ~{T} 分钟
  📄 outline.md     {N} 章 / {M} 步 + 每章信息池 + 末尾素材清单

章节速览：
  1. <id>  <章节标题>  <S> 步 ~<T>s
  2. ...

一次对齐 5 件事：

  1. 稿子 (script.md) 要不要改？
  2. 开发计划 (outline.md) 要不要改？（章节切分/step 数/信息池/素材清单）
  3. 选哪个主题？推荐：
     ★ <推荐1：nameZh (id)> — 因为 <bestFor 命中>
     ★ <推荐2 / 推荐3>
     其它：<剩余主题一句话>；或让我帮你造新主题（见 references/THEMES.md）
  4. 真素材怎么准备？<粗略清单>
     a) 从现有素材帮你挑  b) 你自己提供  c) 全部 placeholder
  5. 开发模式：
     A) 逐章确认（默认/推荐）   B) 顺序开发   C) 并行 subagent（最快）
     第 1 章无论哪种模式都必须主线程完成并验收。
```

> 💡 **主题必须明确**才进 Chapter Phase。用户说"你帮我选"→ 取推荐第 1 个，告知并给反悔机会。

---

## Chapter Phase（Ledger → Signature Move → React 实现）⭐ 最频繁

### 加载清单

| | 内容 |
|---|------|
| **什么时候进** | 实现或修改任何一个章节的 TSX + CSS |
| **目标产出** | `<Chapter>.tsx` + `<Chapter>.css` + `narrations.ts` + Final Ledger |
| **必读** | `references/CHAPTER-RULES-MINI.md`（H1-H7 + H1-b + Narration Gate §2.5 + Ledger 模板 + Anti-patterns） |
| **必读** | `references/EXAMPLES/<匹配类型>/ANCHOR-CARD.md`（开工前必读） |
| **必读** | 当前章 `outline.md` 片段 + `MATERIAL-INDEX.md` 本章条目 + `theme.json` |
| **必读** | `references/SCRIPT-STYLE.md`（narrations 文本质量的唯一规则来源，写/改 narrations 时必须加载） |
| **禁读** | ❌ ARTICLE-PROCESS-GUIDE（内容已准备好）<br>❌ OUTLINE-FORMAT（outline 已定稿）<br>❌ AUDIO.md / RECORDING.md（生产阶段规则）<br>❌ 其他章节的代码（只看第 1 章作为风格 anchor） |
| **按需** | `src/components/patterns/` 组件源码（API 卡住时才查）<br>`references/CHAPTER-CRAFT.md`（第 1 章必读完整版；第 2~N 章只读 Part 0） |
| **开工动作** | 先执行 **Narration Gate（CHAPTER-RULES-MINI §2.5，6 条硬门槛）** → 输出 Draft Step Focus Ledger → 确认后再写代码 |
| **完工动作** | 输出 Final Ledger + Narration Gate G1-G6 结果 + 跑 `npm run validate` |

> **⚠️ Chapter Phase 是最高频操作（每章一次 × N 章）。** 严格遵循"禁读"列表是节省 token 的关键。
> 第 1 章额外需读 `CHAPTER-CRAFT.md` 完整版（含教程式解释）；第 2~N 章可省略。

### Phase 2 —— 网页开发

#### 2.1 脚手架

```bash
bash <path-to-skill>/scripts/scaffold.sh ./presentation --theme=<主题id>
bash <path-to-skill>/scripts/scaffold.sh --list-themes

# 删除 demo 章节
rm -rf presentation/src/chapters/01-example
# 同时移除 chapters.ts 里的 EXAMPLE_CHAPTER import 和数组项
```

自定义主题见 [`references/THEMES.md`](references/THEMES.md)。

#### 2.2 第 1 章 —— 主线程 + 强制验收

第 1 章 = 完整版本一次到位（节奏 + 视觉 + 素材齐全），**没有"骨架版"概念**。
必须读完整版 [`references/CHAPTER-CRAFT.md`](references/CHAPTER-CRAFT.md)。

做完停下来，输出验收提示：

```
第 1 章 <id> 做完了，dev server 在 localhost:5173 运行。

验收重点：
  □ 视觉气质对不对？符合 <theme nameZh> 的预期吗？
  □ 节奏对不对？某些步太快 / 太慢 / 信息太薄？
  □ 内容驱动动画是否到位？还是有几步是无脑入场动画？
  □ 双源原则：屏幕画面有没有"口播没念但 article 能挂"的细节？
  □ 反 AI 味：紫粉渐变 / 圆角彩色边框 / 假插画 / emoji 是否有？
```

##### 第 1 章验收失败降级路径

| 验收轮次 | 策略 |
|---------|------|
| 第 1 次失败 | **定点修改**：用户描述问题，按最小切片原则针对性改（不重做整章） |
| 第 2 次失败 | **检查主题匹配**：主题选择是否符合内容气质？必要时换主题重做 |
| 第 3 次失败 | **回退 Checkpoint Plan**：重审 outline / 主题 / 素材，重新对齐后再开发 |

#### 2.3 第 2~N 章 —— 按选定模式

所有模式共同规则：每章独立按 [`CHAPTER-RULES-MINI.md`](references/CHAPTER-RULES-MINI.md) + 匹配的 [ANCHOR-CARD.md](references/EXAMPLES/) 开发。
主题 token 统一气质，章节动画/节奏自由发挥（风格差异是预期，不是 bug）。

##### Pattern Primitives（省力工具箱）

> **目标：70% 复用 primitive 减少杂活 + 30% 手写保留本章灵魂。**
> 组件只承载工程重复，不承载创意决策。

| 层级 | 组件 | 状态 | 用途 | 使用规则 | 数量限制 |
|------|------|------|------|---------|---------|
| **低层** | `ChapterShell` | ✅ 可用 | 全屏居中容器 | 默认使用 | 不限 |
| **低层** | `Kicker` | ✅ 可用 | 48px 章节提示文字 | 默认使用 | 不限 |
| **高层** | `SlotGrid` | ✅ 可用 | ghost/active/dim 三态网格 | **只能作为起点，必须做本章变体** | **每章最多 1 个高层 primitive** |
| **高层** | `FlowStrip` | ✅ 可用 | 流程节点 + 箭头 | **只能作为起点，必须做本章变体** | 同上 |
| 高层 | `MetricCard` | *待实现* | 数字 + 单位 + 标签卡片 | — | 同上 |
| 高层 | `TerminalWindow` | *待实现* | 终端/代码窗口 | — | 同上 |
| 高层 | `MegaBadge` | *待实现* | 大数字 takeover | — | 同上 |

> **低层** = 无视觉语义的纯工程组件（容器、排版），默认复用。
> **高层** = 自带视觉语法的 pattern（网格、流程、终端），如果直接用会让章节模板化。
> **数量规则**：每章最多选 **1 个** 高层 primitive 作为骨架。其余视觉必须手写（Signature Move）。
> 每章必须在 Draft Ledger 中定义 **Signature Move**（见 CHAPTER-RULES-MINI §2）——这是高层 primitive 无法替代的唯一记忆点。

**参考示例（list-reveal 起步 → SlotGrid 变体）：**
```tsx
import { ChapterShell, Kicker, SlotGrid } from "../../components/patterns";
import type { SlotItem } from "../../components/patterns";

const ITEMS: SlotItem[] = [
  { num: "01", label: "术语", desc: "具体困惑描述" },
];

export function MyChapter({ step }: ChapterStepProps) {
  if (step === 1) return (
    <ChapterShell>
      <SlotGrid items={ITEMS} activeIndices={[0]} columns={3} />
    </ChapterShell>
  );
}
```



##### 模式 A · 逐章确认（默认）

每章做完暂停验收 → OK → 下一章。**用户未明确选模式时走此路径。**

##### 模式 B · 顺序开发

第 2~N 章主线程顺序做完后统一验收。适合不支持并行的环境。

##### 模式 C · 并行 subagent

用 subagent 并行做第 2~N 章，最大并行数由用户指定。

**并行 subagent 必须包含的上下文：**

<details>
<summary>📋 Mode C subagent prompt 模板（点击展开，复制后填空）</summary>

```markdown
你是一个章节开发 subagent，负责独立实现第 {N} 章，**不修改 chapters.ts**。

## 本章任务
章节 ID：`{chapter_id}`
完工后跑 `npx tsc --noEmit`（0 error 才算完成）。

## 本章 outline 段落
{粘贴 outline.md 中本章完整段落，含信息池}

## 主题气质参考
- descriptionZh: {theme.json.descriptionZh}
- mood: {theme.json.mood}
- bestFor: {theme.json.bestFor}
（动画/时长/字号/emoji 由你自由决定，不要机械对齐第 1 章）

## 第 1 章设计决策卡（风格参考，非复制对象）
- 演示手法：{CSS数字动画 / SVG对比图表 / 流程图 / ...}
- 动画基调：{利落线性~400ms / 弹簧overshoot / 电影感慢~1.5s}
- 字号层级：hero {N}px / 副标 {N}px / cue {N}px
- 颜色策略：{--text 为主 + --accent 点缀 / ...}
- 信息密度：{屏幕信息 > 口播信息，通过...落地双源原则}

## 素材
查阅项目根目录 `MATERIAL-INDEX.md` 本章条目，不需要全读 article.md。

## 硬规则（必须遵守）
- CSS 前缀：本章专属前缀（如 `.cd-` / `.mg-` / `.pm-`），禁止跨章污染
- 必读：`references/CHAPTER-RULES-MINI.md`（硬规则速查，~100 行）
- 必读：`references/EXAMPLES/` 中匹配本章类型的 ANCHOR-CARD.md（卡住才读 README + 代码）
- 完工自检：跑 `npm run validate`，fail 项修复后才算完成
```
</details>

#### 2.4 实现单章（每章必走）

**开工前必须先产出 Draft Step Focus Ledger**（防跑偏，在对话中输出即可）：

```
Draft Step Focus Ledger:
  S0: [ROLE-TAG]   焦点=____  预期密度=轻(2~3元素)  解释力=口播说X，画面补充Y
  S1: [ROLE-TAG]   焦点=____  预期密度=中(3~5元素)  解释力=口播说X，画面补充Y
  S2: [ROLE-TAG]   焦点=____  预期密度=中(3~5元素)  解释力=口播说X，画面补充Y
  ...

ROLE-TAG 枚举：EMOTION-HOOK | CONTRAST-REVEAL | STAMP-OST | TAKEOVER | TEASER | LIST-REVEAL | SINGLE-PROOF | PROCESS-MAP | CUSTOM

密度评级：轻 ≤3 / 中 3~5 / 重 >5（重 = ⚠️ 必须在 Draft 阶段确认是否拆步）
解释力：每步必须写明"口播说了什么，画面额外补充了什么"（Y 必须是口播没念的具体细节/数据/对比/机制）
```

> ⚠️ 任何 Step 预期密度为"重"（>5 元素）时，必须在 Draft 中标记 ⚠️ 并等待用户确认后才能开工。

**开工前按顺序读以下文件（不可跳过）：**

> narrations.ts 是运行时真相，outline.md 是规划参考。实际 step 数 > outline → 更新 outline 对齐，不回退。
> **但**：若实际 step 数 < outline 声明的 **80%**（偏差 > 20%），必须**停下并告知用户确认**后再继续（Narration Gate G4）。
> 静默接受大幅缩减会纵容信息丢失（失败案例：某项目偏差 58% 时信息保留率仅 7%，详见 CHAPTER-RULES-MINI §2.5）。

1. **`references/CHAPTER-RULES-MINI.md`** — 每章必读（硬规则速查，~100行）
2. **`references/EXAMPLES/<匹配章节类型的anchor>/ANCHOR-CARD.md`** — 必读卡（~20行），卡住才读 README+代码
3. **[双源落地] 回 article.md 抽取本章额外信息**
   - 触发条件、动作、输出、标准与范例保持不变（保持现有内容）

> ⚠️ **第 1 章**额外读 `references/CHAPTER-CRAFT.md` 完整版（含教程式解释）；第 2~N 章可只读 CHAPTER-CRAFT Part 0 十条原则

##### 章节类型 → EXAMPLES anchor 映射表

| 本章类型 | 特征 | 必看 anchor | 替代方案 |
|---------|------|-----------|---------|
| **hook / 开场钩子** | 抛反例/截图→引出主题→大字 takeover | [`EXAMPLES/hook-chapter/ANCHOR-CARD.md`](references/EXAMPLES/hook-chapter/ANCHOR-CARD.md)（卡住读 README+代码） | 无 |
| **list-reveal / 列举展开** | 清单项/排行榜/对比列表逐个揭示 | [`EXAMPLES/list-reveal/ANCHOR-CARD.md`](references/EXAMPLES/list-reveal/ANCHOR-CARD.md)（卡住读 README+代码） | 无 |
| **case-tech-review / 测评对比** | 多产品/方案横向对比 | [`EXAMPLES/case-tech-review/ANCHOR-CARD.md`](references/EXAMPLES/case-tech-review/ANCHOR-CARD.md)（卡住读 README+代码） | 参考 hook-chapter 的 takeover 模式 |
| **其他 / 自定义** | 不匹配以上类型 | 通读所有 EXAMPLES 取灵感 | 从 CHAPTER-CRAFT.md Part 1 五问开始设计 |

#### 2.5 大改后 bump STORAGE_KEY

改动 `chapters.ts`（增/删/重排章节，或某章 `narrations.ts` 长度变化）后，
**bump** `presentation/src/hooks/useStepper.ts` 的 `STORAGE_KEY`（如 `v4` → `v5`），
避免持久化游标落到不存在的 step 上。

> ⚠️ 此项当前未被 `validate.sh` 覆盖，**必须人工执行**，不得遗漏。

#### 2.6 章节完成后验证

```bash
cd presentation && npm run validate
```

自动检查：narrations 对齐 / TypeScript 编译 / 字号下限 / CSS prefix 隔离 / 动画时长 ≤ 口播时长。
详见 [`references/VALIDATION.md`](references/VALIDATION.md)。

**validation fail 时禁止进入下一章。**

**章节完成后还需输出 Final Step Focus Ledger**（Draft→Final 对比自证）：

```
Final Step Focus Ledger:
  S0→轻(2) ✅ 解释力=中（画面仅重复口播，增量少）
  S1→中(4) ✅ 解释力=强（术语映射/对比卡，口播未念）
  S2→中(4) ✅ 解释力=强（金额/周期量化，口播未念）
  S3→轻(3) ✅ 解释力=中（10x数字+机制cue，可再充实）
  过载步=0/4(0%)

  Draft→Final 偏离说明：无
  解释力短板：S0/S3 画面对口播的解释不够扎实，S0缺视觉钩子，S3缺机制深度
```

> Draft→Final 对比是 Agent 自我校准的证据。Final 与 Draft 严重偏离需解释原因。过载步（>5 foregroundUnits）必须在 Final 中显式标注 ⚠️。
> **解释力检查**：逐屏对照 narrations，确认画面补充了口播未念的增量信息。若某步画面只是口播的文字版 → 标记为"解释力=弱"，需补充增量元素。

---

## Boundary 2: Checkpoint Audio（Chapter → Production）

> 🚧 **HARD STOP: 不得进入 Production Phase，直到用户确认。**

```
网页做完，{N} 章 {M} 步，dev server 在 localhost:5173 跑着。

要不要合成音频做"自动播放录屏"？
  ✓ 合成 → 扫所有章节 narrations.ts 出 audio-segments.json，
           调 mmx-cli 合成每步一个 mp3 到 public/audio/。
           合成完后 ?auto=1 模式可一镜到底录屏（音视频天然同步）。
           本机没装 mmx 会问你用什么 TTS（详见 references/AUDIO.md §降级路径）。
  ✗ 不合成 → 跳过 Phase 3，直接 Phase 4 手动录屏 + 后期配音。
```

---

## Production Phase（narrations → validate → audio → 录屏）

### 加载清单

| | 内容 |
|---|------|
| **什么时候进** | 所有章节完成后，进入合成/发布流程 |
| **目标产出** | `audio-segments.json` + mp3 文件 / 录屏文件 |
| **必读** | `references/AUDIO.md`（Phase 3 合成时）<br>`references/RECORDING.md`（Phase 4 录屏时） |
| **必读** | `scripts/validate.sh`（每次跑 validation 时参考检测项含义） |
| **禁读** | ❌ ARTICLE-PROCESS-GUIDE / SCRIPT-STYLE / OUTLINE-FORMAT<br>❌ CHAPTER-RULES-MINI §2 Ledger 模板（不再设计新章节）<br>❌ ANCHOR-CARD / primitives 组件表<br>❌ CHAPTER-CRAFT.md |
| **按需** | `references/VALIDATION.md`（validate 报错时查修复建议） |

### Phase 3 —— 音频合成（可选）

详细流程见 [`references/AUDIO.md`](references/AUDIO.md)。简版：

```bash
cd presentation
npm run extract-narrations   # 扫所有 narrations.ts → audio-segments.json
# 让用户扫一眼 audio-segments.json 确认文本
npm run synthesize-audio     # 调 mmx 串行合成；增量、跳过已存在
```

合成完告知：输出位置 / 总段数 / 时长异常段（太长 = 该 step 拆分；太短 = 文案太薄）。

### Phase 4 —— 录屏 + 后期

详见 [`references/RECORDING.md`](references/RECORDING.md)。

| 场景 | 推荐路径 |
|------|---------|
| Phase 3 已合成音频 | **Auto 模式**：`localhost:5173/?auto=1` → 按 SPACE → 整片自动播完 → 裁头尾即成片 |
| Phase 3 跳过 | **Manual 模式**：手动点击推进 → 后期工具配音 |

---

## Validation Protocol

每个产出物完成后：**validate + 自检 → 修复 → 再汇报**（不允许带 fail 项汇报）。

| 产出 | 自检文件 | 程序化检测 |
|------|---------|-----------|
| `script.md` | `references/SCRIPT-STYLE.md` 三层自检 | — |
| `outline.md` | `references/OUTLINE-FORMAT.md` 自检 | — |
| 单章实现完成 | `references/CHAPTER-RULES-MINI.md` §7 完工自检清单（9 项） | `npm run validate`（C1/C2/C4/C6/C7） |

**执行方式**（按能力降级）：Agent Teams → subAgent → self review

---

## 覆盖与安全

**不可覆盖（物理定律）**：T1-T5 架构硬约束 + narrations 对齐 + Checkpoint 硬节点 = 永远生效。

**可覆盖（需显式确认）**：开发模式 / 是否合成音频 / 主题切换 / 单章设计细节。

**确认格式**（agent 收到模糊指令时引导用户使用）：
```
我确认要 [动作]，因为 [原因]
```

✅ 有效：`我确认要跳过音频合成，因为这只是预览版`
❌ 模糊：`不做音频了` → agent 应澄清："您是要跳过音频合成吗？请回复'确认跳过音频'"

**架构硬约束速查**（完整代码级要求见 [`references/CORE-PRINCIPLES.md`](references/CORE-PRINCIPLES.md)）：

| # | 约束 | 违反后果 |
|---|------|---------|
| T1 | 16:9 固定画布，`transform: scale()` 缩放，禁 media query / 流式布局 | 录屏变形 / 动画坐标错位 |
| T2 | 章节是 step 的纯函数，禁 `setTimeout`/`setInterval` | 节奏失控 / Auto 模式崩溃 |
| T3 | 每步独占整屏（`<FullScene />`），禁条件渲染部分元素 | 视觉混乱 / 节拍模糊 |
| T4 | 控件默认 `opacity:0`，hover/active 时 `opacity:1`，禁 `display:none` | 录屏残留 UI |
| T5 | 舞台无 header / footer / 页码 / 导航栏 | 空间浪费 / 不像电影感 |

---

## 相关资源索引

### 必读（对应 Phase 必须读）

| 文件 | 何时读 | 内容 |
|------|-------|------|
| `references/ARTICLE-PROCESS-GUIDE.md` | Content Phase 必读 | 处理杂乱原始素材的通用预处理指南 |
| `references/SCRIPT-STYLE.md` | Content Phase 必读 | 文章 → 口播稿规则、平台变体 |
| `references/OUTLINE-FORMAT.md` | Content Phase 必读 | outline.md 字段 spec、命名约定、信息池 |
| `references/CHAPTER-RULES-MINI.md` | Chapter Phase 必读 | H1-H7 + Ledger 模板 + Anti-patterns |
| `references/CHAPTER-CRAFT.md` | Chapter Phase 第 1 章必读 | Part 0~8 全部内容 |
| `MATERIAL-INDEX.md` | Chapter Phase 每章必读 | 项目根目录，article.md 按章节索引 |
| `references/AUDIO.md` | Production Phase 必读 | mmx-cli、TTS 降级路径、故障排查 |
| `references/RECORDING.md` | Production Phase 必读 | 录屏工具 + 后期合成 |

### 按需（卡住或报错时查）

| 文件 | 何时读 | 内容 |
|------|-------|------|
| `references/presets/` | Content Phase 选读 | 各类内容题材的预处理规则模板 |
| `references/EXAMPLES/` | Chapter Phase 每章开工前必看 | 章节结构示意（形参考，不照抄内容） |
| `references/THEMES.md` | Checkpoint Plan 时 | 完整 token 契约 + 内置主题清单 + 创作流程 |
| `references/VALIDATION.md` | validate 报错时 | 检测项详解、C6 动画时长说明、修复建议 |
| `references/CHAPTER-CRAFT-CHEATSHEET.md` | 按需参考 | 视觉分级库 / 决策树 / 安全区检测 |
| `themes/` | Checkpoint Plan 时翻 | 内置主题（每个含 `theme.json` + `tokens.css`） |
| `scripts/scaffold.sh` | Chapter Phase 脚手架 | 一键项目脚手架 |
| `scripts/validate.sh` | Chapter Phase 每章完成后 | 自动化校验脚本（C1/C2/C4/C6/C7） |

### 历史 / 参考（理解设计决策时）

| 文件 | 何时读 | 内容 |
|------|-------|------|
| `references/CORE-PRINCIPLES.md` | 想理解"为什么"时 | 5 条高层原则 + T1-T5 完整代码约束 |
| `references/DESIGN-DECISIONS.md` | 边界情况 / 首次使用 | 设计决策理由（双源/outline边界/anchor/并行/validate） |
| `WORKFLOW.md` | 工作流细节 / 风险排查时 | 风险矩阵 R1-R13 / 工作流补充 |
