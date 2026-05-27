# Web Video Presentation — 完整工作流手册

> 本文档是 `web-video-presentation` Skill 的**完整工作流程与开发规范参考手册**（供开发者与 AI 协作时参考以开发高保真视频网页，项目运行时本身并不依赖此文档）。
> 所有约束文件（references/）和运行时模板（templates/）的变更都应同步更新本文档。
>
> **最后更新**：2026-05-19（v2.0 版：引入 Phase 0 预处理引擎 / MATERIAL-INDEX.md 替代 MATERIAL-GUIDE.md / ARTICLE-PROCESS-GUIDE + presets 插件式架构 / validate-outline 动态 SKIP 探测 / 时间估算矩阵 + 风险管理）

---

## 一、架构全景

```
┌─────────────────────────────────────────────────────────┐
│                    用户输入                                │
│  article-full.md（杂乱原始素材 / 公众号文章 / 论文等）      │
└──────────────────────┬──────────────────────────────────┘
                       │
          ┌────────────▼────────────┐
          │   Phase 0：数据预处理     │  ← 按 ARTICLE-PROCESS-GUIDE
          │   0.1 模板匹配(presets)    │     清洗噪音 + 补全结构
          │   0.2 选择性修剪+密度校验  │
          │   0.3 输出双文件           │
          │   article.md             │     纯净知识库
          │   MATERIAL-INDEX.md      │     素材索引（按章节定位）
          └────────────┬────────────┘
                       │
          ┌────────────▼────────────┐
          │   Phase 1：内容编写       │  ← agent 一次性产出
          │   script.md + outline.md  │     script（口播稿）
          └────────────┬────────────┘     outline（开发计划，v2 YAML 信息池）
                       │
          ┌────────────▼────────────┐
          │  Checkpoint Plan        │  ← ⛔ 必须停！用户审核 5 件事
          │  稿子/outline/主题/素材/模式│
          └────────────┬────────────┘
                       │
          ┌────────────▼────────────┐
          │   Phase 2：网页开发       │
          │  2.1 脚手架(scaffold.sh)   │
          │  2.2 第1章(完整版)         │ ← 读 CHAPTER-CRAFT.md (完整)
          │      ↓                 │
          │  [硬节点] 第1章验收      │ ← ⛔ 用户必须验收
          │  2.3 第2~N章            │ ← 读 CHEATSHEET.md (浓缩红线)
          │      ↓                 │
          │  Checkpoint Audio      │ ← ⛔ 是否合成音频？
          └────────────┬────────────┘
                       │
          ┌────────────▼────────────┐     ┌──────────────────┐
          │ Phase 3: 音频合成(可选)    │     │ Phase 4: 录屏后期  │
          │ extract → review → synthesize│     │ Auto 模式一镜到底  │
          └──────────────────────────┘     └──────────────────┘
```

### 核心文件角色

| 文件 | 角色 | 谁写 | 谁读 | 何时更新 |
|------|------|------|------|---------|
| `article.md` | 原始素材库 | **用户**提供 | agent Phase 1.2 + Phase 2.4 按 MATERIAL-INDEX 索引读 | Phase 0 清洗后不可变 |
| `script.md` | 口播稿（节拍源） | **agent Phase 1.2** 生成 | agent Phase 2.4 参考 | Checkpoint Plan 后可微调 |
| `outline.md` | 开发计划（信息密度源） | **agent Phase 1.2** 生成 | **用户** Checkpoint Plan 审核 | Phase 2 开发时可同步 step 数 |
| `MATERIAL-INDEX.md` | article → 素材索引 | **Phase 0 自动生成** | **agent Phase 2.4 每章必读**（位于项目根目录，替代读完整 article） | article 预处理时更新 |
| `CHAPTER-CRAFT.md` | 章节开发完整教程 | Skill 作者 | **仅第 1 章** agent 读 | 不常变 |
| `CHAPTER-CRAFT-CHEATSHEET.md` | 章节开发深度参考（视觉分级/决策树/安全区） | Skill 作者 | **第 2~N 章按需参考**（必读已浓缩到 CHAPTER-RULES-MINI.md） | 随完整版同步 |

---

## 二、Phase 0：启动前准备 (数据预处理)

### 0.1 识别并预处理输入

当用户提供的是杂乱的原始文章（如 `article-full.md`）时，必须先进行预处理：
1. **模板匹配**：阅读 `references/ARTICLE-PROCESS-GUIDE.md`，并根据素材类型从 `references/presets/` 选取对应模板。
2. **清洗与补全**：剔除无关噪声，将隐性对比/流程转化为显性的表格/列表，补全结构。
3. **密度自检**：确保每个 H2 下至少有 3 个视觉元素。
4. **生成产物**：输出纯净的 `article.md` 和对应的 `MATERIAL-INDEX.md`（素材索引）到项目根目录。
5. **📊 素引质量自检**（v2.0 新增）：详见下方 0.3 节。

### 0.3 素材索引质量自检（Phase 0.4）

> **触发时机**：生成 `article.md` + `MATERIAL-INDEX.md` 之后，进入 Phase 1 之前。
> **目的**：确保素材索引的质量和完整性，避免"有索引但无法使用"的问题。

#### 自检清单

