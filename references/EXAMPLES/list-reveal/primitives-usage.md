# list-reveal · Pattern Primitives 使用示例

> 本文件展示如何用 `src/components/patterns/` 组件实现一个 **list-reveal** 类型章节。
> 对比原始手写版本（见同目录 `chapter.tsx` + `chapter.css`），Primitives 版本将 200+ 行压缩到 ~80 行。

## 完整示例（基于 Ch2 Problem 章节精简版）

### 文件结构

```
src/chapters/03-my-chapter/
  MyChapter.tsx    ← ~80 行（数据声明 + 组件组合）
  MyChapter.css    ← ~30 行（仅本章独特样式，不含 grid/flow/container）
```

### TSX

```tsx
import type { ChapterStepProps } from "../../registry/types";
import { ChapterShell, Kicker, SlotGrid, FlowStrip } from "../../components/patterns";
import type { SlotItem, FlowStep } from "../../components/patterns";
import "./MyChapter.css";

// ── 数据层：纯声明，无 JSX 嵌套 ──
const ITEMS: SlotItem[] = [
  { num: "01", label: "行业术语" },
  { num: "02", label: "业务流程" },
  { num: "03", label: "技术原理" },
  { num: "04", label: "应用场景" },
  { num: "05", label: "工具链" },
  { num: "06", label: "行业全貌" },
];

const ACTIVE_S1: SlotItem[] = [
  { num: "01", label: "行业术语", desc: <>别人说<span className="highlight-term">"跑通流水线"</span>你以为在说水管</> },
  { num: "02", label: "业务流程", desc: "数据从哪来到哪去完全没概念" },
  { num: "03", label: "技术原理", desc: "知道有AI但不懂怎么训练、怎么调参" },
];

const FLOW: FlowStep[] = [
  { title: "第一步", detail: "技术术语 A / B / C" },
  { title: "第二步", detail: "技术术语 D / E / F" },
];

export function MyChapter({ step }: ChapterStepProps) {
  if (step === 0) {
    return (
      <ChapterShell>
        <Kicker>标题文字</Kicker>
        <SlotGrid items={ITEMS} activeIndices={[]} columns={3} />
      </ChapterShell>
    );
  }

  if (step === 1) {
    return (
      <ChapterShell>
        <SlotGrid
          items={[...ACTIVE_S1, ...ITEMS.slice(3)]}
          activeIndices={[0, 1, 2]}
          columns={3}
        />
      </ChapterShell>
    );
  }

  if (step === 2) {
    return (
      <ChapterShell>
        <SlotGrid
          items={[...ITEMS.slice(0, 3), ...ACTIVE_S2]}
          activeIndices={[3, 4, 5]}
          dimIndices={[0, 1, 2]}
          columns={3}
        />
      </ChapterShell>
    );
  }

  return (
    <ChapterShell>
      <Kicker>案例标题</Kicker>
      <div className="mc-example card">
        <FlowStrip steps={FLOW} />
      </div>
    </ChapterShell>
  );
}
```

### CSS（仅残留样式）

```css
/* MyChapter.css — 仅包含 Primitives 未覆盖的章节独特样式 */

.mc-example {
  padding: 56px 48px;
  width: 100%;
  max-width: 1200px;
  opacity: 0;
  animation: mc-exampleIn 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

@keyframes mc-exampleIn {
  from { opacity: 0; transform: translateY(30px); }
  to   { opacity: 1; transform: translateY(0); }
}

.highlight-term {
  color: var(--accent);
  font-weight: bold;
}
```

## 关键设计决策

| 决策 | 为什么 |
|------|--------|
| 数据声明在组件外 | 纯数据不混 JSX，Agent 读起来更快 |
| `desc` 用 `ReactNode` | 支持高亮标签等富文本 |
| `activeIndices` 显式传数组 | 强制 H5——Agent 必须思考每步激活哪些 slot |
| stagger 不需要手写 | SlotGrid 自动按 activeIndices 位置序号 × 150ms 生成 delay |
| CSS 只剩 ~30 行 | container/kicker/grid/flow 全部由 patterns.css 覆盖 |

## 与原始手写版对比

| 维度 | 手写版（chapter.tsx + chapter.css） | Primitives 版 |
|------|-------------------------------------|--------------|
| TSX 行数 | ~160 行 | ~80 行 (-50%) |
| CSS 行数 | ~180 行 | ~30 行 (-83%) |
| H5 强制执行 | 靠 Agent 自觉（容易忘） | `activeIndices` prop 物理强制 |
| Stagger 实现 | 手写 nth-child 规则 (~10 行) | 自动生成（0 行） |
| 复用性 | 零（每章重写） | 高（组件跨章共享） |
