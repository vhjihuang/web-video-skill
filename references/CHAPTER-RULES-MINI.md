# 每章硬规则速查（v3 — 证据链版）

> **v3 变更**：从"规则百科全书"重构为 **7 条硬规则 + 证据门控 + 失败路由**。
> 审美/风格规则不在此文件，见 `TROUBLESHOOT.md` 的 anti-AI smell 区。
> 完整 Failure Case 见 `/FAILURE_ANALYSIS.md`。

---

## §1 七条硬规则（不可违反）

> **入选标准**（三条全满足才入选）：
> 1. 不做会导致成片/流程崩溃
> 2. AI 高频违反，且违反后代价高
> 3. 可通过产物证据或机器检查确认

| ID | 硬规则 | 违反后果 | 证据 / 检查方式 |
|----|--------|---------|----------------|
| **H1** | **STEP-SYNC**：`step = 口播节拍`，`narrations.ts` 是唯一时间轴 | Auto 模式音画错位 / 录屏不可用 | `narrations.length === maxStep + 1` |
| **H1-b** | **NARRATION-SOURCE**：每条 narration 必须从 `script.md` 对应节拍切分/改写，禁止从 `outline.md` 摘要重写 | 旁白缩水 / 信息主干被抽空（失败案例保留率低至 7%，详见 §2.5） | Narration Gate（§2.5）+ `npm run validate:content` |
| **H2** | **FOCUS**：每个 step 只能有 1 个主焦点 | 观众不知道看哪 / 认知过载 | Draft/Final Ledger `mainFocus` 字段 |
| **H3** | **ADDITIVE**：屏幕必须补充口播，不做字幕机 | 视频无存在意义 / 信息密度归零 | Ledger `articleExtra + whyRelevant` |
| **H4** | **NO-OVERLOAD**：每步 `articleExtra ≤ 3`，前景单元 ≤ 7 | 一眼看到太多 / 节拍模糊 | Ledger `foregroundUnits + risk` |
| **H5** | **REVEAL**：列表/多点内容逐项揭示，`1项=1step` | PPT 感 / 和口播不同步 | Anchor Card 模式 + Ledger |
| **H6** | **TRUTHFUL**：不造假；缺素材用 placeholder | 信任度归零 / 致命级失败 | Final 自检 + material-usage.ts |
| **H7** | **VALID**：代码可运行且基础校验通过 | 编译崩溃 / 录屏白屏 | `npm run validate` |

### H7 包含的物理约束（旧 T1-T5 合并）

| # | 约束 | 原因 |
|---|------|------|
| H7-a | 16:9 固定画布，transform:scale() 缩放 | 录屏变形 |
| H7-b | 章节是 step 的纯函数，禁 setTimeout/setInterval | Auto 崩溃 |
| H7-c | 每步独占整屏（<FullScene />） | 视觉混乱 |
| H7-d | 控件默认 opacity:0 | 录屏残留 UI |
| H7-e | 舞台无 header/footer/页码 | 空间浪费 |

---

## §2 Step Focus Ledger（证据门控）

> **开工前必须先产出 Draft Ledger**（在对话中输出）。不填不能写代码。
> **完工后产出 Final Ledger**（Draft→Final 对比自证）。

### Draft 模板（开工前）

> ⚠️ **填写 Draft 前，必须先执行 §2.5 Narration Gate（6 条硬门槛）。不通过不能填 Ledger，不能写代码。**