```
□ 索引完整性：
  - 每章至少有 N 个 [MUST] 项（N = 预估 step 数 × 0.6，向上取整）
  - 每章至少有 M 个 [SHOULD] 项（M = 预估 step 数 × 0.4，向上取整）
  - 如果某章 [MUST] + [SHOULD] < 3 个 → 标记 ⚠️ 密度警告

□ 来源定位准确性：
  - 所有 [MUST] 项的 source 字段格式正确（article §X LYY-ZZ）
  - 抽查验证：随机选 2 个 source，确认 article.md 对应位置内容匹配
  - [SKIP] 区域占比合理（应占全文 50-80%）

□ 视觉角色分配：
  - 每个 [MUST] 项的 visual-role 值属于合法枚举（hook-reveal | comparison-proof | ...），不含 CSS/动画词（[OUTLINE-BOUNDARY]）
  - 不包含需要外部资源才能实现的效果（如"用原文图片"）
```

#### 处理方式

| 自检结果 | 处理 | 是否阻塞 |
|---------|------|---------|
| 全部通过 ✅ | 进入 Phase 1 | 否 |
| 有 ⚠️ 警告 | 标记警告，在 Checkpoint Plan 时让用户决定是否补充 | 否 |
| 有 ❌ 失败 | 必须修复后重新自检 | **是** |

> **详细规范**：参见项目根目录 `MATERIAL-INDEX.md` 的「素材使用规范（v2.0 新增）」章节。

| 用户的输入类型 | 该做的 |
|-----------|--------|
| 杂乱原始文章（公众号/论文等） | 走 Phase 0 预处理，产出纯净的 `article.md` 和 `MATERIAL-INDEX.md` |
| 直接的口播稿/视频脚本 | 准备好 `script.md`，Phase 1.2 简化 outline |
| 只有主题想法，没有内容 | **停下来**——先给素材或大纲。Skill 不替你构思内容 |

### 0.2 选择开发模式（Checkpoint Plan 时决定）

| 模式 | 代号 | 适用场景 | 并行能力 | 推荐度 |
|------|------|---------|---------|--------|
| 逐章确认 | A | 首次使用 / 追求质量 | ❌ 串行 | ★★★ 默认推荐 |
| 顺序开发 | B | 有经验 / 想快速推进 | ❌ 串行 | ★★☆ |
| 并行 subagent | C | 章节多 / 时间紧 | ✅ 并行 | ★☆☆（需设计决策卡） |

---

## 三、Phase 1：内容编写（一次产出）

> **负责人：AI Agent**
> **输入**：`article.md`
> **输出**：`script.md` + `outline.md`
> **必须读取的约束文件**：

| 步骤 | 读什么 | 目的 |
|------|--------|------|
| 1.1 | [`SCRIPT-STYLE.md`](references/SCRIPT-STYLE.md) | 8 条口语化原则 + 去 AI 味 + 三层自检 |
| 1.2 | [`OUTLINE-FORMAT.md`](references/OUTLINE-FORMAT.md) | outline 格式 spec（含 v2 YAML 信息池格式）+ 画面感写作规范 |
| 1.2 | `article.md` | 双源原则：script 定节拍，article 定画面密度 |

### 1.2.1 生成 `script.md`

按 SCRIPT-STYLE.md 规则：
- B 站风格口语化（短句、第二人称、3 秒钩子）
- 信息保留度 ≥ 60%
- 用 `---` 分隔每个节拍段
- 每节拍对应 1~2 个 step

### 1.2.2 生成 `outline.md`

按 OUTLINE-FORMAT.md 规则：

**顶部 metadata**：
```markdown
> **主题**：<theme-id>
> **总时长**：约 X 分 Y 秒
> **章节数**：N 章 / M 步
```

**每章结构**：
```markdown
## N. <chapter-id> — <标题>（S steps · ~Ts）

**信息池**:

```yaml
- id: <全局唯一kebab-case>
  label: "<人类可读描述>"
  type: text-quote | data | case | term-pair | comparison | concept
  source: article §X LYY-ZZ           # 必须：MATERIAL-INDEX 可用区域
  visual-role: <叙事功能>            # 可选（hook-reveal / comparison-proof / ...）
  priority: must | should | optional   # 可选，默认 should
  for-steps: [step编号...]            # 🆕 v2.0 必填：素材→step 映射
```

> **⚠️ for-steps 字段（v2.0 新增必填）**：
> - **作用**：强制规划时思考"这个素材放在哪个 step"，便于开发时交叉验证
> - **格式**：`for-steps: [2, 3]` 表示该素材用于第 2 和第 3 个 step
> - **校验**：`validate-outline.sh` 会检查 ≥80% 的条目是否有此字段
> - **详细规范**：参见 `MATERIAL-INDEX.md` 的「三、交付物增强」章节

**Step 规划**：
- step N (~Ts) — <屏幕内容，≥ 2 个视觉维度>

**type 枚举速查**：
| type | 含义 | 典型 visual-role |
|------|------|-------------------|
| `text-quote` | 可引用文字片段 | single-proof / quote-evidence |
| `data` | 数字/比例/统计 | single-proof / comparison-proof |
| `case` | 案例/故事/人物线 | list-progress / process-map |
| `term-pair` | ❌→✅ 术语对比 | comparison-proof |
| `comparison` | A vs B 对比 | comparison-proof |
| `concept` | 概念/原理/方法论 | process-map |
```

**画面感要求**（每步描述必须包含 ≥ 2 个视觉维度）：
- **焦点**："中央" / "右上角" / "底部居中"
- **层次**："缩小到顶部 kicker" / "保留上方作上下文"
- **动作暗示**："亮起" / "灰化保留" / "划掉→弹入"

