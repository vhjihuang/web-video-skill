# Design Decisions

> **何时读**：首次使用本 Skill 时、或遇到边界情况想理解"为什么这么做"时。
> **执行时不需要读**——SKILL.md 已保留一行注脚指向此处。

基于上游：[ConardLi/garden-skills](https://github.com/ConardLi/garden-skills/tree/main/skills/web-video-presentation)

---

## § 双源原则 (Dual-Source)

**来源**：SKILL.md Phase 1.2 / FAILURE_ANALYSIS #10 #11 #43-45

**规则**：`article.md` 不删，它是画面信息源。

**为什么**：

口播稿（script.md）决定的是**节奏和节拍**——每一步说什么、什么顺序。

但屏幕画面不能只是口播的"字幕"。如果那样做：

- 信息密度太低（FAILURE #10：画面=口播打字）
- 浪费了视觉通道的带宽
- 观众眼睛没事干，注意力漂移

所以 `article.md`（原始文章）必须保留作为**第二信息源**。章节实现时从 article 中抽取：

- 具体数字和引用（增强可信度）
- 案例和标签（提供上下文）
- 图表和可视化素材（提升信息密度）

这就是 **outline 信息池** 的作用——它充当 article → 画面的桥梁。

**落地方式**：
1. outline 每章首段必须有 `信息池`（从 article 抽取的关键素材）
2. Phase 2.4 实现单章时通过 `MATERIAL-INDEX.md` 按章节定位素材
3. 验证时检查：屏幕是否有"口播没念但 article 能挂"的细节

---

## § Outline 边界 —— 为什么不写动画

**来源**：SKILL.md Phase 1.2 / CHAPTER-CRAFT.md Part 0 原则 7

**规则**：outline 只规划节奏与信息密度，不规划具体动画。

**为什么**：

如果 outline 写死了动画类型（如 `step 3: fade in from left`），chapter agent 就退化为**翻译机**——把文字描述翻译成代码，没有创作空间。

更糟糕的是：写 outline 的人和实现章节的人对"语义"的理解可能不同。outline 说 `fade in`，agent 可能理解为 `opacity transition`，也可能理解为 `transform translateX`，结果不可控。

**留白的收益**：

- chapter agent 在每步开工时，根据**该步的具体内容**选择最合适的动画
- 用 [CHAPTER-CRAFT.md](CHAPTER-CRAFT.md) 的"内容驱动决策树"来引导
- 同样的"揭示"动作在不同语境下可以是 maskReveal / wipe / opacity / clip-path 等

**outline 应该写什么**：

| ✅ 该写 | ❌ 不该写 |
|---------|----------|
| 章节切分 / step 数 / 估时 | 具体动画类型 |
| 每步屏幕内容（hero / 数据 / 标语） | CSS 实现手段 |
| 章节级信息池（数字 / 引用 / 案例） | 时长数值 |
| 步级关系名前缀（可选 hint） | 微观节奏细节 |

---

## § 第一章 Anchor —— 为什么必须主线程

**来源**：SKILL.md Phase 2.2 / WORKFLOW.md R5

**规则**：第 1 章必须在主线程完成 + 用户验收后才能并行后续章节。

**为什么**：

第 1 章是整套指引在**当前主题 × 当前题材**下的**第一次真实落地**。

这意味着：

1. **指引盲区暴露**：CHAPTER-CRAFT.md 的规则是通用的，但具体到某个主题（如 `terminal-green`）和某个题材（如 AI 工具介绍），一定有指引没覆盖到的场景。第 1 章一定会踩到这些坑。
2. **主题 token 验证**：主题定义的颜色 / 字体 / 装饰 token 在实际内容中是否够用？字号层级是否合理？对比度是否足够？第 1 章是验证机会。
3. **风格锚点**：后续章节（无论顺序还是并行）都会参考第 1 章的代码模式。第 1 章的质量直接决定后续章节的下限。

**早改成本最低**：在第 1 章发现问题和在第 5 章发现，修复成本差 5 倍以上（因为后续章节可能已经复制了错误模式）。

---

## § 并行模式 —— 为什么允许风格不一致

**来源**：SKILL.md Phase 2.3 模式 C

**规则**：模式 C（subagent 并行）下各章风格差异是**预期行为**，不是 bug。

**为什么**：

每个 subagent 看不到其他 subagent 的产出，无法机械对齐风格。但即使能看到，**强求一致也不一定是好事**：

1. **物理隔离已保证安全**：每章独立 CSS 前缀（`.cd-` / `.mg-` / `.pm-`），不会互相破坏
2. **主题 token 兜底统一**：颜色 / 字体 / hero 数字 / 卡片性格 / 分割线等由 theme.json 统一控制，气质不会跑偏
3. **风格差异 = 呼吸感**：人手写视频本身就有多 voice / 多视角的变化。机械统一的"组件库感"反而是 AI 味的表现（FAILURE #22-25）

**控制手段**（不是消除差异，而是约束范围）：

- 第 1 章**设计决策卡**：记录演示手法 / 动画基调 / 字号层级 / 颜色策略
- 主题禁区：`theme.json` 中标记 `avoid` 的元素（如某主题禁用 emoji）
- CHEATSHEET 硬规则：CSS prefix / narrations 格式 / tsc 通过

---

## § 文件读取分层策略

**来源**：SKILL.md 各阶段文件读取指南 / talking.md "注意力预算"

**规则**：第 1 章读完整版 CHAPTER-CRAFT.md，第 2~N 章只读 CHEATSHEET。

**为什么**：

CHAPTER-CRAFT.md 完整版约 **300+ 行**，包含：
- Part 0 十条原则（哲学层）
- Part 1 开工 5 问（决策层）
- Part 2 关系→动作决策树（工具层）
- Part 3 视觉工具箱（参考层）
- Part 4 时长参考（数据层）
- Part 5 反 AI 味反模式（约束层）
- Part 6 代码硬规则（工程层）
- Part 7 完工自检（质量门）
- Part 8 反馈速查（运维层）

每次实现新章节都读 300+ 行 = **巨大的 token 浪费**，而且大部分内容是"参考性质"，不是"必须遵守"。

**分层策略**：

| 读取对象 | 内容 | 适用场景 | 行数 |
|---------|------|---------|------|
| CHAPTER-CRAFT.md | 完整版（含教程式解释） | **仅第 1 章** | ~300+ |
| CHAPTER-CRAFT-CHEATSHEET.md | 浓缩红线版（硬规则+自检） | **第 2~N 章** | ~100 |
| CORE-PRINCIPLES.md | 5 条高层原则 + 10 条详细索引 | 想理解"为什么"时按需 | ~120 |
| DESIGN-DECISIONS.md（本文件） | 设计决策背后的理由 | 边界情况/首次使用 | ~50 |

**关键洞察**（来自 talking.md）：

> 中模型读 100 行 cheatsheet 比读 5 个原则更容易漂
>
> 因为 Transformer 不是规则引擎——规则越多 ≠ 约束越强，
> 有时候规则太多本身才是 attention 污染和不稳定的来源。

所以 CHEATSHEET 本身也做了极致精简：只保留**硬规则 + 代码约束 + 自检清单**，删除所有"为什么"的解释。

---

## § Validation Protocol —— 为什么需要程序化校验

**来源**：FAILURE_ANALYSIS #16 #20 #26 #27 / optimized_skill_architecture_refactor_plan.md Layer 1

**规则**：每章完成后运行 `npm run validate`，fail 则阻断流程。

**为什么人工自检不够**：

FAILURE_ANALYSIS 记录了多个"人工自检遗漏"的案例：

- **#16 Narrations 不同步**：`.tsx` 里 max step 和 `narrations.length` 不一致，人工数错
- **#20 动画超时**：Auto 模式下动画时长 > 口播时长，录屏崩溃——这个靠肉眼几乎无法发现
- **#26 Vite 类型导入错误**：编译都不通过，但 Agent 忘记跑 `tsc --noEmit`
- **#27 导出不一致**：chapters.ts 注册了但文件没 export，运行时崩溃

这些问题的共同特征：**客观、可机器检测、人工容易遗漏**。

**validate 的设计哲学**（来自 optimized_skill_architecture_refactor_plan.md）：

> 程序负责确定性（校验/一致性/编译）
> 模型负责创造力（节奏/镜头/动画语义）
> 不要试图用规则完全替代创意

所以 validate 只检测**纯客观项**：
- narrations 对齐（数一数就行）
- TypeScript 编译（tsc 一跑就知道）
- 字号下限（正则解析 CSS）
- CSS prefix 隔离（扫描类名）
- 动画时长 vs 口播时长（解析 + 对比）

**不检测**主观项：有没有电影感？节奏对不对？AI味重不重？（这些留给人工验收）

---

*最后更新：2026-05-21（refactor 分支初始化）*