```
Draft Step Focus Ledger:

  signatureMove: __________________________________ （本章唯一的记忆点是什么？高层 primitive 做不到的）

  ── Narration Gate 执行记录（§2.5 输出，必填）──
  script段落: script.md L___-L___（本章对应的完整原文）
  关键事实: [___, ___, ___]（从 script 段落提取的关键数字/案例/方法论）
  sourceMap: "S0←script Lx-Ly, S1←script La-Lb, ..."

S0:
  role: EMOTION-HOOK | CONTRAST-REVEAL | STAMP-OST | TAKEOVER | TEASER | LIST-REVEAL | SINGLE-PROOF | PROCESS-MAP | CUSTOM
  mainFocus: _________________________________ （观众眼睛该看哪里？唯一答案）
  articleExtra: [_________________, _________________, _______________] （口播没念的增量信息——先定画面有什么）
  whyRelevant: _________________________________ （为什么这些 extra 和 mainFocus 值得展示？）
  narration: "_______________________________" （对应 narrations.ts 内容——最后写，基于 mainFocus+articleExtra+script 节拍）
           ⚠️ 写 narration 前必读 SCRIPT-STYLE.md：对话体/第二人称/短句≤20字/去AI味/自然过渡禁用"接下来/总结一下/上回说到"
  foregroundUnits: ___ （只算文字/数字/图片/卡片/图标，背景纹理不计）
  risk: none | overload | subtitle | list-bomb | missing-source

S1:
  role: ...
  ...（每步一行，格式同上）

ROLE-TAG 说明：
  EMOTION-HOOK   = 情绪钩子（首屏吸引注意力）
  CONTRAST-REVEAL = 对比揭示（A vs B 并列展示差异）
  STAMP-OST      = 印章式定格（关键数字/结论砸下来）
  TAKEOVER       = 全屏接管（大图/大字占据视觉中心）
  TEASER         = 预告悬念（展示局部暗示整体）
  LIST-REVEAL    = 列表逐项揭示（ghost grid → stagger reveal）
  SINGLE-PROOF   = 单点证明（一个论据讲透）
  PROCESS-MAP    = 流程地图（多步骤流程可视化）
  CUSTOM         = 自定义（以上都不适用时）
```

---

## §2.5 Narration Gate（narrations 生成硬门槛）

> **为什么需要**：第一次生成 narrations 时，Agent 最容易走 `outline.md 概括 → 每章 4 句摘要` 的路径。
> 这条路径产出的 narrations 信息保留率可低至 **7%**（失败案例实测：某项目 narrations 仅 417 字 / script.md 原文 5647 字，偏差 58%），而 SCRIPT-STYLE.md 要求 ≥ 60%。
> Narration Gate 是防止这条错误路径的 6 道硬闸。**全部通过才能写 narrations.ts。**
> 
> 💡 以上 7% / 417字 / 5647字 / 58%偏差 为真实失败案例数据，用作警示依据。G4/G5 的阈值（20% / 60%）是独立于该案例的通用工程标准。

### 硬门槛清单（按顺序执行）

| # | 硬门槛 | 通过标准 | 不通过的后果 |
|---|--------|---------|------------|
| **G1** | **来源绑定**：找到本章对应的 `script.md` 原文段落（用 `outline.md` 口播节选定位） | 能标出 script.md 的起止行号（如 `L3-L22`） | ❌ 不能从 outline 摘要重写，必须回 script.md |
| **G2** | **关键事实提取**：列出 script 段落中的关键事实 / 案例 / 方法论（≥ 3 项） | 每项都是具体内容（数字/名称/步骤），不是抽象概括 | ❌ 提取不到 → 说明没读懂 script，不能继续 |
| **G3** | **节拍映射**：每条 narration 必须映射到 script 的一个 `---` 节拍区间 | 输出 sourceMap：`"S0←script Lx-Ly, S1←script La-Lb, ..."` | ❌ 某 narration 找不到对应节拍 → 该条是编造的，删除或重写 |
| **G4** | **偏差阈值**：实际 step 数 vs outline 声明的 step 数 | 偏差 ≤ 20% 可直接继续；> 20% 必须**停下并告知用户**确认 | ❌ 静默接受大幅缩减 = 纵容信息丢失 |
| **G5** | **信息保有率**：本章 narrations 总中文字数 ÷ 对应 script 段落中文字数 | **≥ 60%** 为通过；< 60% 必须补具体例子/数据直到达标 | ❌ 除非用户明确要求做预告片/短版，否则不豁免 |
| **G6** | **来源证据输出**：生成后输出 narration-source-map | 格式见下方模板 | ❌ 无 sourceMap = 无法追溯，视为未执行 G1-G3 |