**outline 绝对不写**：
- 动画类型（blur clear / wipe / 弹簧）
- CSS 实现手段（filter / SVG / clip-path）
- 具体毫秒数

### Phase 1 交付物

```
✅ script.md —— 完整口播稿，用 --- 分节拍
✅ outline.md —— 开发计划，含 v2 YAML 信息池
⬜️ 进入 Checkpoint Plan（必须停下等用户审核）
```

---

## 四、Checkpoint Plan（⛔ 硬节点）

> **负责人：用户（审核）+ AI Agent（等待指令）**

### 一次性对齐 5 件事

| # | 对齐项 | 用户决定 | 输出 |
|---|--------|---------|------|
| 1 | **稿子** | script.md 内容 OK？还是想改？ | 确认/修改 script.md |
| 2 | **outline** | 章节切分合理？信息池够？ | 确认/修改 outline.md |
| 3 | **主题** | 从 10 套内置主题选 1 套 | 写 `.theme` 文件记录 theme-id |
| 4 | **素材** | 缺哪些图片/数据/案例？ | 补充或标注 placeholder |
| 5 | **模式** | A 逐章 / B 顺序 / C 并行？ | 决定开发模式 |

### 审核清单

```markdown
- [ ] script.md 每段都是口语化的（能念出来不尴尬）
- [ ] outline 每章 3~8 step，总时长合理
- [ ] outline 信息池每条有 source（指向 article 可用区域）
- [ ] outline 每步描述有 ≥ 2 个视觉维度（不是纯信息罗列）
- [ ] 主题已选定且 .theme 文件已创建
```

**通过后 → 进入 Phase 2**

---

## 五、Phase 2：网页开发

### 2.1 脚手架初始化（一次）

```bash
bash .trae/skills/web-video-presentation/scripts/scaffold.sh ./presentation --theme=<theme-id>
```

自动完成：
1. `npm create vite` 创建项目
2. 替换模板文件（base.css / base-typography.css / animations.css / App.tsx / hooks / components / registry / example 章节）
3. 注入选定主题的 `tokens.css`
4. 注册 npm scripts（extract-narrations / synthesize-audio）
5. 创建 `public/audio/` 目录
6. 跑 `npx tsc --noEmit`

**产物**：可运行的 Vite + React + TS 项目

---

### 2.2 第 1 章 = 完整版本（风格锚点）

> **这是全项目最重要的章节。** 后续所有章节（无论顺序还是并行）都以第 1 章为风格参照。

#### 2.2.1 Agent 必读文件

| 文件 | 版本 | 原因 |
|------|------|------|
| [`CHAPTER-CRAFT.md`](references/CHAPTER-CRAFT.md) | **完整版** | 第一次需要理解"为什么这么做"（教程式解释） |
| 当前主题 `themes/<id>/theme.json` | — | 了解 mood / bestFor / preview 色 |
| 当前章节 outline 段落 | — | 本章的 step 划分和信息池 |
| `article.md` 本章对应段落 | — | 双源原则：回原文抽细节 |
| **`MATERIAL-INDEX.md`** 本章段落 | **新增** | 素材索引（不用读完整 article） |

#### 2.2.2 十条原则速记（写代码时心中默念）

| # | 原则 | 一句话检查 |
|---|------|-----------|
| 1 | 16:9 固定舞台 | 内容 1920×1080 + transform scale |
| 2 | 全局 step 计数器 | 章节是 step 的纯函数 |
| 3 | 每步独占整屏 | `if (step === N) return <FullScene />` |
| 4 | 口播节拍 = step | 一节拍 = 一 step = 一聚焦想法 |
| 5 | 隐藏边角控件 | 进度条/翻页器默认 opacity 0 |
| 6 | 舞台无 chrome | 无 header/footer/页码/品牌条 |
| 7 | **内容驱动动画** | 先找内在动作，找不到才入场动画兜底 |
| 8 | 多点逐个揭示 | 1 项 = 1 step，禁同步 stagger 上 N 项 |
| 9 | 整片同一主题 | 颜色/字体走 token，其它自由 |
| 10 | 双源原则 | script 定节拍，article 定画面密度 |

#### 2.2.3 字号硬性下限（不合格 = 回去改）

| 元素类型 | 最小字号 | 说明 |
|---------|---------|------|
| hero 标题 | **80px** | 全屏主文字 |
| 副标题/kicker | **48px** | 二级标题 |
| 正文/列表项 | **28px** | 主要阅读文字 |
| 标注/cue/元数据 | **18px** | 角标/来源 |
| 极小标签 | **14px** | badge/tag（极短 2~3 字） |

#### 2.2.4 产出文件（3 个必选 + 1 个推荐）

```
src/chapters/01-<id>/<Chapter>.tsx       # 组件（if/switch step 渲染）
src/chapters/01-<id>/<Chapter>.css       # 样式（全部走 var(--token)）
src/chapters/01-<id>/narrations.ts     # 口播文本数组（= max step + 1）
src/chapters/01-<id>/material-usage.ts # 🆕 v2.0 推荐：素材使用追踪
```

> **material-usage.ts 说明**（v2.0 新增，推荐但非强制）：
> - **作用**：追踪本章使用了 MATERIAL-INDEX 中的哪些素材，计算覆盖率
> - **格式**：参见 `MATERIAL-INDEX.md` 的「三、交付物增强 → 3.2」章节
> - **价值**：便于自动化检查 + 后续迭代时补充遗漏素材

