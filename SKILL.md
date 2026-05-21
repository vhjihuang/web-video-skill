---
name: web-video-presentation
description: 把一篇文章或口播稿，做成"看起来像视频"的点击驱动 16:9 网页演示，可选合成口播音频。流程：原始文章 → **一次产出**口播稿 + outline 开发计划 → 用户**一次对齐** 5 件事（稿子 / outline / 主题 / 素材 / 开发模式）→ 网页开发（逐章 / 顺序 / 并行）→ 可选音频合成（默认 MiniMax CLI mmx-cli）。**outline 只规划节奏与信息密度，不规划动画** —— 动画由章节开发时按 PRINCIPLES + ANTI-AI 法则即时设计。每次点击推进口播稿的一个节拍，每一步独占整屏，进度条平时隐藏只在悬浮时出现。适用场景：用网页做视频（动态 PPT 但不像 PPT）、把口播稿 / 文章变成可交互的解说、为 B 站 / YouTube / 视频号录屏教程、做有电影感的产品 / talk demo。本 Skill 沉淀的是设计方法论 + 协作流程 —— 不绑定任何特定样式 / 字体 / 颜色 —— 因此能复用到任意主题与美学。
---

# Web Video Presentation

把一篇文章或口播稿，一步步做成可录屏的"伪装成视频的网页"，可选合成
口播音频。产出物 = Vite + React + TS 项目 + 按章节切分的音频。

## 适用场景

- "我有口播稿 / 一篇文章，帮我做成视频" —— 口播驱动的内容
- 想做 "动态 PPT"
- 16:9 横屏录屏，大字、留白、每屏都要有动效
- 教学 / 产品演示 / keynote 想要电影感
- B 站 / YouTube /抖音视频内容

本 Skill **以方法论 + 协作流程为核心**。脚手架模板提供 token 和原语，
但每个美学决策（配色、字型、动效气质）都应该针对你的主题重新设计 ——
不要照搬。

---

## 工作流总览

```
Phase 0   启动前准备 (数据预处理)
   0.1  按 presets 模板对杂乱原始素材（如 article-full.md）进行预处理
   0.2  清理噪音、补全结构并提取视觉素材，确保每 H2 至少 3 个视觉元素
   0.3  产出纯净版 article.md 与素材索引 MATERIAL-INDEX.md
   > ⚠️ Phase 0 专项风险（预处理过度修剪 R11 / presets 不匹配 R12）详见 WORKFLOW.md §十一
   ▼
Phase 1   内容编写
   1.1  识别用户输入
   1.2  一次产出 script.md + outline.md
        （口播稿 + 开发计划）
   ▼
[Checkpoint Plan]      ← 必须停。一次对齐 5 件事：
                         稿子 / outline / 主题 / 素材 / 开发模式
   ▼
Phase 2   网页开发
   2.1  脚手架（按选定主题）
   2.2  第 1 章 = 主线程 + 完整版本（强制 anchor）
        ▼
        [硬节点] 用户验收第 1 章 ← 不可跳过
        ▼
   2.3  第 2~N 章（按选定模式：A 逐章 / B 顺序 / C 并行）
   ▼
[Checkpoint Audio]     ← 必须停。是否合成音频
   ▼
Phase 3   音频合成（可选）
   ▼
Phase 4   录屏 + 后期
```

工作目录约定（agent 在用户当前目录下创建 / 编辑）：

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
    │   ├── extract-narrations.ts   # 扫所有 narrations.ts → audio-segments.json
    │   └── synthesize-audio.sh     # 调 mmx 合成 mp3
    ├── audio-segments.json         # extract 产出（合成前 review）
    └── public/audio/<id>/<N>.mp3   # 可选：合成的音频
