# `outline.md` 格式 spec

视频章节规划的产出文件。**用户可以直接编辑**，所以格式必须人类友好
（用 markdown 不用 JSON / YAML）。

!重要：阅读此文件后必须继续阅读 [`CHAPTER-CRAFT.md`](CHAPTER-CRAFT.md) 的全部内容，了解对网页效果的真实需求，然后再开始编写 outline

> ## ⚠️ outline 是开发计划，不是视觉规划
>
> outline 只规划**节奏 + 内容 + 信息密度**：
>
> - 章节切分 / 每章 step 数 / 每步估时
> - 每步屏幕内容（hero / 标语 / 数据 / 列表项）
> - 章节级**信息池**（从 article 抽的数字 / 引用 / 案例 / 标签）
>
> **outline 里的 step 数是初始预估**。最终 step 数以章节实现时的
> `narrations.ts` 为准——后者既是 step 数源，也是音频合成源
> （详见 [`CHAPTER-CRAFT.md`](CHAPTER-CRAFT.md) 「代码层最小约束」+
> [`AUDIO.md`](AUDIO.md)）。如果实现时章节 step 数和 outline 不一致，
> 回过来同步 outline 即可，不需要纠结"对得严丝合缝"。

> **写 outline 前必读**（双源原则，[CHAPTER-CRAFT.md Part 0 原则 10](CHAPTER-CRAFT.md#10-双源原则scriptmd-定节拍--articlemd-定画面密度)）：
>
> - **`script.md`** —— 决定**节拍**：按 `---` 切节拍，每节拍 1~2 step、估时
> - **`article.md`**（如有）—— 决定**画面信息密度**：每章首段抽**信息池**

---

## 抽象示例（看格式）

````markdown
# Video Outline

> **主题**：`<theme-id>`（Checkpoint Plan 已选定）—— <一句话风格描述>
> **总时长**：约 <T> 分 <S> 秒（口播 ~<X> 字 ÷ 4 字/秒）
> **章节数**：<N> 章 / <M> 步

---

## 1. <chapter-id> — <章节标题>（<S> steps · ~<T>s）

**信息池**（chapter agent 按需挂角标 / 副标 / pull-quote / mono cue）：
- <类型：数字 / 引用 / 出处 / 案例 / 词义 / 时间 / 对比 / ...>：<内容> —— <来源 article §X / Lxx>
- ...

**开发计划**：

- step 1 (~Ts) — <屏幕内容>
- ...

口播节选：
> <1~3 句节选，对应到 script.md 完整文本>

---

## 2. <chapter-id> — ...
````

> **关于时长**：outline 里**只**写 step 的 `(~Ts)` 口播估时（音画对齐
> 用），**绝对不写**动画时长 / 错峰量 / keyframe 数值。这些都在章节开发
> 阶段决定（[`CHAPTER-CRAFT.md`](CHAPTER-CRAFT.md) Part 3 时长参考）。

> **想看具象示例**：
> - 钩子型开场结构 → [`EXAMPLES/hook-chapter/`](EXAMPLES/hook-chapter/)
> - 列举型章节结构 → [`EXAMPLES/list-reveal/`](EXAMPLES/list-reveal/)
> - 科技测评类（实测 / 对比 / 跑分） → [`EXAMPLES/case-tech-review/`](EXAMPLES/case-tech-review/)

---

## 字段约定

### 顶部 metadata block

用引用块（`>`）形式，方便扫一眼整体规模：

| 字段 | 必填 | 说明 |
|---|---|---|
| **主题** | ✓ | Checkpoint Plan 必须已选定。chapter agent 实现时按主题颜色 / 字体 token 走，动画 / 节奏 / 视觉演示由章节自由发挥 |
| **总时长** | ✓ | 估算口播时长（中文 ~ 250 字 / 分钟） |
| **章节数** | ✓ | `N 章 / M 步` |

### 章节标题：`## N. <id> — <title>（<S> steps · ~<T>s）`

| 部分 | 规则 |
|---|---|
| `N` | 1-indexed 顺序，对齐 `chapters.ts` 的注册顺序 |
| `<id>` | **小写 + 连字符**。会成为 React `key` / 文件夹名 (`src/chapters/0N-<id>/`) / 音频子目录 (`public/audio/<id>/`) |
| `<title>` | 给人看的中文标题。**不会**进 React 代码 |
| `<S> steps` | 该章 step 总数 |
| `~<T>s` | 该章口播总估时（中文 ~ 4 字/秒） |

合法 id：`coldopen`、`hook`、`why-good`、`why-good-text-render`。
不合法：`why_good`（用连字符）、`Hook`（小写）、`第一章`（拉丁字符）。

### 章节首段「信息池」（**双源原则核心落地**）

每章独立列出从 `article.md` 抽的细节集合，**让 chapter agent 实现每步
画面时按需取用**——可能挂成右下角 mono 角标 / 副标小字 /
pull-quote 引用 / 数据浮层。

#### 信息池条目格式（v2 — 推荐）

> **v2 (YAML 内嵌) 是推荐格式**，支持机器解析、自动校验、跨章追踪。
> v1（纯文本）仍可使用但标记为 deprecated。
> 迁移工具：`bash scripts/migrate-outline.sh <outline.md>` 可自动转换。

**格式**：每章信息池区块内使用 **YAML 列表**（内嵌在 markdown 代码块中）：

```yaml
# 信息池（从 article.md 提取的素材）
- id: pain-overwhelmed
  label: "核心痛点：新领域想学但觉得太难"
  type: text-quote           # 枚举：text-quote / data / case / term-pair / comparison / concept
  source: article §1 L4-L8    # 必须：对应 MATERIAL-INDEX.md 的可用区域
  render-hint: contrast-card   # 建议：contrast-card / terminal / pyramid-layer / counter / flow-step
  priority: must              # must / should / optional
  for-steps: [1, 2]           # 建议分配到哪些 step（可选）
  narration-hint: "就是觉得太难了，不知道从哪下手"  # 口播补充方向（可选）

- id: time-comparison
  label: "对比：找专家花钱 / 自己研究花时间"
  type: comparison
  source: article §1 L10-L11
  render-hint: strike-transition
  priority: must
```

**字段说明**：

| 字段 | 必填 | 说明 |
|------|------|------|
| `id` | ✓ | 全局唯一标识（kebab-case），用于跨章复用追踪 |
| `label` | ✓ | 人类可读描述（agent 挂到画面上的文字方向） |
| `type` | ✓ | 素材类型枚举（见下方类型表） |
| `source` | ✓ | 来源定位（`article §X LYY-ZZ` 或 `MATERIAL-INDEX #N-M`），校验时检查是否在可用区域 |
| `render-hint` | 建议 | 渲染建议（给 agent 的视觉演示方向提示） |
| `priority` | 建议 | must = 必须用 / should = 建议用 / optional = 有更好 |
| `for-steps` | 可选 | 建议分配到的 step 编号数组 |
| `narration-hint` | 可选 | 口播补充措辞方向（帮助 agent 保持口语风格一致性） |

**type 枚举值**：

| type | 含义 | 典型渲染方式 |
|------|------|------------|
| `text-quote` | 可引用的文字片段 | pull-quote 卡片 / kicker 文字 |
| `data` | 数字/比例/统计数据 | counter 动画 / 进度条 / 排名交换 |
| `case` | 案例/故事/人物线 | 时间线 / 人物卡片序列 |
| `term-pair` | ❌→✅ 术语对比对 | 对比切分卡片（左灰右亮） |
| `comparison` | A vs B 对比数据 | split-screen 数值对比 / 划掉转场 |
| `concept` | 概念/原理/方法论 | SVG 图表 / 流程图 / 金字塔层 |

#### 信息池条目格式（v1 — deprecated，仍可解析）

```
- <类型>：<具体内容> —— <来源 article §X / Lxx 或简注>
```

> v1 格式会被 `validate-outline.sh` 和 `migrate-outline.sh` 自动识别并给出迁移提示。
> **新项目请直接使用 v2 格式。**

> **没 article（用户直接给 script）**：信息池退化为"主动设计画面信息
> 密度"——靠数字 / 对比 / 元数据等让画面比口播信息密。可以列"画面
> 装饰元素池"而非"article 抽取池"。

### Step 列表：每步 **1 行**

```
- step N (~Ts) — <屏幕内容>
```

| 规则 | 原因 |
|---|---|
| `step N` 1-indexed | agent 实现时 `if (step === N - 1) ...`（注意零基偏移） |
| **`(~Ts)`** 必填 | 按 script.md 本步对应口播段字数 ÷ 4 估算（中文 ~ 4 字/秒）。范围 3~10s |
| **屏幕内容** | 一句话讲清楚这一步舞台上有什么：hero / 标语 / 数据 / 装饰元素。**≤ 1 行**，再多就该拆 step |
| **不写动画** | 写死 = 翻译机化（详见本文件顶部框） |
| **不写时长数值 / 错峰量** | 这些在章节开发阶段决定 |
| **不写实现手段** | filter / SVG / Canvas 选型留给 chapter agent |

### 画面感写作规范（每步描述必须包含 ≥ 2 个视觉维度）

> **核心问题**：同样是一句话"屏幕内容"，信息性描述和视觉性描述会让 chapter agent
> 产出天壤之别的结果。本节教你怎么写出有画面感的 step 描述。

**每步的「屏幕内容」必须包含以下 ≥ 2 个视觉维度**：

| 维度 | 含义 | 示例关键词 |
|------|------|-----------|
| **焦点** | 这一步观众眼睛该看哪里 | "中央"、"右上角"、"底部居中"、"全屏" |
| **层次** | 元素之间的先后/主次/上下关系 | "缩小到顶部作kicker"、"保留在上方作上下文"、"主vs副" |
| **动作暗示** | 元素出现/变化的动态感觉（不写动画类型） | "亮起"、"灰化保留"、"划掉→弹入"、"逐个揭示"、"浮现"、"切入" |

#### 合格 vs 不合格的对比

❌ **信息性描述（会导致 PPT 感）**：
```
- step 2 (~5s) — 介绍 AI 学习方法的三个好处
```
→ chapter agent 只能做：大标题 + 三行文字 = 纯文字 PPT

✓ **视觉性描述（有画面感，chapter agent 能设计出视频感）**：
```
- step 2 (~5s) — hero 标题缩到顶部 kicker，中央浮现「3h → 30s」
  对比数字动画（左边划掉，右边 accent 色弹入放大）
```
→ chapter agent 知道：有 kicker 层次、有中央聚焦区、有对比数字演示、
  有颜色消费策略 = 视频感

✓ **另一个合格例子**：
```
- step 4 (~6s) — 对比数字保留上方作上下文，下方逐个揭示三个好处
  （第1步：「效率翻倍」accent色亮起，其余 faint 色灰化）
```
→ 有层次关系、有逐步揭示节奏、有颜色策略、有焦点引导

#### 常见错误模式

| 错误 | 为什么不行 | 改法 |
|------|-----------|------|
| "列出 X 个 Y" | → chapter agent 做 stagger 列表 = 违反原则 8 | 写成"逐个揭示，每项 1 step" |
| "展示数据" | → 太模糊，不知道用什么形式 | 写成"用进度条/数字递增/排名交换展示" |
| "说明概念 X" | → 纯文字 | 写成"用流程图/SVG/对比切分来呈现 X 的关系" |
| 连续 3 步都是"介绍..." | → 无视觉变化，像翻 PPT | 每步换主导元素类型 |


### 口播节选（每章末尾，可选但推荐）

精炼 1~3 句，**不是完整稿子**，仅供章节规划阶段对照"这章在讲什么"。
完整文本回 `script.md`。`outline.md` 章节 = `script.md` 中两个明显
主题切换之间的段落。

> 音频合成（[`AUDIO.md`](AUDIO.md)）会**回到 `script.md`** 切分完整
> 文本，**不**用 outline 节选。

---

## 命名规则速查

| 对象 | 规则 | 示例 |
|---|---|---|
| 章节 id | 小写 + 连字符 | `coldopen`, `why-good` |
| 章节文件夹 | `0N-<id>` | `src/chapters/01-coldopen/` |
| 章节组件 | PascalCase | `Coldopen.tsx`, `WhyGood.tsx` |
| 章节 CSS 类前缀 | 章节缩写（避免跨章冲突） | `.cd-` / `.wg-` / `.mg-` |
| 音频子目录 | `<id>/` | `public/audio/coldopen/` |
| 音频文件 | `<step-N>.mp3` (1-indexed) | `public/audio/coldopen/1.mp3` |

---

## 章节切分的经验法则

- **每章 3~8 步**。少于 3 步太薄；多于 8 步观众会忘记这章在讲啥
- **总时长 ÷ 30 秒** ≈ 章节数（一章约 30~60 秒讲完）
- **每章 = 一个聚焦主题**。"为什么强 + 怎么用" 是两章，不是一章
- **章节边界 = 口播稿里讲者会换语气 / 换主题的位置**。读 `script.md`
  时哪里你下意识想"咳一声接下一段"，那里就是章节边界
- **慢节奏 / 长镜头风主题**（midnight-press / 电影感片头）每章可少到
  2~3 step；**信息密集型**（科技测评 / 对比表）每章可放宽到 8~10 step

---

## 素材清单（outline.md 末尾）

```markdown
## 素材清单

### 1. coldopen
- ✓ <资源 1 描述> （<已就位路径>）
- ⚠️ <资源 2 描述>（待提供）
- ⚠️ <资源 3 描述>（待提供）

---

## 自检（写完 outline **强制**执行，不可跳过）

> ⚠️ **硬性流程**：outline 写完后**必须**走自检 → 修改 → 提交 三步。
> **禁止**写完直接进入 Checkpoint Plan 让用户对齐。
>
> **执行方式**（按能力降级）：
>
> 1. **优先 Agent Teams**：开一个独立 reviewer agent，传入 `outline.md`
>    + 本节自检清单 + `script.md` / `article.md` 路径，让它**逐项核查 +
>    出结论**（哪几条 fail + 证据）。
> 2. **其次 subAgent**：当前 agent 没 Teams 但能开 subagent，用 subagent
>    走同样流程。
> 3. **都没有**：自己**严格逐项**核查。
>
> 拿到结论后**先按 fail 项改 outline，再进入 Checkpoint Plan**。

- [ ] 每个 step 都是**单一句屏幕内容描述**，没有"动画"行 / "手段"行
- [ ] 没有任何 step 写了具体毫秒 / 秒数（除 `(~Ts)` 口播估时）
- [ ] 每章首段都有「信息池」block（v2 YAML 或 v1 纯文本），至少 3 条 article 抽取项
      **v2 格式要求**：每条必须有 `id` / `label` / `type` / `source` 四个必填字段
      **v1 格式要求**：每条必须带来源标注（`—— 来源 article §X / Lxx`）
- [ ] **所有 step `(~Ts)` 累加 ≈ 顶部声明的总时长**（误差 < 10%）—— 不
      一致说明节奏规划失真
- [ ] 章节切分符合"每章 3~8 步 / 30~60s 一聚焦主题"经验
- [ ] 末尾「素材清单」分章节列出，✓ / ⚠️ 标注清楚
- [ ] 脚本不得包含标题、序号等非口播内容，仅包含人类正常可读的内容
- [ ] **每步描述包含 ≥ 2 个视觉维度**（焦点 / 层度 / 动作暗示），不是纯信息罗列
- [ ] **连续 3 个 step 的主导视觉元素有变化**（不能全是"文字列表"或"介绍..."）
- [ ] **信息池的 ≥ 50% 条目被显式分配到了具体 step**（不能只在信息池里列着但没用上）
- [ ] **[v2 专属] 信息池 `source` 字段引用的区域不在 MATERIAL-INDEX.md 的 [SKIP] 列表中（若存在）**
- [ ] **[v2 专属] 信息池 `id` 在全文件中唯一（无重复）**
- [ ] **[v2 专属] 信息池 `type` 值属于合法枚举（text-quote/data/case/term-pair/comparison/concept）**

写完看一眼：**outline 是不是干净到 chapter agent 看了能立刻开工 + 还有
设计空间**？是 = 合格。如果你看了都觉得"太空，agent 不知道动画选什么"