注册到 `src/registry/chapters.ts`。

#### 2.2.5 完工自检（8 项核心 + 10 项建议）

> 详见 [CHAPTER-RULES-MINI.md](references/CHAPTER-RULES-MINI.md) §7 完工自检清单，或 [CHAPTER-CRAFT-CHEATSHEET.md](references/CHAPTER-CRAFT-CHEATSHEET.md)「完工自检清单」章节获取完整版。

**🔴 核心必查（8 项，阻塞交付）**：

| # | 检查项 | 失败后果 |
|---|--------|---------|
| C1 | `narrations.ts` 存在且 `length === max(step) + 1` | Auto 录屏音画错位 |
| C2 | `npx tsc --noEmit` 通过 | 编译错误 |
| C3 | 无硬编码 hex/颜色名/字体名（语义例外需注释） | 换主题爆炸 |
| C4 | 字号达到硬性下限（L1≥80 / L2≥56 / L3≥48 / L4≥32 / L5≥24 / L6≥18 / L7≥16 / L8≥14） | 小屏不可读 |
| C5 | 每章至少 1~2 处视觉演示 | 像 PPT |
| C6 | 每步动画时长 ≤ 口播时长（字数÷4≈秒） | Auto 模式切断 |
| C7 | 独立 CSS 前缀，未跨章 import | 耦合污染 |
| C8 | 无 emoji 图标（content emoji 允许但需标注） | 跨平台不一致 |

**🟡 建议检查（11 项，未过需说明原因）**：
不同 step 主导动作不同 / 留白配色走 token / 清单逐个揭示 / 信息密度>口播 / 无紫粉渐变假数据 / 缺素材用 placeholder / primitive class 接主题 / 无页眉页脚 / 无小号纯文字 / 主动告知缺素材 / **🆕 素材覆盖率 ≥ 60%（[MUST] 100% + [SHOULD] > 60%）**

> **🆕 素材覆盖率检查说明**（v2.0 新增）：
> - **计算方式**：对比 `MATERIAL-INDEX.md` 中本章的 `[MUST]`/`[SHOULD]` 条目与实际使用情况
> - **工具支持**：可手动统计或使用 `material-usage.ts` 自动计算
> - **不通过处理**：如果覆盖率 < 40%，必须补充素材或调整 step 划分；如果在 40-60%，需说明原因
> - **详细标准**：参见 `MATERIAL-INDEX.md` 的「一、覆盖率标准」章节

#### 2.2.6 [硬节点] 用户验收第 1 章

**用户操作**：
1. `npm run dev` 启动 dev server
2. 浏览器打开 `http://localhost:5173/`
3. 用 ← → Space 切换 step，审查每一屏
4. 反馈修改意见

**如果第 1 章有问题** → agent 修改直到通过。**第 1 章是后续所有章节的风格锚点，这里暴露的问题越早修成本越低。**

---

### 2.3 第 2~N 章

#### 2.3.1 Agent 必读文件（与第 1 章的关键差异）

| 文件 | 第 1 章 | 第 2~N 章 |
|------|---------|----------|
| CHAPTER-CRAFT | **完整版**（223 行，含教程解释） | **跳过** |
| CHAPTER-RULES-MINI | 不需要 | **必读**（~93 行硬规则速查） |
| ANCHOR-CARD | 不需要 | **开工前必读**（~22 行结构卡） |
| CHAPTER-CRAFT-CHEATSHEET | 不需要 | 按需深度参考（视觉分级/决策树） |
| MATERIAL-INDEX.md | 可选 | **必读**（本章段落，~80 行，根目录查找） |
| 第 1 章代码 | 不需要 | **作为风格参考传入 prompt**（不是抄袭对象） |

**Token 节省**：第 2~N 章每章必读 ~115 行（MINI 93 + ANCHOR-CARD 22），替代旧 CHEATSHEET ~100 行 + article 全文

#### 2.3.2 三种开发模式

**Mode A — 逐章确认（默认推荐）**：
```
写第 2 章 → 用户审核 → 改 → 通过 → 写第 3 章 → ...
```
- 最稳，适合首次使用
- 每章都有人工质量把控

**Mode B — 顺序开发**：
```
写第 2 章 → 直接写第 3 章 → ... → 最后统一审核
```
- 快但风险累积：前面犯的错误会传播到后面
- 适合有经验的用户

**Mode C — 并行 subagent**：
```
主 agent:
  1. 完成第 1 章（anchor）
  2. 生成「第 1 章设计决策卡」：
     - 演示手法：CSS数字动画 + SVG对比图表
     - 动画基调：利落线性 ~400ms
     - 字号层级：hero 96px / sub 48px / cue 16px
     - 颜色消费策略：--text 为主 + --accent 点缀
  3. 为每个 subagent 准备独立 prompt（含决策卡）
  4. 启动 N 个 subagent 并行开发第 2~N 章

subagent 每人:
  1. 读 CHEATSHEET.md（浓缩红线）
  2. 读 Material Guide 本章段落
  3. 读 theme.json
  4. 读第 1 章代码（风格参考，非抄袭）
  5. 读决策卡
  6. 独立写 chapter 代码
  7. 完工自检
  8. 汇报交付
```
- 最快但需要用户有能力整合多个 subagent 的产出
- **物理隔离保证安全**：每章独立文件夹/CSS前缀/不跨章import

---

### 2.4 可选：新建章节脚手架