```

> **关键**：`narrations.ts` 是 step 数和音频合成的**唯一真相源**。
> 章节 `.tsx` 里的 `if (step === N)` 出现的最大 N + 1 必须等于
> `narrations.length`。这保证 5 处地方（script / outline / 章节代码 /
> chapters.ts / 音频文件）永远不会漂。

---

## Validation Protocol（贯穿整个 Skill）

下面三个产出，每一个**完成后必须走 validate + 自检 → 修复 → 再汇报/推进**：

| 产出 | 自检出处 | 程序化检测 |
|---|---|---|
| `script.md` | [`SCRIPT-STYLE.md`](references/SCRIPT-STYLE.md) 三层自检 | — |
| `outline.md` | [`OUTLINE-FORMAT.md`](references/OUTLINE-FORMAT.md) 自检 | — |
| 单章实现完成 | [`CHAPTER-CRAFT-CHEATSHEET.md`](references/CHAPTER-CRAFT-CHEATSHEET.md) 18项自检 | `npm run validate`（C1/C2/C4/C6/C7） |

**执行方式**（按能力降级）：**Agent Teams（最优）→ subAgent → self review**

> **铁律**：fail 项必须修复后才准汇报。直接汇报原始结论但不修复 = 违规。
> 详见 [WORKFLOW.md](WORKFLOW.md) §自检协议细节、[DESIGN-DECISIONS.md](references/DESIGN-DECISIONS.md) §Validation Protocol

---

## 各阶段文件读取指南

不同阶段读不同的文件。**长会话里 agent 容易遗忘原则**，特别是
Phase 2.4 的"实现单章"会重复 N 次 —— 每次都要回看核心约束。

| 阶段 | 必读（每次都看） | 一次性看完 / 按需查 |
|---|---|---|
| Phase 0 启动前准备 | `references/ARTICLE-PROCESS-GUIDE.md` + 匹配的 `references/presets/` 模板 | `article-full.md` 等原始素材 |
| Phase 1.1-1.2 内容编写 | `references/SCRIPT-STYLE.md` + `references/OUTLINE-FORMAT.md` + `article.md`（用户原文，如有） | —— |
| **Checkpoint Plan 选主题** | —— | `themes/*/theme.json`（动态读全部，列清单 + `bestFor` 推荐 + `descriptionZh`）；`references/THEMES.md`（用户想了解主题系统时） |
| Phase 2.1 脚手架 | —— | SKILL.md 本节看一次 |
| **Phase 2.4 实现单章（×N 次，被 2.2 / 2.3 调用）** | **第 1 章**：读 [`references/CHAPTER-CRAFT.md`](references/CHAPTER-CRAFT.md)（完整版）；**第 2~N 章**：读 [`references/CHAPTER-CRAFT-CHEATSHEET.md`](references/CHAPTER-CRAFT-CHEATSHEET.md)（浓缩红线版）+ 当前主题 `theme.json` + 当前章节 outline 段落 + **`MATERIAL-INDEX.md`（素材萃取指南，按章节查表，不用读完整 article.md，需在项目根目录查找）** + 素材清单 | `references/EXAMPLES/`（结构示意）；`references/THEMES.md` 完整 token 契约 |
| Phase 3 音频合成 | `references/AUDIO.md`（含 narrations.ts → segments.json → mmx 流程） | —— |
| Phase 4 录屏 + 后期 | `references/RECORDING.md`（含 `?auto=1` 自动录屏） | —— |
| 选 / 造 / 切主题 | —— | `references/THEMES.md` |

> **第 1 章必须读完整版 `CHAPTER-CRAFT.md`**（理解"为什么这么做"）。
> 后续章节只读 `CHAPTER-CRAFT-CHEATSHEET.md`（只记"不能做什么"），
> 大幅节省 token 同时不丢关键约束。
> **article.md 不需要全文读**——通过 `MATERIAL-INDEX.md` 按章节查表定位素材即可
> （原始素材往往含有大量冗余信息，利用 MATERIAL-INDEX 定位核心内容即可）。
> `EXAMPLES/` **不是必读** —— 先按内容自由设计，卡壳才翻。

---

## Phase 1 —— 内容编写（一次产出）

### 1.1 识别用户输入

| 用户给的东西 | 该做的 |
|---|---|
| 原始文章（书面语 / 公众号 / 论文 / 博客） | 一次产出 `script.md` + `outline.md`（1.2），过 Checkpoint Plan |
| 直接的口播稿 / 视频脚本 | 落盘成 `script.md`，一次产出 `outline.md`（1.2 简化版），过 Checkpoint Plan |
| 啥都没有，只说"帮我做个 X 主题的视频" | **反问**：先给一段素材或大纲。Skill 不替用户构思内容 |

### 1.2 一次产出 script.md + outline.md

**两份产出物在一次思考中完成**：

1. **生成 `script.md`**：按 [`references/SCRIPT-STYLE.md`](references/SCRIPT-STYLE.md)
   的规则把 article 转 B 站风口播稿。**保留 `article.md` 不删**——它是
   outline 写信息池和章节实现画面时的细节源。（详见 [DESIGN-DECISIONS.md](references/DESIGN-DECISIONS.md) §双源原则）
2. **生成 `outline.md`**：按 [`references/OUTLINE-FORMAT.md`](references/OUTLINE-FORMAT.md)
   规则切章节 + 切 step + 每章首段抽**信息池**。

**outline 的边界**（关键）：

| outline 必须写 | outline 不要写 |
|---|---|
| 章节切分 / 每章 step 数 / 估时 | 具体动画类型（blur clear / wipe / 弹簧） |
| 每步屏幕内容（hero / 数据 / 标语 / 列表项） | CSS 实现手段（filter / SVG / clip-path） |
| 章节级**信息池**：从 article 抽的数字 / 引用 / 案例 / 标签 | 时长数值（不写 ~2.5s / 80~120ms） |
| 步级关系名前缀（"反差对照" / "递进列表" / "金句" 等可选 hint） | 持续微动 / 错峰量等微观节奏 |

> **outline 不写动画的理由**：写死动画 = chapter agent 退化为翻译机；
> 留白让 chapter agent 按内容驱动自由设计。（详见 [DESIGN-DECISIONS.md](references/DESIGN-DECISIONS.md) §Outline边界）

**落盘后必须先走自检再进 Checkpoint Plan**：按上文「硬性自检协议」分别
对 `script.md` / `outline.md` 执行（优先 Agent Teams → subAgent → 自检），
按结论修复完成后再进入 Checkpoint Plan。

---

## Checkpoint Plan —— 5 件事一次对齐（**硬节点**）

`script.md` + `outline.md` 写完后必须停下来。**用户在这一个节点同时确认
5 件事**。

### agent 此时要做的预备工作

1. 读所有 `themes/*/theme.json` 拿 `nameZh` / `descriptionZh` / `bestFor`
   / `mood` —— **不要硬编码清单**
2. 根据 `script.md` 的内容类型 / 关键词 / 语气，**主动**从主题里挑 2~3
   套**最匹配的推荐**（匹配 `bestFor` 字段）
3. 扫一遍 `outline.md` 末尾"素材清单"部分

### 总结模板（骨架 + 关键示例）

```
内容计划写完，产出文件：
  📄 article.md     {若用户给原文则保留}
  📄 script.md      {X} 字 / ~{T} 分钟
  📄 outline.md     {N} 章 / {M} 步 + 每章信息池 + 末尾素材清单