### 输出模板（必须随 Draft Ledger 一起输出）

```markdown
## Narration Gate 执行结果

**G1 来源**: script.md L___-L___（本章在 script 中的完整段落）
**G2 关键事实**:
  1. ___（具体数字/案例/方法）
  2. ___
  3. ___
**G3 sourceMap**: "S0←script Lx-Ly, S1←script La-Lb, S2←script Lc-Ld, ..."
**G4 偏差**: outline 声明 __ 步 → 实际 __ 步 = 偏差 __%（✅≤20% / ⚠️>20%需确认）
**G5 信息保有率**: narrations ___ 字 / script段落 ___ 字 = __%（✅≥60% / ❌<60%需补充）
```

### 常见失败模式与修复

| 失败表现 | 根因 | 修复方式 |
|---------|------|---------|
| narrations 只有 3~4 条且每条都是概括句 | 从 outline 摘写而非 script 切分 | 回到 G1，重新定位 script 段落，逐节拍切分 |
| narrations 总字数 < script 的 30% | 把"改写"当成了"摘要" | 按 G5 补充：每步至少保留 1 个 script 中的具体元素 |
| 出现"第一步/第二部/第三步"等结构词 | 直接搬运了 script 的小标题 | 读 SCRIPT-STYLE.md 原则 7，改为自然过渡 |
| 实际 step 数远少于 outline | Agent 为了省事故意合并/砍步骤 | 触发 G4 偏差警报，需用户确认 |

---

### Final 模板（完工后）

```
Final Step Focus Ledger:
  S0→role=EMOTION-HOOK focus="对比卡片" units=2 risk=none ✅ 解释力=强（原因）
  S1→role=STAMP-OST focus="10x badge" units=3 risk=none ✅ 解释力=中（原因）
  S2→role=LIST-REVEAL focus="痛点网格" units=6 risk=overload ⚠️ 已拆为两步
  S3→role=TAKEOVER focus="机制链" units=4 risk=none ✅ 解释力=强（原因）
  过载步=1/4(25%) [说明]
  全局短板：S3 解释力可再加强（建议加 XXX）

  ── Signature 自评 ──
  记忆点: _________________________________ （观众看完能记住的一个画面？）
  是否只是 primitive 拼装: _______________ （是/否，如果是需说明补救措施）
  本章独有样式行数: ___ / 建议≤100 （超了说明哪些不能沉淀到 primitive）
```

### 关键字段说明

| 字段 | 为什么重要 | Agent 常犯的错 |
|------|-----------|--------------|
| **mainFocus** | 强制单一焦点决策 | 不填或填多个（"标题+卡片+数字都重要"） |
| **articleExtra** | 强制列出增量信息 | 填口播已念的内容（变成字幕机） |
| **whyRelevant** | 防止"乱挂信息"，迫使思考价值 | 填"因为原文有"或直接跳过 |
| **risk** | 强制自我评估风险 | 永远填 `none`（假装没问题） |
| **foregroundUnits** | 量化过载风险 | 忘记统计或故意少报 |

---

## §3 Failure Owner Map（每个坑的唯一入口）

> 同一个坑只在 **1 个文件** 详细解释。其他地方只引用 ID，不重复描述。
> 出了问题按此表找对应的 owner 文件。