```bash
npm run new-chapter --id=<chapter-id> --title="章节标题"
# 自动：建文件夹 → 模板 tsx/css/narrations → 注册到 chapters.ts
```

---

### 2.5 可选：校验 outline 质量

```bash
bash .trae/skills/web-video-presentation/scripts/validate-outline.sh outline.md
# 9 项自动化校验：metadata/信息池/step范围/时长/非法字段/
#   画面感/利用率/视觉多样性/素材来源有效性
```

---

## 六、Checkpoint Audio（⛔ 硬节点）

> **负责人：用户决定**

| 选择 | 做法 | 后续 |
|------|------|------|
| **合成音频** | 进入 Phase 3 | 有音频后可开启 Auto 模式（音画同步自动推进） |
| **跳过音频** | 直接进入 Phase 4 | 只能用 Manual 模式（手动点按推进） |

---

## 七、Phase 3：音频合成（可选）

### 3.1 提取口播文本

```bash
npm run extract-narrations
# 扫描所有 chapters/*/narrations.ts → 生成 audio-segments.json
```

### 3.2 审核与合成

```bash
# 1. 审核 audio-segments.json（每条对应一个 mp3）
npm run synthesize-audio
# 2. 自动调用 mmx-cli 串行合成 mp3 → public/audio/<id>/<step>.mp3
#    支持断点续合（中断后重跑只合成缺失的）
```

### 退化路径（mmx 未安装时）

| 情况 | 处理 |
|------|------|
| mmx-cli 已安装 | 正常 TTS 合成 |
| mmx 未安装但有自定义 TTS | 用户自行合成，放入 `public/audio/<id>/` |
| 完全无音频 | 跳过；Auto 模式下用字数估时退化（max(1500ms, 字数×250ms)） |

---

## 八、Phase 4：录屏与后期

### 4.1 推荐录屏方式

**Auto 模式一镜到底**（推荐）：
```bash
# 浏览器打开 ?auto=1
# 音频就位后按 SPACE 开始
# 每步自动：播放音频 → 等待结束 → 自动推进下一步
# 录制整个浏览器窗口即可
```

### 4.2 手动录屏

| 工具 | 平台 | 说明 |
|------|------|------|
| QuickTime Player | macOS | Cmd+Shift+5 选区录制 |
| OBS | 全平台 | Scene → Display Capture → Start Recording |

### 4.3 后期工具（可选）

| 工具 | 用途 |
|------|------|
| FFmpeg | 裁剪/转码/压缩 |
| HandBrake | 视频压缩 |

---

## 九、文件依赖关系图

```
SKILL.md (流程宪法)
  │
  ├── references/
  │   ├── SCRIPT-STYLE.md ────── Phase 1.1-1.2 (写稿规则)
  │   ├── OUTLINE-FORMAT.md ──── Phase 1.2 (outline spec, 含 v2 YAML 信息池)
  │   │   └── 画面感写作规范
  │   ├── CHAPTER-CRAFT.md ───── Phase 2.2 仅第1章 (完整教程)
  │   ├── CHAPTER-RULES-MINI.md ──── Phase 2.3 第2~N章 (硬规则速查, 93行)
  │   ├── CHAPTER-CRAFT-CHEATSHEET.md ── 按需深度参考 (视觉分级/决策树/安全区)
  │   │   ├── 十条原则
  │   │   ├── 开工 5 问
  │   │   ├── 决策树
  │   │   ├── 工具箱
  │   │   ├── 时长参考
  │   │   ├── 反 AI 味反模式
  │   │   ├── 代码硬规则
  │   │   ├── 字号硬性下限表
  │   │   ├── 完工自检（8 核心 + 10 建议）
  │   │   └── 反馈速查
  │   ├── THEMES.md ───────────── Checkpoint Plan (选主题)
  │   │   └── 10 套主题 token 契约
  │   ├── AUDIO.md ─────────────── Phase 3 (音频合成)
  │   └── RECORDING.md ────────── Phase 4 (录屏指引)
  │
  ├── MATERIAL-INDEX.md ──────── Phase 2.4 每章必读 (素材索引, 替代读完整 article)
  │   └── 按 5 章组织 + 来源定位 + 渲染建议 + SKIP 区域 (~1100行)
  │
  ├── templates/ ─────────────── scaffold.sh 复制到项目
  │   ├── src/hooks/          (useStepper / useAudioPlayer / useAutoMode / useStageScale)
  │   ├── src/components/     (Stage / MaskReveal / ProgressBar / AutoToggle /
  │   │                      AutoStartGate + ImagePlaceholder /
  │   │                      AudioPlaceholder / DataPlaceholder)
  │   ├── src/styles/         (base.css / base-typography.css / animations.css)
  │   ├── src/registry/        (types.ts / chapters.ts)
  │   └── src/chapters/01-example/ (Example.tsx / Example.css / narrations.ts)
  │
  └── scripts/
      ├── scaffold.sh          (2.1 脚手架)
      ├── new-chapter.sh        (2.3 新建章节)
      ├── extract-narrations.ts (3.1 提取口播)
      ├── synthesize-audio.sh  (3.2 音频合成)
      ├── migrate-outline.sh    (v1↔v2 格式迁移)
      └── validate-outline.sh   (outline 9 项校验)

presentation/ (产出物)
  ├── src/chapters/NN-<id>/   (每章独立目录)
  ├── src/styles/tokens.css   (当前主题 token)
  ├── .theme                 (当前主题 id)
  ├── public/audio/<id>/      (合成后的 mp3)
  ├── article.md              (原始素材)
  ├── script.md               (口播稿)
  └── outline.md              (开发计划, v2 YAML 信息池)
```

