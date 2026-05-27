# Agent 故障排查 Runbook

> 卡住了？按以下顺序排查。不要硬做到底。

---

## 场景 1：validate.sh 红了

1. 读 `VALIDATION.md` 对应检测项说明
2. 按说明修复
3. 重跑 `npm run validate`
4. Pass 后才能进下一章

---

## 场景 2：用户说"不好看"但不知道怎么改

**先自查 [AI-GEN] 5 项反模式：**
- 紫粉渐变背景？
- 圆角彩色边框？
- emoji 图标？（📖🔧💡 等）
- 假数据/假logo？
- 杂乱装饰动效（infinite glow/ken burns）？

**如果都不是 → 主动问用户：**
- 是节奏问题？（某步太快/太慢？）
- 是信息密度问题？（某步东西太多/太少？）
- 是颜色搭配问题？
- 是素材问题？

---

## 场景 3：连续改了 3 轮还不通过

1. **检查主题匹配**：当前 theme 的 `bestFor` 是否命中 `script.md` 内容类型？
2. 如果不匹配 → 推荐换主题（给出 2 个候选，列 `bestFor` + `descriptionZh`）
3. 如果匹配 → **回退 Checkpoint Plan**：
   - 重新阅读 outline + script.md
   - 检查章节切分是否合理
   - 检查素材是否充足
   - 重新与用户对齐 5 件事

---

## 场景 4：这一章能"偷懒"吗？

1. **检查 Step Focus Ledger**：任何 Step foregroundUnits > 5 即危险，立即 ⚠️ 标注
2. **双源验证**：屏幕每项信息口播没念？（至少 1 项，至多 3 项）→ 不满足则调整
3. **删掉测试**：删掉任一元素后理解不受损？→ 该删

---

## Step Focus Ledger 格式要求

### Draft（开工前，对话中输出）
```
Draft Step Focus Ledger:
  S0: [ROLE-TAG]   焦点=____  预期密度=轻(2~3元素)
  S1: [ROLE-TAG]   焦点=____  预期密度=中(3~5元素)
  ...

ROLE-TAG: EMOTION-HOOK | CONTRAST-REVEAL | STAMP-OST | TAKEOVER | TEASER | LIST-REVEAL | SINGLE-PROOF | PROCESS-MAP | CUSTOM
密度：轻 ≤3 / 中 3~5 / 重 >5（重 = ⚠️ 必须确认是否拆步）
```

### Final（完工后，对话中输出）
```
Final Step Focus Ledger:
  S0→轻(2) ✅ | S1→中(4) ✅ | S2→⚠️重(6) 超预期 | ...
  过载步=N/M(N%)  [原因说明]
```

Draft→Final 对比是 Agent 自我校准的证据。Final 与 Draft 严重偏离需解释原因。