| 坑类型 | 对应硬规则 | Owner 文件 | 关键操作 |
|--------|-----------|-----------|---------|
| 音画错位 / narrations 不同步 | H1 STEP-SYNC | `validate.sh` (C1) | `narrations.length === maxStep + 1` |
| **narrations 内容缩水 / 来源不明** | **H1-b NARRATION-SOURCE** | **§2.5 Narration Gate** | **G1 来源绑定 + G3 节拍映射 + G5 信息保有率 ≥ 60%** |
| 无主焦点 / 不知道看哪 | H2 FOCUS | **Step Focus Ledger** | Draft 填 `mainFocus`，Final 核实 |
| 字幕机 / 画面=口播打字 | H3 ADDITIVE | **Step Focus Ledger** | Draft 填 `articleExtra + whyRelevant` |
| 信息过载 / 一眼太多 | H4 NO-OVERLOAD | **Step Focus Ledger** | Draft 填 `foregroundUnits + risk` |
| 清单一次性全出 / PPT 感 | H5 REVEAL | `ANCHOR-CARD.md` | 选 list-reveal / hook-chapter 等 pattern |
| 假数据 / 编造信息 | H6 TRUTHFUL | `material-usage.ts` + Final 自检 | 用 placeholder 或留空 |
| 编译崩溃 / 白屏 / 动画乱 | H7 VALID | `validate.sh` | `npm run validate` |
| flex 子元素被压扁 / 尺寸异常 | H7 VALID | **§5 Anti-patterns** | 检查 `flex-shrink:0` + min-size 声明 |
| CSS 动画 scale(0) 导致布局抖动 | H7 VALID | **§5 Anti-patterns** | 用 `scale(0.9~0.95)` + opacity 替代 |
| 紫粉渐变 / emoji / 圆角边框 | —（审美层） | `TROUBLESHOOT.md` → anti-AI smell | 出问题时查阅 |
| CSS 类名跨章污染 | —（工程层） | `validate.sh` (C3) | grep 前缀隔离 |
| 动画单调 / 安全但平庸 | —（创意层） | `TROUBLESHOOT.md` → 创意激发 | 出问题时查阅 |
| 素材利用率低 | —（规划层） | `MATERIAL-INDEX.md` v2.0 规范 | Phase 0 自检 |

---

## §4 参考规则（非硬约束，但值得了解）

> 以下规则**不作为硬门槛**，但违反时大概率降低质量。
> 完整背景和 Failure Case 见 `/FAILURE_ANALYSIS.md`。

| ID | 规则 | 防的坑 | FA# | status |
|----|------|--------|-----|--------|
| [OVERLOAD] | mainFocus=1，articleExtra=0~3，foregroundUnits≤7 | 信息过载 | #7,#12,#13 | active |
| [LIST-BOMB] | 多点逐张揭示，1项=1step，禁一次性全出 | PPT感 | #9 | active |
| [SUBTITLE] | 屏幕信息 ≠ 口播字幕，必须增量补充 | 字幕机 | #10,#11 | active |
| [EMOJI] | 禁 emoji 图标，用 SVG / Unicode（✓✗→←↑） | 跨平台不一致 | #23,#39 | active |
| [HARDCOLOR] | 硬编码色值必须 `/* SEMANTIC-HARDCODE: 原因 */` | 换主题炸 | #14,#40 | active |
| [INF-MOTION] | 默认禁持续微动；仅允许背景/材质/高潮点 | 单调/伪电影感 | #8,#35 | active |
| [CSS-PREFIX] | 每章专属 CSS 前缀，禁跨章污染 | 样式泄漏 | #18,#30 | dormant |

> 注：[OVERLOAD] ≈ H4，[LIST-BOMB] ≈ H5，[SUBTITLE] ≈ H3。保留此表是为了与旧文档兼容和追溯 FA 编号。

### Pattern Primitives 使用策略（防模板化）

**目标比例：70% 复用低层 primitive + 30% 手写本章灵魂。**

> **CSS 预算提醒**：章节专属 CSS 建议控制在 **≤100 行**（Ch2=27行, Ch3=279行含签名动作）。超过 100 行需在 Final Ledger 的 Signature 自评中说明：哪些样式不能沉淀到 primitive，为什么。