章节速览：
  1. <id>     <章节标题>    <S> 步 ~<T>s
  2. ...

接下来一次对齐 5 件事：

  1. 稿子 (script.md) 要不要改？
     可以直接编辑文件，或口头告诉我修改方向。

  2. 开发计划 (outline.md) 要不要改？重点看：
     - 章节切分 / step 数 / 估时是否合理（合理判断：每章 30~60s）
     - 每步屏幕内容是否清晰
     - 每章首段「信息池」是否有足够的 article 细节供画面挂
     - 末尾素材清单是否完整

  3. 选哪个主题？我的推荐：
     ★ <推荐 1：nameZh (id)> — 因为 <bestFor 命中>；<descriptionZh 摘要>
     ★ <推荐 2 / 推荐 3>
     其它可选：<剩余主题，nameZh + 一句话>
     也可以让我帮你做新主题（详见 references/THEMES.md）。

  4. 真素材怎么准备？粗看本视频要的图：<列粗略清单>
     a) 我从 <现有素材路径> 帮你挑   b) 你自己提供   c) 全部 placeholder

  5. 开发模式选哪个？

     **第 1 章无论哪种模式都必须主线程做完 + 用户验收**（强制 anchor）。
     差异在第 2 章及之后：

     A) 默认 · 逐章确认（推荐）
        每章做完都暂停验收 → 风险可控 / 节奏最稳
     B) 第 1 章后顺序开发（不并行）
        第 2~N 章主线程顺序做完后统一验收 → 速度中 / 适合 agent 不支持并行
     C) 第 1 章后并行开发（subagent）
        第 2~N 章用 subagent 并行 → 最快 / 用户控并行数（一次几章）
        ⚠️ 风格各章会有差异（这是预期，主题禁区兜底）