---

## 十、时间估算矩阵

> 以下时间为**典型项目**的参考值（基于 5 章 / 25 步 / 8 分钟成品视频）。
> 实际耗时受素材质量、审核反馈轮次、Agent 能力等因素影响。

### 10.1 各阶段耗时总览

| 阶段 | 负责人 | 预估耗时 | 说明 |
|------|--------|---------|------|
| **Phase 0：数据预处理** | 用户 + AI Agent | **20~40 min** | 详见下方拆分 |
| ├── 0.1 准备原始素材 | **用户** | **5~10 min** | 整理 article-full.md 或确认输入完整性 |
| ├── 0.2 Agent 预处理执行 | **AI Agent** | **10~20 min** | 按 ARTICLE-PROCESS-GUIDE 清洗 + 产出双文件 |
| └── 0.3 审核清洗结果 | **用户** | **5~10 min** | 确认 article.md 质量与 MATERIAL-INDEX 索引准确性 |
| **Phase 1：内容编写** | AI Agent | **10~20 min** | 一次性产出 script + outline |
| **Checkpoint Plan** | 用户 | **10~30 min** | 审核 5 项对齐内容（可并行其他事务） |
| **Phase 2.1：脚手架** | AI Agent | **2~3 min** | 自动化脚本执行 |
| **Phase 2.2：第 1 章** | AI Agent | **20~40 min** | 最重要章节，含多轮自检 |
| **[硬节点] 第1章验收** | 用户 | **10~20 min** | 必须逐屏审查 |
| **Phase 2.3：第 2~N 章** | AI Agent | **15~30 min/章** | 取决于模式（A/B/C） |
| **Checkpoint Audio** | 用户 | **< 2 min** | 快速决策是否合成音频 |
| **Phase 3：音频合成** | AI Agent | **5~15 min** | 取决于内容长度 + TTS 速度 |
| **Phase 4：录屏后期** | 用户 | **10~30 min** | 一镜到底录制 + 可选压缩 |

### 10.2 典型项目总耗时估算

| 项目规模 | 章节数 | 总步数 | 预计成品时长 | **预估总耗时** |
|---------|--------|--------|-------------|---------------|
| 迷你演示 | 1~2 章 | 5~10 步 | 1~2 分钟 | **1~2 小时** |
| 标准项目 | 3~5 章 | 15~30 步 | 5~10 分钟 | **3~5 小时** |
| 大型专题 | 6~10 章 | 30~60 步 | 10~20 分钟 | **6~10 小时** |

### 10.3 耗时影响因子

| 因子 | 影响程度 | 说明 |
|------|---------|------|
| 素材质量 | ⭐⭐⭐⭐⭐ | 高质量 article → Phase 1 更快 → outline 更准 → 开发更顺 |
| 第 1 章验收轮次 | ⭐⭐⭐⭐⭐ | 每多一轮修复 = +20~40 min；**第 1 章是杠杆点** |
| 审核响应速度 | ⭐⭐⭐⭐ | Checkpoint 停留时间完全取决于用户 |
| Agent 模型能力 | ⭐⭐⭐ | 更强模型 = 更少修复轮次 = 省 Token + 时间 |
| 并行开发能力 | ⭐⭐ | Mode C 可缩短 Phase 2.3 但增加整合成本 |
| 音频合成方式 | ⭐⭐ | mmx-cli 自动 vs 手动合成差异大 |

### 10.4 关键路径分析

```
最长关键路径（决定项目最短完成时间）：

Phase 0(用户) → Phase 1(Agent) → Checkpoint Plan(用户)
    → Phase 2.1(Agent) → Phase 2.2(Agent) → [验收](用户)
    → Phase 2.3(Agent, N章串行) → Phase 4(用户)
    ──────────────────────────────────────────────
                    ≈ 3~8 小时（标准项目）

可并行的非关键路径：
├── Phase 3（音频合成）可在 Phase 2.3 后与 Phase 4 并行准备
└── Mode C 下第 2~N 章可并行（需额外整合时间）
```

---

## 十一、风险管理

### 11.1 风险矩阵

| # | 风险事件 | 概率 | 影响 | 风险等级 | 应对策略 |
|---|---------|------|------|---------|---------|
| R1 | **article.md 质量差/结构混乱** | 高 | 高 | 🔴 严重 | Phase 0 前置检查清单；必要时用户预处理 |
| R2 | **outline 信息池不足/step 过少** | 中 | 高 | 🔴 严格 | validate-outline.sh 9 项校验；画面感≥2维度规则 |
| R3 | **第 1 章风格不符合预期** | 高 | 高 | 🔴 严重 | [硬节点] 强制验收；十条原则+18项自检量化标准 |
| R4 | **Token 消耗超预算** | 中 | 中 | 🟡 注意 | Cheatsheet 替代完整版；Material Guide 替代全文 |
| R5 | **风格漂移（后续章节偏离第1章）** | 中 | 中 | 🟡 注意 | 第1章代码作为风格参考传入 prompt；Mode C 决策卡 |
| R6 | **音频合成失败/mmx 未安装** | 低 | 低 | 🟢 可控 | 退化路径：手动合成或跳过用 Manual 模式 |
| R7 | **依赖安装失败（Node/npm）** | 低 | 中 | 🟡 注意 | scaffold.sh 内置版本检查 + 报错指引 |
| R8 | **用户审核延迟导致项目停滞** | 中 | 中 | 🟡 注意 | 明确每个 Checkpoint 的审核清单，减少决策负担 |
| R9 | **CSS 硬编码导致主题切换困难** | 中 | 低 | 🟢 可控 | base-typography.css 共享层；var(--token) 强制约束 |
| R10 | **narrations.ts 与 step 数不同步** | 中 | 中 | 🟡 注意 | narrations 作为单一事实来源；自检第 4 项强制校验 |
| R11 | **预处理过度修剪导致信息丢失** | 中 | 高 | 🔴 严格 | ARTICLE-PROCESS-GUIDE "宁可多留不可多删"原则；密度校验 < 3 时必须警告 |
| R12 | **presets 模板不匹配素材类型** | 低 | 中 | 🟡 注意 | 提供 `_TEMPLATE.md` 扩展；允许组合多 preset 规则 |
| R13 | **🆕 素材未充分利用（利用率 < 40%）** | **高** | **高** | 🔴 严格 | Phase 0.4 索引质量自检；outline for-steps 必填；Phase 2.5 覆盖率检查 ≥ 60% |