| 层级 | 组件 | 使用规则 |
|------|------|---------|
| **低层** | `ChapterShell` / `Kicker` | 默认复用（纯工程组件，无视觉语义） |
| **高层** | `SlotGrid` / `FlowStrip` / `MegaBadge` ... | 只能作为起点，**必须做本章专属变体** |

> **高层 primitive 直接用 = 模板视频。** 每章的 `signatureMove` 必须是手写的、primitive 做不到的东西。

#### 故意不用高层 Primitive（创意逃生口）

如果本章主视觉需要突破模板（signatureMove 要求），可以完全不用高层 primitive。但必须：

1. **复用底层基础设施**：token/字号/stage-frame/validate 不绕过
2. **在 Draft Ledger 的 signatureMove 解释**：为什么这个视觉必须手写
3. **高层 primitive 为什么不适用**：具体差异（不是"我想自由发挥"）

#### 抽象门槛（防止过早抽象）

```
同一种结构出现 ≥ 2 章 → 才抽为 Primitive
同一种动画出现 ≥ 2 章 → 才进 patterns.css
只出现 1 次 → 留在章节专属 CSS
```

当前已满足门槛：ChapterShell / Kicker（Ch1+Ch2）。SlotGrid / FlowStrip 在 Ch2 首次使用。

---

## §5 视觉反模式速查（审美层，出问题再查）

| ❌ 禁止 | ✅ 替代 | 所属 owner |
|---------|--------|-----------|
| 紫粉渐变背景 | 主题 --bg token 或深色纯色 | TROUBLESHOOT |
| 圆角彩色边框 | 直角细线或无边框，用间距区分 | TROUBLESHOOT |
| emoji 当独立图标 | SVG / Unicode ✓✗→ 或 ImagePlaceholder | TROUBLESHOOT |
| 假数据/假logo | DataPlaceholder 组件或留空 | H6 TRUTHFUL |
| 装饰性持续动效 | 仅内容驱动动画（≤ 口播时长） | TROUBLESHOOT |
| flex 子元素缺 `flex-shrink:0` 保护 | 所有有固定尺寸的子元素显式声明 `flex-shrink:0; min-width/min-height` | **H7 VALID** |
| `@keyframes from { scale(0) }` 起始帧 | 用 `scale(0.9~0.95)` + `opacity:0` 替代，避免 getBoundingClientRect 报告异常尺寸 | **H7 VALID** |

---

## §6 完工自检（11 项，H1-H7 + Narration Gate + 风格）

- [ ] **H1**: `narrations.length === maxStep + 1`
- [ ] **H1-b**（Narration Gate）: G1-G6 全部通过，sourceMap 已输出，信息保有率 ≥ 60%
- [ ] **风格**: narration 已过 SCRIPT-STYLE.md 检查（对话体/第二人称/短句≤20字/去AI味/自然过渡禁用"接下来/总结一下/上回说到"）
- [ ] **H2**: 每 step 有且仅有 1 个 `mainFocus`（Final Ledger 核实）
- [ ] **H3**: 每章必须有 ADDITIVE 证据（至少 1 步有 articleExtra）；纯情绪 hook / 过渡 step 可为 0，但 Final Ledger 需说明原因
- [ ] **H4**: 每步 `foregroundUnits ≤ 7`，无 overload risk
- [ ] **H5**: 列表/多点内容逐项揭示，无一次性全出
- [ ] **H6**: 无假数据，缺素材用 placeholder
- [ ] **H7**: `npm run validate` 通过（TS 编译 + C1-C8）
- [ ] **material-usage**: 本章信息池中 priority=must 的条目已挂载到画面（`material-usage.ts` 或 Final 自检确认）
- [ ] **outline 偏差**: 若实际 step 数 < outline 声明的 80%，已在 Draft 阶段告知用户并获确认