```

> 💡 以上是完整交互模板。agent 可根据实际情况调整措辞，但**必须覆盖 5 个检查项**。
> 精简版骨架（只保留结构）见下方"快速版本"，适合熟练场景。

收到反馈后：
- 稿子 / outline 要改：直接编辑文件，编辑完 ping 一次（或口头描述 agent 改）
- **主题必须明确**才进入 Phase 2。用户说"主题你帮我选" → 取你推荐的第 1 个，
  **告诉用户你选了什么、为什么**，给反悔机会
- 模式选定 → 进 Phase 2

---

## Phase 2 —— 网页开发

### 2.1 脚手架

```bash
bash <path-to-web-video-presentation>/scripts/scaffold.sh \
  ./presentation \
  --theme=<用户选的主题 id>

bash <path-to-web-video-presentation>/scripts/scaffold.sh --list-themes
```

> 自定义主题 → 先按 [`references/THEMES.md`](references/THEMES.md)
> "创作新主题"流程做一个 `themes/<my-theme>/`，再 `--theme=<my-theme>`。

脚手架带一个 `01-example` demo。在写第一章真实内容前**删掉**：

```bash
rm -rf presentation/src/chapters/01-example
```

并把 `presentation/src/registry/chapters.ts` 里 `EXAMPLE_CHAPTER`
的 import 和数组项移除。

### 2.2 第 1 章 —— 主线程 + 强制验收

**核心**：第 1 章 = 完整版本一次到位（节奏 + 视觉 + 真素材齐全）。
**没有"骨架版"概念** —— 第一章就要做出**用户能直接验收**的样板。

> **第1章必须在主线程完成并验收，作为后续风格 anchor（强制）。**
> 原因：首次落地暴露指引盲区+验证主题 token，早改成本最低。（详见 [DESIGN-DECISIONS.md](references/DESIGN-DECISIONS.md) §第一章Anchor）

**做完第 1 章后必须停下来**等用户验收：

```
第 1 章 <id> 做完了，dev server 在 localhost:5173 运行。

验收重点：
  □ 视觉气质对不对？符合 <theme nameZh> 的预期吗？
  □ 节奏对不对？某些步太快 / 太慢 / 信息太薄？
  □ 内容驱动动画是否到位？还是有几步是无脑入场动画？
  □ 双源原则：屏幕画面有没有"口播没念但 article 能挂"的细节？
  □ 反 AI 味检查：紫粉渐变 / 圆角彩色边框 / 假插画 / emoji 是否有？

