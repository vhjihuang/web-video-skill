# 列举型逐个揭示 章节 Anchor Card

**特征**：单网格 N 槽位，每 step 只填一个槽位，位置不重排，观众视线始终锁定新揭示项。

## 推荐 Primitive

| 视觉需求 | 推荐组件 | 说明 |
|---------|---------|------|
| ghost/active/dim 网格 | **`<SlotGrid>`** | 自动 stagger，activeIndices prop 强制 H5 |
| 全屏容器 | **`<ChapterShell>`** | 统一 padding + flex center |
| 章节提示文字 | **`<Kicker>`** | 48px 统一 kicker |

> **低层 Primitives（ChapterShell/Kicker）默认复用。高层 Primitive（SlotGrid）只能作为起点，必须做本章变体。** 如果本章 signatureMove 要求突破模板，可完全手写（需在 Draft Ledger 说明）。

## 结构骨架

| Step | 做什么 | 焦点 | SlotGrid 调用方式 |
|------|--------|------|-----------------|
| S0 | masthead 引子大字 + 序号 01/02/.../N ghost 占位 | 预告"有几件事" | `activeIndices={[]}` |
| S1 | "01"槽位填充：标题 + 简短说明 + accent 编号高亮 | 观众只看 01 | `activeIndices={[0]}` |
| S2 | "02"槽位填充；01 降级为次级灰化；其余仍 ghost | 观众视线移至 02 | `activeIndices={[1]} dimIndices={[0]}` |
| S3 | 后续槽位逐个填充，之前激活降级，之后保持 ghost | 递进揭示 | `activeIndices={[2]}` / 依此类推 |

## SlotGrid 数据结构

```ts
import type { SlotItem } from "../../components/patterns";

const ITEMS: SlotItem[] = [
  { num: "01", label: "行业术语", desc: <>别人说<span className="highlight-term">"跑通流水线"</span>你以为在说水管</> },
  { num: "02", label: "业务流程", desc: "数据从哪来到哪去完全没概念" },
  // ghost 态只需 num + label，不需要 desc
];
```

- `desc` 类型是 `ReactNode`，支持 JSX（用于高亮等富文本）
- ghost/dim 态的 desc 不渲染（节省 DOM）
- **自动 stagger**：activeIndices 中第 N 个元素自动获得 `N × 150ms` delay

## 字号关系
标题: ~64px / 巨号: ~144px serif / cue 标签: ~28px

## 动画基调
mask reveal 标题 + 数字砸下，稳而不跳，每个槽位只变一次。

## ⚠️ 最容易犯的错误
每点一次重新渲染整个布局——已揭示的项跟着抖动/重新入场，观众不知道该看哪。

## Signature Move 示例（list-reveal 类型）

> 每章开工前必须在 Draft Ledger 定义 `signatureMove`——高层 primitive 做不到的唯一记忆点。

| 章节 | signatureMove | 为什么 SlotGrid 做不到 |
|------|--------------|----------------------|
| Ch2 痛点展开 | 六个痛点像**诊断报告逐项被盖章**，不是卡片淡入 | 需要印章动画 + 盖章后变红/打钩的语义变化 |
| （假设）Ch3 方案对比 | 三个方案不是并列卡片，而是**天平两端逐渐倾斜** | 需要 CSS transform + 物理隐喻，SlotGrid 是纯网格 |
| （假设）Ch4 效率数据 | 10x 不是静态 badge，而是**数字从 1 开始滚动到 10** | 需要 JS 计数器动画，SlotGrid 无此能力 |

⚠️ 卡住？读 README.md