### 11.2 关键风险深度应对

#### 🔴 R1：article.md 质量问题

**症状**：
- 文章结构不清晰（无明确章节划分）
- 缺少数据/案例/引用（信息密度低）
- 语言风格过于学术/晦涩（难以口语化）

**预防措施**：
```markdown
## Phase 0 前置检查清单
- [ ] 文章有明确的章节结构（或可按逻辑切分）
- [ ] 包含至少 3~5 个可引用的数据点/案例
- [ ] 核心论点清晰，不是纯理论堆砌
- [ ] 总字数在 2000~10000 字之间（过短则内容薄，过长则需裁剪）
```

**应急方案**：
- 用户预处理：高亮关键段落、标注可用素材区域
- Agent 降级处理：基于现有内容生成简化版 outline（减少 step 数）

---

#### 🔴 R2/R3：outline 与第 1 章质量问题

**根因链**：
```
outline 质量差 → 第 1 章开发缺依据 → 视觉效果差 → 多轮修复 → Token 浪费
```

**防御层级**：

| 层级 | 工具/方法 | 时机 | 效果 |
|------|----------|------|------|
| L1 | `validate-outline.sh` 9 项自动化校验 | Phase 1 产出后立即 | 拦截格式错误/遗漏字段 |
| L2 | 画面感写作规范（≥2 视觉维度） | Phase 1.2.2 生成时 | 保证每步有足够视觉信息 |
| L3 | Checkpoint Plan 人工审核 | Phase 1 后 | 用户把关整体合理性 |
| L4 | 十条原则 + 分层自检（8 核心 + 10 建议） | Phase 2.2 开发时 | 量化标准防止偏差 |
| L5 | [硬节点] 第 1 章验收 | Phase 2.2 后 | 最终质量门禁 |

---

#### 🟡 R4：Token 消耗优化

**已实施的优化措施**：

| 优化点 | Before | After | 节省 |
|--------|--------|-------|------|
| 第 2~N 章参考文档 | CHAPTER-CRAFT.md (223 行) | CHEATSHEET.md (~100 行) | **~50%** |
| 素材读取 | 读完整 article.md | MATERIAL-INDEX.md (~80 行/章) | **~70%** |
| CSS 复用 | 每章独立写排版类 | base-typography.css 共享层 | **~30%/章** |

**进一步优化建议**：
- 使用更强模型（如 Claude Opus）减少修复轮次
- Mode A 逐章确认避免大规模返工
- 定期清理上下文窗口中的冗余信息

---

#### 🟡 R5：风格一致性保障

**Mode B/C 下的特殊风险**：

```
第 1 章（anchor）→ 第 2 章（略偏）→ 第 3 章（更偏）→ ... → 风格漂移累积
```

**应对策略**：

1. **设计决策卡**（Mode C 必须）：
   ```markdown
   ## 第 1 章设计决策卡
   - 演示手法：CSS数字动画 + SVG对比图表
   - 动画基调：利落线性 ~400ms
   - 字号层级：hero 96px / sub 48px / cue 16px
   - 颜色消费策略：--text 为主 + --accent 点缀
   ```

2. **代码审查锚点**：每章完成后对比第 1 章的：
   - 字号使用是否符合下限表
   - 是否消费 var(--token) 而非硬编码
   - 动画节奏是否一致

3. **CHEATSHEET 强约束**：红线规则不可违反

---

#### 🔴 R11：预处理过度修剪（Phase 0 专有）

**根因链**：
```
Agent 激进删除"看起来无用"的内容 → article.md 信息密度不足
→ outline 信息池贫乏 → 章节画面空洞 → 用户验收不通过
```

**防御层级**：

| 层级 | 工具/方法 | 时机 | 效果 |
|------|----------|------|------|
| L1 | ARTICLE-PROCESS-GUIDE 第 2 节「选择性修剪」原则 | Phase 0.2 执行时 | 强制"宁可多留不可多删" |
| L2 | 第 4 节「素材密度校验」硬指标 | Phase 0.2 输出前 | 每 H2 < 3 个视觉元素 = 必须警告 |
| L3 | Phase 0.3 用户审核清洗结果 | Phase 0.3 | 最终质量门禁 |

**应急方案**：
- 发现信息丢失 → 回归原始 `article-full.md` 重新提取
- 密度警告未消除 → 标记为 `[OPTIONAL]` 占位，在 Checkpoint Plan 时让用户决定是否补充