问题告诉我，我针对性改。OK 了告诉我"继续"，我按选定模式做第 2 章及之后。
```

### 2.3 第 2~N 章 —— 按选定模式

**所有模式下的共同规则**：每章独立按 [`CHAPTER-CRAFT.md`](references/CHAPTER-CRAFT.md)
开发。**风格不强求章节间完全一致** —— 主题颜色 / 字体 token 兜底视觉
统一，动画 / 节奏 / 视觉演示由章节自由发挥是设计预期。

#### 模式 A · 默认 · 逐章确认

第 2 章做完 → 暂停验收 → OK → 第 3 章 → 暂停 → ... → 第 N 章。**每章
独立验收**，问题随时改，**风险最低，节奏最稳**。**用户不明确选模式时
默认走这个**。

#### 模式 B · 第 1 章后顺序开发

第 2 章 → 第 3 章 → ... → 第 N 章 **主线程顺序做完，最后统一验收**。
速度中等，适合 agent 不支持并行任务的环境。

#### 模式 C · 第 1 章后并行开发（subagent）

用 subagent 把第 2~N 章并行做完，最大并行数由用户控制（"一次 4 章"
/ "一次 2 章"）。**最快，但风格各章会有差异** —— 这是预期，因为：

1. 每个 subagent 看不到别的 subagent 产出，无法机械对齐
2. 章节代码物理分离（每章一个文件夹 / 自己的 CSS 前缀），不会互相
   破坏
3. 主题 token 兜底视觉统一（颜色 / 字体 / hero 数字 / 卡片 / 分割线
   性格 / 装饰），气质不会跑偏
4. **风格不一致 = 人手写视频的呼吸感**（多 voice / 多视角）

并行 subagent 的 prompt 必须包含：

- 当前章节 outline 段落（含信息池）
- `references/CHAPTER-CRAFT-CHEATSHEET.md` 的路径（**浓缩红线版** ——
  硬规则 / 代码约束 / 自检清单全部在这一份里）
- 当前主题 `theme.json` 的 `descriptionZh` / `mood` / `bestFor`（参考气质
  即可，动画 / 时长 / 字号 / emoji 由 chapter agent 自由决定）
- **第 1 章代码作为"代码风格"参考**（不是"视觉抄袭对象"）
- **第 1 章设计决策卡**（模板如下，填好后附给 subagent）：
  ```markdown
  ## 第 1 章设计决策卡（供后续章节参考）

  - 演示手法：<CSS数字动画 / SVG对比图表 / 流程图 / ...>
  - 动画基调：<利落线性~400ms / 弹簧overshoot / 电影感慢~1.5s>
  - 字号层级：hero <N>px / 副标 <N>px / cue <N>px
  - 颜色消费策略：<--text为主 + --accent点缀高亮 / ...>
  - 信息密度：<屏幕信息 > 口播信息，通过...落地双源原则>
  ```
- 硬规则：每章独立 CSS 前缀（`.cd-` / `.mg-` / `.pm-` / ...）；
  不修改 `chapters.ts`；完工跑 `npx tsc --noEmit`

**重要**：无论选哪种模式，**用户随时可以中途切换模式**。第 2 章 OK
后用户说"剩下的并行" / "剩下的逐章" 都行。

### 2.4 实现单章（每章必走）

**第 1 章**：读 [`references/CHAPTER-CRAFT.md`](references/CHAPTER-CRAFT.md)（完整版，
含教程式解释 + 为什么这么做）。

**第 2~N 章**：读
[`references/CHAPTER-CRAFT-CHEATSHEET.md`](references/CHAPTER-CRAFT-CHEATSHEET.md)
（浓缩红线版，~100 行，覆盖全部硬规则 / 代码约束 / 自检清单）。
同时必读：当前主题 `theme.json` + 当前章节 outline 段落 +
`MATERIAL-INDEX.md`
（素材萃取指南，按章节查表定位 article.md 中的可用素材，在项目根目录查找）+ 素材清单。

### 2.5 大改后 bump STORAGE_KEY

改动 `chapters.ts`（增加 / 删除 / 重排章节，或某章 `narrations.ts`
长度变化）后，**bump** `presentation/src/hooks/useStepper.ts` 的
`STORAGE_KEY`（如 `v4` → `v5`），避免持久化游标落到不存在的 step 上。

### 2.6 章节完成后验证（推荐）

每章完成后运行程序化校验：

```bash
cd presentation && npm run validate
```

自动检查：narrations 对齐 / TypeScript 编译 / 字号下限 / CSS prefix 隔离 / 动画时长 ≤ 口播时长  
（详见 [`references/VALIDATION.md`](references/VALIDATION.md)）

**validation fail 时禁止进入下一章**。这是 FAILURE_ANALYSIS #16 #20 #26 #27 的程序化防护。

---

## Checkpoint Audio —— 是否合成音频（**硬节点**）

Phase 2 结束后必须停下来，问用户：

```
网页做完，{N} 章 {M} 步，dev server 在 localhost:5173 跑着。

