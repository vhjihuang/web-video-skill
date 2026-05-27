# Validation 使用指南

> **何时读**：`npm run validate` 报错时、或想了解每项检测的含义时。

## 快速开始

```bash
# 在项目根目录运行
npm run validate
```

或直接：

```bash
bash scripts/validate.sh
```

## 检测项详解

| ID | 检测内容 | 对应 Failure | 严重度 | 修复方式 |
|----|---------|-------------|--------|---------|
| **C1** | narrations 一致性 | #16 | 🔴 致命 | 检查 `.tsx` 中 `step === N` 的最大 N+1 是否等于 `narrations.length` |
| **C2** | TypeScript 编译 | #26, #27 | 🔴 致命 | 运行 `npx tsc --noEmit` 修复所有类型错误 |
| **C4** | 字号下限 | #12 | 🟡 警告 | 对照下限表调整：hero≥80px, h1≥56px, body≥32px, cue≥18px |
| **C6** | 动画时长 ≤ 口播时长 | **#20** | 🔴 致命 | 缩短动画时长或拆分 step；Auto 模式下超时=录屏崩溃<br>**→ 对应 Rule-ID: [NO-TIMER]** |
| **C7** | CSS Prefix 隔离 | #18 | 🔴 致命 | 确保每章使用独立前缀（`.cd-` / `.mg-` / `.pm-` 等）<br>**→ 对应 Rule-ID: [CSS-PREFIX]** |

## 退出码

| 码 | 含义 | Agent 应该 |
|---|------|----------|
| 0 | 全部通过（可能有 WARN） | 可以进入下一阶段 |
| 0 + WARN | 通过但有警告 | 建议修复后继续 |
| 1 | 有 FAIL | **必须修复后重新运行**，禁止进入下一阶段 |

## C6 动画时长检测详解

这是 **FAILURE_ANALYSIS #20（致命级）** 的程序化防护。

### 问题现象

Auto 模式（`?auto=1`）下，音频播放完毕自动推进到下一步。如果某步的动画总时长 > 该步口播时长：
- 音频结束 → 自动切走 → 但画面还在播动画 → 观众看到闪烁/跳跃
- 录屏者崩溃："动画没播完就切走了！！"

### 检测逻辑

```
1. 解析章节所有 CSS 的 animation-duration / @keyframes 隐式时长
   取最大值作为该章"最长动画时长"

2. 统计 narrations.ts 的字符数 ÷ 4 ≈ 口播秒数
   （中文平均 4 字/秒，含停顿）

3. 对比：
   最长动画 > 口播 × 1.5 → ❌ FAIL
   最长动画 > 口播 × 1.0 → ⚠️ WARN
   最长动画 ≤ 口播       → ✅ OK
```

### 局限性（已知）

- ✅ 能覆盖：CSS `animation-duration` / `@keyframes` / `transition-duration`
- ❌ 不能覆盖：JS 驱动的动画（GSAP / Framer Motion / requestAnimationFrame）
- ❌ 不能覆盖：SVG `<animate>` 内联标签
- ❌ 不能覆盖：动态计算时长（依赖数据量/窗口尺寸的动画）

对于不覆盖的场景，**人工验收时重点检查 Auto 模式下的完整播放**。

### 修复建议

```css
/* ❌ 太长 */
.hero-number {
  animation: countUp 3s ease-out;
}

/* ✅ 缩短到口播时间内 */
.hero-number {
  animation: countUp 1.2s ease-out;
}
```

或者将该步拆分为两个 step：
- Step 3: 数字出现 + 开始递增（~1s）
- Step 4: 数字稳定 + 口播解释含义

## 集成到 workflow

在 `package.json` 中添加：

```json
{
  "scripts": {
    "validate": "bash scripts/validate.sh",
    "validate:strict": "bash scripts/validate.sh && echo '✅ Strict validation passed'"
  }
}
```

推荐在以下节点强制运行：

1. **每章完成后**（Phase 2.4 → 2.5 之间）
2. **Checkpoint Audio 前**（Phase 2 结束时全量跑一次）
3. **最终交付前**（Phase 4 录屏前）

---

*最后更新：2026-05-21（refactor 分支）*