---

#### 🟡 R12：Presets 模板不匹配（Phase 0 专有）

**症状**：
- 用户的素材同时具备多种特征（如"技术讲解 + 产品评测"）
- 单一 preset 规则无法覆盖所有预处理需求

**应对策略**：

1. **组合规则**：从多个 preset 中各取所需规则组合使用
2. **_TEMPLATE 扩展**：基于空白模板创建项目专属规则
3. **降级处理**：若无匹配 preset，走通用流程（仅做基础修剪，不做类型特化）

---

#### 🔴 R13：素材未充分利用（v2.0 新增）

**根因链**：
```
MATERIAL-INDEX 有素材但 Agent 未使用 → 画面信息 = 口播信息
→ 违反双源原则 → 视频无存在意义 → 用户验收不通过
```

**症状**：
- 章节只使用了 [MUST] 项，[SHOULD]/[OPTIONAL] 完全未使用
- 每章素材利用率 < 40%
- 用户反馈："太空"、"内容太少"、"像 PPT"

**防御层级**：

| 层级 | 工具/方法 | 时机 | 效果 |
|------|----------|------|------|
| L1 | Phase 0.4 索引质量自检 | 预处理后 | 确保 [MUST]+[SHOULD] 数量充足 |
| L2 | outline.md `for-steps` 必填字段 | Phase 1.2.2 | 强制规划素材→step 映射 |
| L3 | Agent 开发前必读 MATERIAL-INDEX | Phase 2.x 开发时 | 完整阅读不只扫 [MUST] |
| L4 | material-usage.ts 覆盖率追踪 | Phase 2.x 交付时 | 量化利用率数据 |
| L5 | 完工自检第 11 项（覆盖率 ≥ 60%） | Phase 2.5 | 最终质量门禁 |

**应急方案**：

| 触发条件 | 方案 | 操作 |
|---------|------|------|
| 覆盖率 < 40%，时间充裕 | **A: 补充素材** | 回 MATERIAL-INDEX 查遗漏，向用户确认后补充 |
| 覆盖率 40-60% | **B: 调整 step 划分** | 合并低价值 step，释放容量展示更多素材 |
| 必须按时交付 | **C: 标注技术债** ⚠️ | 记录在 material-usage.ts + FAILURE_ANALYSIS.md，需用户同意 |

> **详细规范**：参见项目根目录 `MATERIAL-INDEX.md` 的「素材使用规范（v2.0 新增）」章节。

---

### 11.3 应急预案速查

| 触发场景 | 应急动作 | 恢复条件 |
|---------|---------|---------|
| Phase 0 预处理后信息密度不足 | 回归 article-full.md 重跑修剪（调低激进度） | 每 H2 ≥ 3 个视觉元素 |
| Phase 0 presets 无匹配模板 | 组合多 preset 规则或用 _TEMPLATE 扩展 | 预处理规则覆盖主要噪声类型 |
| Phase 1 产出完全不达标 | 重跑 Phase 1，提供更详细指令 | outline 通过 validate + 人工审核 |
| 第 1 章验收连续 2 轮未通过 | 回退到 Phase 1 优化 outline | 第 1 章验收通过 |
| 开发中途 Token 耗尽 | 导出当前进度，新会话从断点继续 | 所有章节开发完成 |
| 音频合成持续失败 | 切换到 Manual 模式跳过音频 | 项目可正常录屏 |
| npm 依赖冲突 | 删除 node_modules 重装 | `npm run dev` 正常启动 |
| 主题效果不满意 | 更换 .theme 文件重新选主题 | 视觉效果符合预期 |
| 🆕 章节素材利用率 < 40% | 按优先级执行：A.补充素材 → B.调整step → C.标注技术债（需用户同意）| 覆盖率 ≥ 60% 或用户明确接受当前质量 |

---

## 十二、常见问题速查

| 你遇到的问题 | 可能原因 | 解决 |
|---------------|---------|--------|
| "字体太小" | 字号低于下限标准 | 按 CHAPTER-CRAFT 字号表调大（hero≥80/sub≥48/body≥28/cue≥18） |
| "太空/内容太少" | 没回 article 抽细节 | 挂信息池数据到具体 step（双源原则） |
| "像 PPT" | 纯文字/同一动画/无视觉演示 | 加 CSS/SVG 演示 + 变化动画 |
| "太花哨" | 每步都有持续微动/ken burns | 砍装饰动画，保留内容驱动 |
| "看不懂在讲什么" | 信息太密或缺少焦点 | 每步只放 1~3 个东西，hero 明确 |
| "节奏太快/太慢" | step 切分不合理 | 拆 step 或合并 step（同步改 narrations.ts） |
| "风格不统一" | 硬编码了颜色/字体 | 改为消费 var(--token) |
| "Token 消耗巨大" | Phase 1 前就开始大量 read/bash | 正常——Phase 1 是一次性投入，Phase 2.4 已优化为读 Cheatsheet(~100行)+MaterialGuide(~80行/章) |
| "CSS 每章重复太多" | 物理隔离导致排版模式重复 | 使用 base-typography.css 共享层（ty-hero/ty-sub/ty-body/ty-item 等 class） |
| "多轮修复同一问题" | 字号/层次无量化标准 | 现在 CHAPTER-CRAFT 有 5 级量化下限表 + 自检量化 |

---

*本文档随 Skill 约束文件更新而同步维护。*