要不要合成音频做"自动播放录屏"？
  ✓ 合成 → 扫所有章节的 narrations.ts 出 audio-segments.json，
           调 mmx-cli 合成每步一个 mp3 到 public/audio/。
           合成完后用 ?auto=1 模式可以一镜到底录屏（音视频天然同步）。
           本机没装 mmx 会问你用什么 TTS。
  ✗ 不合成 → 跳过 Phase 3，直接 Phase 4 用手动录屏 + 后期配音。
```

要合成 → Phase 3。不合成 → 直接 Phase 4。

---

## Phase 3 —— 音频合成（可选）

详细流程见 [`references/AUDIO.md`](references/AUDIO.md)。简版：

```bash
cd presentation
npm run extract-narrations   # 扫所有 narrations.ts → audio-segments.json
# 让用户扫一眼 audio-segments.json 确认文本对
npm run synthesize-audio     # 调 mmx 串行合成；增量、跳过已存在
```

合成完告诉用户：输出位置 / 总段数 / 哪些段时长异常（太长 = 该 step 拆
分；太短 = 文案太薄）—— 给最后一次校准节奏的机会。然后进入 Phase 4。

---

## Phase 4 —— 录屏 + 后期

详见 [`references/RECORDING.md`](references/RECORDING.md)。两种路径：

| 场景 | 推荐路径 |
|---|---|
| Phase 3 已合成音频 | **Auto 模式一镜到底**：浏览器开 `localhost:5173/?auto=1` → 按 SPACE → 整片自动播完 → 停录 → 裁头尾即成片，**无需后期对音轨** |
| Phase 3 跳过 | 默认 Manual 模式手动点击推进 → 后期任意剪辑工具配音 |

> agent 在 Phase 3 / Checkpoint Audio 后**主动告诉用户**适合的录屏路径。

---

## CORE PRINCIPLES（完整版含代码约束见 [`references/CORE-PRINCIPLES.md`](references/CORE-PRINCIPLES.md)）

从 FAILURE_ANALYSIS.md 45 个真实 Case 反向聚类的**父规则**——每条覆盖多个具体 Failure。

| # | 原则 | 一句话 | 避免什么 | 防住什么 |
|---|------|--------|---------|---------|
| 1 | **Step = 节拍** | 一步只表达一个聚焦想法，像镜头切换 | 同时讲多个重点 / 长时间无变化 / 信息一次性爆发 | 清单一次性展示 / 无节奏变化 |
| 2 | **一屏一主焦点** | 用户注意力不能分裂 | 多区域竞争 / 多高亮同时出现 / 多动画同时抢注意力 | 密集文字 / 多动画竞争 |
| 3 | **动画必须有语义** | 表达对比/递进/因果/冲击 | 无意义 fade / 模板化 slide / 机械 stagger | 同一动画到底 / 动画超时 |
| 4 | **信息密度 > 口播** | 屏幕必须补充口播未念的信息（双源原则） | 页面=字幕机 / 只念不挂细节 | 画面=口播打字 / 素材浪费 |
| 5 | **Token 统一，章节自由** | 主题管气质（颜色/字体），章节管创意（动画/节奏） | 机械统一各章表现 / 安全区不敢创新 | 硬编码主题值 / 安全区单调 |

> 原 10 条详细原则（含技术约束：16:9舞台/step计数器/隐藏控件等）见 CORE-PRINCIPLES.md

### 架构硬约束（不可违反）

以下 5 条是**技术实现层面的物理定律**，不是设计建议——违反它们会导致系统崩溃或功能失效。

| # | 约束 | 实现 | 违反后果 |
|---|------|------|---------|
| T1 | **16:9 固定舞台** | 内容 1920×1080 + `transform: scale()`，禁止响应式布局 | 录屏画面变形 / 不符合视频规格 |
| T2 | **全局 step 计数器** | 章节是 `step` 的纯函数（`if (step === N) return ...`），禁用 `setTimeout`/`setInterval` | 节奏失控 / 音画不同步 / Auto 模式崩溃 |
| T3 | **每步独占整屏** | 一步 = 一个 `<FullScene />`，无部分更新 | 视觉混乱 / 注意力分散 |
| T4 | **隐藏边角控件** | 进度条 / 翻页器默认 `opacity: 0`，`:hover` 时显示 | 录屏出现 UI 残留 / 不像"视频" |
| T5 | **舞台无 chrome** | 无 header / footer / 页码 / 品牌条 / 导航栏 | 空间浪费 / 不像电影感 |

> 这些约束由 `validate.sh` C7（CSS Prefix 隔离）和 C2（TypeScript 编译）部分覆盖，但 agent 必须在写代码时就遵守，不能依赖事后校验。

---

## 常见用户反馈速查

简化表见 [`references/CHAPTER-CRAFT.md`](references/CHAPTER-CRAFT.md)
Part 8「常见反馈速查」。**关键**：先定位是哪一层（节奏 / 视觉 / 内容
/ 代码），再改最小切片，**不要重做整章**。

---

## 相关资源

按"何时读"标注，避免一次性全读：

| 文件 | 何时读 | 内容 |
|---|---|---|
| [`references/ARTICLE-PROCESS-GUIDE.md`](references/ARTICLE-PROCESS-GUIDE.md) | Phase 0 必读 | 处理杂乱原始素材的通用预处理指南 |
| `references/presets/` 下的各类模板 | Phase 0 选读 | 用于各类内容题材的预处理规则 |
| [`references/SCRIPT-STYLE.md`](references/SCRIPT-STYLE.md) | Phase 1.2 必读 | 文章 → 口播稿规则、平台变体 |
| [`references/OUTLINE-FORMAT.md`](references/OUTLINE-FORMAT.md) | Phase 1.2 必读 | outline.md 字段 spec、命名约定、章节切分、信息池 |
| [`references/CORE-PRINCIPLES.md`](references/CORE-PRINCIPLES.md) | **想理解"为什么"时** | 5 条高层原则 + 10 条详细原则（从 CHAPTER-CRAFT Part0 提取） |
| [`references/DESIGN-DECISIONS.md`](references/DESIGN-DECISIONS.md) | **边界情况 / 首次使用** | 设计决策背后的理由（双源/outline边界/anchor/并行/validate） |
| [`references/CHAPTER-CRAFT.md`](references/CHAPTER-CRAFT.md) | **第 1 章必读**（完整版，含教程式解释） | Part 0~8 全部内容 |
| [`references/CHAPTER-CRAFT-CHEATSHEET.md`](references/CHAPTER-CRAFT-CHEATSHEET.md) | **第 2~N 章必读**（浓缩红线版） | 硬规则 / 代码约束 / 自检清单 / 反馈速查 |
| `MATERIAL-INDEX.md` | **第 2~N 章必读**（素材萃取指南） | 位于项目根目录。article.md 素材索引：按章节查表 |
| [`references/EXAMPLES/`](references/EXAMPLES/) | **可选** —— 看结构 | 章节结构示意；**不是抄袭模板** |
| [`references/THEMES.md`](references/THEMES.md) | 选 / 造 / 切主题时 | 完整 token 契约 + 内置主题清单 + 创作流程 |
| [`references/AUDIO.md`](references/AUDIO.md) | Phase 3 才读 | MiniMax CLI、TTS 退化路径、故障排查 |
| [`references/RECORDING.md`](references/RECORDING.md) | Phase 4 才读 | 录屏工具 + 后期合成 |
| [`references/VALIDATION.md`](references/VALIDATION.md) | validate 报错时 | 检测项详解、C6 动画时长说明、修复建议 |
| `themes/` | Checkpoint Plan / Phase 1.2 时翻 | 内置主题（每个含 `theme.json` + `tokens.css`） |
| [`scripts/scaffold.sh`](scripts/scaffold.sh) | Phase 2.1 跑一次 | 一键项目脚手架 |
| [`scripts/validate.sh`](scripts/validate.sh) | 每章完成后 | 自动化校验脚本（C1/C2/C4/C6/C7） |
| `WORKFLOW.md` | 工作流细节 / 风险排查时 | 风险矩阵 R1-R13 / 工作流补充 |
