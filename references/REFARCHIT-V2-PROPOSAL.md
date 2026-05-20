# skill_v2.md

````md
---
name: web-video-presentation-v2

description:
将 article / script 制作成具有“视频感”的网页演示。

核心流程：
article/script
→ outline
→ checkpoint
→ chapter implementation
→ validation
→ optional audio
→ recording

核心目标：
- 保留电影感与视频节奏
- 避免 AI PPT 感
- 保持创造力
- 降低 Prompt 巨石问题
- 提高中等模型稳定性

核心原则：
- Step = 节拍
- 一屏一个主焦点
- 动画必须有语义
- 屏幕信息密度 > 口播
- token统一，章节表达自由
---

# SYSTEM OVERVIEW

本系统不是：
- 静态网页生成器
- PPT 生成器
- UI 页面生成器

本系统目标是：

```txt
用网页形式表达“视频叙事”
````

重点：

* 节奏
* 镜头感
* 信息递进
* 视觉叙事
* 动画语义

而不是：

* UI 堆砌
* 炫技动画
* 组件感

---

# CORE PRINCIPLES

## 1. Step = 节拍

一个 step 只表达一个核心想法。

避免：

* 一个 step 同时讲多个重点
* 长时间停留不变化
* 信息同时爆发

step 应该像：

* 镜头切换
* 节奏点
* 叙事推进

---

## 2. 每个 Step 只能有一个主视觉焦点

避免：

* 多区域竞争
* 同步 reveal
* 并列高亮
* 多动画同时抢注意力

用户注意力必须被明确引导。

---

## 3. 动画必须有语义

动画不是装饰。

动画必须表达：

* 对比
* 因果
* 遮挡
* 递进
* 强调
* 转变
* 冲击

避免：

* 无意义 fade
* 模板化 slide
* 机械 stagger
* 纯装饰 motion

---

## 4. 屏幕信息密度 > 口播

script：
决定节拍。

article：
决定视觉信息密度。

屏幕不能只是字幕。

屏幕必须：

* 补充信息
* 增加上下文
* 提供视觉叙事
* 提高信息密度

---

## 5. token统一，章节表达自由

主题负责统一：

* 气质
* 颜色语言
* 字体
* 动画基调

章节允许：

* 镜头差异
* 节奏变化
* 不同表现方式

不要追求完全机械统一。

---

# WORKFLOW

## Phase 1 — 内容理解

目标：
理解 article/script 的真正重点。

输出：

* narrative
* emotional beats
* visual opportunities
* chapter split

不要：

* 直接开始写页面
* 直接设计动画

---

## Phase 2 — Outline

outline 只定义：

* step
* 信息结构
* 叙事顺序
* 节奏

不要在 outline 写死：

* 动画实现
* 具体 motion
* 视觉细节

outline 是：

* 结构
* 节奏
* 信息骨架

不是：

* 动画脚本

---

## Checkpoint — Outline Approval

outline 必须经过确认后：
才能进入 chapter implementation。

禁止：

* 未确认直接生成全部章节

---

## Phase 2.4 — Chapter Implementation

每章实现时：
只读取：

1. CORE PRINCIPLES
2. 当前章节 outline
3. 当前 theme
4. chapter-memory.json
5. 当前素材

不要反复读取大型文档。

---

## Chapter 1 Rule

第1章必须：

* 主线程实现
* 人工验收
* 作为后续风格 anchor

后续章节：
允许并行。

---

# SINGLE SOURCE OF TRUTH

## narrations.ts

narrations.ts 是：

* step 数
* narration timing
* 音频同步

的唯一真相源。

所有章节：
必须与 narrations.ts 对齐。

禁止：

* 自行新增 step
* 自行修改 step 数
* narration 与页面脱节

---

# VISUAL LANGUAGE

## 避免 AI PPT 感

避免：

* 模板化 UI
* 装饰主导
* 多焦点竞争
* 无语义动画
* 机械 stagger
* 组件堆砌

避免：
“页面像组件库 Demo”。

---

## 视频感优先

页面应该更像：

* 镜头
* 剪辑
* 视觉叙事

而不是：

* dashboard
* admin panel
* landing page

---

# IMPLEMENTATION GUIDELINES

## 优先级

P0 — 不可违反

* narrations 对齐
* step 一致
* build 通过
* TypeScript 正确

P1 — 强约束

* 一屏一个主焦点
* 动画有语义
* step 有节拍

P2 — 风格建议

* 避免 AI 味
* 避免模板感
* 避免过度装饰

---

# VALIDATION

完成章节后：

运行：

```bash
npm run validate
```

自动检查：

* narrations step 对齐
* registry 对齐
* CSS prefix
* step 连续性
* TypeScript
* import/export

validation fail：
禁止进入下一阶段。

---

# CHAPTER MEMORY

每章结束：
自动生成：

```json
{
  "visualDensity": "high",
  "motionStyle": "cinematic",
  "usedPatterns": [
    "maskReveal",
    "timelineZoom"
  ],
  "avoidRepeat": [
    "sameHeroLayout"
  ]
}
```

用途：

* 降低长上下文依赖
* 避免重复镜头
* 保持风格连续性

---

# PARALLEL EXECUTION

允许：

* 后续章节并行
* subagent 实现

前提：

* Chapter 1 已验收
* theme 已确定
* narrations.ts 已稳定

---

# RECOVERY

如果任务中断：

恢复顺序：

1. 检查 narrations.ts
2. 检查 current outline
3. 检查 completed chapters
4. 检查 chapter-memory
5. 重新进入当前 phase

不要：

* 从头重新生成全部内容

---

# FILE STRUCTURE

```txt
SKILL.md
PRINCIPLES.md
VALIDATION.md
DESIGN_DECISIONS.md
FAILURES.md
EXAMPLES/
chapter-memory/
```

---

# DESIGN PHILOSOPHY

程序负责：

* 确定性
* 校验
* 一致性

模型负责：

* 创造力
* 镜头感
* 节奏
* 动画表达

不要：
试图用规则完全替代创意。

目标不是：
100% 可预测。

目标是：

```txt
高下限 + 高上限
```

即：

* 不容易生成 AI PPT
* 同时保留惊艳空间

```
```
