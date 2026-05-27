#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# validate-outline.sh —— 自动化校验 outline.md 格式与质量。
#
# 用法：
#   bash scripts/validate-outline.sh <outline.md>
#
# 检查项：
#   1. 文件存在且非空
#   2. 顶部 metadata block 完整（主题 / 总时长 / 章节数）
#   3. 每章信息池 ≥ 3 条，每条带来源标注
#   4. 每章 step 数在 3~8 范围
#   5. step (~Ts) 累加 ≈ 声明总时长（误差 < 15%）
#   6. 无动画类型 / CSS 手段等非法字段
#   7. 画面感：每步描述包含 ≥ 2 个视觉维度关键词
#   8. 信息池 ≥ 50% 条目被分配到具体 step
#   9. 连续 step 视觉多样性 + 素材来源有效性
#
# 退出码：
#   0 = 全部通过
#   1 = 有 FAIL 项（详情见输出）
# ─────────────────────────────────────────────────────────────
set -euo pipefail

OUTLINE="${1:-outline.md}"
PASS=0
FAIL=0
WARN=0

red=$'\033[0;31m'
green=$'\033[0;32m'
yellow=$'\033[0;33m'
bold=$'\033[1m'
reset=$'\033[0m'

log_pass() { echo "  ${green}✓${reset} $1"; ((PASS++)); }
log_fail() { echo "  ${red}✗${reset} $1"; ((FAIL++)); }
log_warn() { echo "  ${yellow}⚠${reset} $1"; ((WARN++)); }

echo "${bold}━━━ outline.md 校验：${OUTLINE} ━━━${reset}"
echo

if [[ ! -f "$OUTLINE" ]]; then
  log_fail "文件不存在: ${OUTLINE}"
  exit 1
fi

FILE_SIZE=$(wc -c < "$OUTLINE")
if [[ "$FILE_SIZE" -eq 0 ]]; then
  log_fail "文件为空"
  exit 1
fi
log_pass "文件存在 (${FILE_SIZE} bytes)"

# ── 1. metadata block ──
echo ""
echo "${bold}[1/9] 顶部 metadata block${reset}"

if grep -q '^>' "$OUTLINE" && grep -q '主题' "$OUTLINE"; then
  log_pass "metadata block 存在"
else
  log_fail "缺少 metadata block（需要 > 引用块声明 主题 / 总时长 / 章节数）"
fi

# 提取声明的总时长（从 metadata 中）
DECLARED_TOTAL=$(grep -oP '约 \K[\d.]+(?= 分)' "$OUTLINE" | head -n1 || true)
if [[ -n "$DECLARED_TOTAL" ]]; then
  log_pass "声明总时长: ~${DECLARED_TOTAL} 分钟"
else
  log_warn "未找到声明的总时长（格式：约 X 分 Y 秒）"
fi

# ── 2. 章节结构 ──
echo ""
echo "${bold}[2/9] 章节结构与信息池${reset}"

CHAPTER_COUNT=$(grep -cE '^## \d+\.' "$OUTLINE" || true)
if [[ "$CHAPTER_COUNT" -ge 1 ]]; then
  log_pass "检测到 ${CHAPTER_COUNT} 章"
else
  log_fail "未检测到任何章节（格式：## N. <id> — <title>）"
fi

INFO_POOL_PASS=0
INFO_POOL_TOTAL=0
while IFS= read -r line; do
  CHAPTER_NUM=$(echo "$line" | grep -oP '\d+')
  POOL_ITEMS=$(sed -n "/^## ${CHAPTER_NUM}\./,/^## /p" "$OUTLINE" | grep -cE '^- .*——.*来源' || true)
  POOL_NO_SOURCE=$(sed -n "/^## ${CHAPTER_NUM}\./,/^## /p" "$OUTLINE" | grep -cE '^-(?!.*——)' || true)
  INFO_POOL_TOTAL=$((INFO_POOL_TOTAL + POOL_ITEMS + POOL_NO_SOURCE))

  if [[ "$POOL_ITEMS" -ge 3 ]]; then
    log_pass "第 ${CHAPTER_NUM} 章：信息池 ${POOL_ITEMS} 条（≥ 3 ✓）"
    ((INFO_POOL_PASS++))
  elif [[ "$POOL_ITEMS" -ge 1 ]]; then
    log_fail "第 ${CHAPTER_NUM} 章：信息池仅 ${POOL_ITEMS} 条（需 ≥ 3）"
  else
    log_fail "第 ${CHAPTER_NUM} 章：未检测到信息池或条目不足"
  fi

  if [[ "$POOL_NO_SOURCE" -gt 0 ]]; then
    log_warn "第 ${CHAPTER_NUM} 章：有 ${POOL_NO_SOURCE} 条信息池条目缺来源标注（需含 —— 来源 article ...）"
  fi
done < <(grep -nE '^## \d+\.' "$OUTLINE")

# ── 3. step 数范围 ──
echo ""
echo "${bold}[3/9] step 数范围（每章 3~8 步）${reset}"

STEP_RANGE_PASS=0
while IFS= read -r line; do
  CHAPTER_NUM=$(echo "$line" | grep -oP '\d+')
  STEP_COUNT=$(sed -n "/^## ${CHAPTER_NUM}\./,/^## /p" "$OUTLINE" | grep -cE '^-\s*step \d+' || true)

  if [[ "$STEP_COUNT" -eq 0 ]]; then
    log_warn "第 ${CHAPTER_NUM} 章：未检测到 step（可能用了其他格式）"
  elif [[ "$STEP_COUNT" -ge 3 && "$STEP_COUNT" -le 8 ]]; then
    log_pass "第 ${CHAPTER_NUM} 章：${STEP_COUNT} 步（3~8 ✓）"
    ((STEP_RANGE_PASS++))
  else
    log_fail "第 ${CHAPTER_NUM} 章：${STEP_COUNT} 步（超出 3~8 范围，建议拆分或合并章节）"
  fi
done < <(grep -nE '^## \d+\.' "$OUTLINE")

# ── 4. 时长累加 vs 声明总时长 ──
echo ""
echo "${bold}[4/9] step 估时累加 vs 声明总时长${reset}"

TOTAL_SECS=0
STEP_COUNT_TOTAL=0
while IFS= read -r match; do
  SEC=$(echo "$match" | grep -oP '\(\K[\d.]+(?=s\))' || true)
  if [[ -n "$SEC" ]]; then
    TOTAL_SECS=$(echo "$TOTAL_SECS + $SEC" | bc)
    ((STEP_COUNT_TOTAL++))
  fi
done < <(grep -oP '\(~\K[\d.]+(?=s\))' "$OUTLINE")

if [[ "$STEP_COUNT_TOTAL" -gt 0 && -n "$DECLARED_TOTAL" ]]; then
  DECLARED_SECS=$(echo "$DECLARED_TOTAL * 60" | bc)
  RATIO=$(echo "scale=2; $TOTAL_SECS / $DECLARED_SECS * 100" | bc)
  DIFF=$(echo "$RATIO - 100" | bc)
  ABS_DIFF=${DIFF#-}

  if (( $(echo "$ABS_DIFF < 15" | bc -l) )); then
    log_pass "估时累加: ${TOTAL_SECS}s ≈ 声明 ${DECLARED_SECS}s（偏差 ${DIFF}% ✓）"
  else
    log_fail "估时累加: ${TOTAL_SECS}s vs 声明 ${DECLARED_SECS}s（偏差 ${DIFF}%，需 < 15%）"
  fi
elif [[ "$STEP_COUNT_TOTAL" -gt 0 ]]; then
  log_pass "估时累加: 总计 ~$(( TOTAL_SECS / 60 ))分$(( TOTAL_SECS % 60 ))秒（${STEP_COUNT_TOTAL} 步）"
  log_warn "无法对比总时长（metadata 中未找到声明值）"
else
  log_warn "未检测到任何 step 估时（格式：step N (~Ts)）"
fi

# ── 5. 非法字段检查 ──
echo ""
echo "${bold}[5/9] 非法字段（不应出现动画类型 / CSS 手段 / 具体毫秒数）${reset}"

ILLEGAL_PATTERNS=(
  "blur clear"
  "fade in\|fadeIn"
  "slide up\|slideUp"
  "wipe"
  "弹簧\|spring"
  "ken burns\|Ken Burns"
  "filter:"
  "clip-path\|clipPath"
  "animation:\|@keyframes"
  "ms$\|ms )"
  "transition:"
)

ILLEGAL_FOUND=0
for pattern in "${ILLEGAL_PATTERNS[@]}"; do
  COUNT=$(grep -ci "$pattern" "$OUTLINE" 2>/dev/null || true)
  if [[ "$COUNT" -gt 0 ]]; then
    log_fail "发现非法字段 '${pattern}'（${COUNT} 处）— outline 不应写动画/CSS手段"
    ((ILLEGAL_FOUND++))
  fi
done
[[ "$ILLEGAL_FOUND" -eq 0 ]] && log_pass "无非法动画/CSS手段字段"

# ── 6. 画面感检查 ──
echo ""
echo "${bold}[6/9] 画面感（每步应包含 ≥ 2 个视觉维度关键词）${reset}"

FOCUS_WORDS="中央|右上角|左下角|底部|全屏|上方|下方|左侧|右侧|居中|焦点"
LAYER_WORDS="kicker|上下文|层次|主.*副|保留|缩小|放大|灰化|背景|前景|叠加"
ACTION_WORDS="亮起|浮现|弹入|划掉|揭示|切入|淡入|推进|展开|收起|聚拢|散开|旋转|翻转|流动|点亮"

VISUAL_PASS=0
VISUAL_TOTAL=0
WEAK_STEPS=()

while IFS= read -r line; do
  STEP_DESC=$(echo "$line" | sed -E 's/^- *step [0-9]+ \(~[0-9.]+s\) — //' )
  [[ -z "$STEP_DESC" ]] && continue

  ((VISUAL_TOTAL++))

  FOCUS_MATCH=$(echo "$STEP_DESC" | grep -cio "$FOCUS_WORDS" || true)
  LAYER_MATCH=$(echo "$STEP_DESC" | grep -cio "$LAYER_WORDS" || true)
  ACTION_MATCH=$(echo "$STEP_DESC" | grep -cio "$ACTION_WORDS" || true)
  TOTAL_DIM=$((FOCUS_MATCH + LAYER_MATCH + ACTION_MATCH))

  STEP_LABEL=$(echo "$line" | grep -oP 'step \K\d+')

  if [[ "$TOTAL_DIM" -ge 2 ]]; then
    ((VISUAL_PASS++))
  else
    WEAK_STEPS+=("step ${STEP_LABEL}: 「${STEP_DESC:0:60}...」(${TOTAL_DIM} 维)")
  fi
done < <(grep -E '^-\s*step \d+' "$OUTLINE")

if [[ "$VISUAL_TOTAL" -gt 0 ]]; then
  PCT=$(( VISUAL_PASS * 100 / VISUAL_TOTAL ))
  if [[ "$PCT" -ge 80 ]]; then
    log_pass "画面感: ${VISUAL_PASS}/${VISUAL_TOTAL} 步达标（≥ 2 视觉维度，${PCT}% ✓）"
  else
    log_fail "画面感: 仅 ${VISUAL_PASS}/${VISUAL_TOTAL} 步达标（${PCT}%，目标 ≥ 80%）"
    for weak in "${WEAK_STEPS[@]:0:5}"; do
      log_warn "  → $weak"
    done
    [[ "${#WEAK_STEPS[@]}" -gt 5 ]] && log_warn "  → ... 还有 $(( ${#WEAK_STEPS[@]} - 5 )) 步"
  fi
else
  log_warn "未检测到 step 行，跳过画面感检查"
fi

# ── 7. 信息池利用率 ──
echo ""
echo "${bold}[7/9] 信息池利用率（≥ 50% 条目应被分配到具体 step）${reset}"

if [[ "$INFO_POOL_TOTAL" -gt 0 ]]; then
  ASSIGNED=0
  while IFS= read -r item; do
    KEYWORD=$(echo "$item" | sed -E 's/^- .*?：(.*)——.*/\1/' | head -c 20)
    if grep -q "$KEYWORD" "$OUTLINE"; then
      ((ASSIGNED++))
    fi
  done < <(grep -E '^- .*——.*来源' "$OUTLINE")

  UTIL_PCT=$(( ASSIGNED * 100 / INFO_POOL_TOTAL ))
  if [[ "$UTIL_PCT" -ge 50 ]]; then
    log_pass "信息池利用: ${ASSIGNED}/${INFO_POOL_TOTAL} 条被引用（${UTIL_PCT}% ≥ 50% ✓）"
  else
    log_fail "信息池利用: 仅 ${ASSIGNED}/${INFO_POOL_TOTAL} 条被引用（${UTIL_PCT}%，目标 ≥ 50%）"
  fi
else
  log_warn "信息池为空，跳过利用率检查"
fi

# ── 8. 连续视觉变化 ──
echo ""
echo "${bold}[8/9] 连续 step 视觉多样性${reset}"

MONOTONE=0
PREV_KEYWORD=""
CONSECUTIVE=0
while IFS= read -r line; do
  STEP_DESC=$(echo "$line" | sed -E 's/^- *step [0-9]+ \(~[0-9.]+s\) — //')
  CURRENT=$(echo "$STEP_DESC" | grep -oiE '^(列出|介绍|展示|说明|显示|呈现|讲述|讨论)' || true)

  if [[ -n "$CURRENT" && "$CURRENT" == "$PREV_KEYWORD" ]]; then
    ((CONSECUTIVE++))
    if [[ "$CONSECUTIVE" -ge 2 ]]; then
      ((MONOTONE++))
    fi
  else
    CONSECUTIVE=0
  fi
  PREV_KEYWORD="$CURRENT"
done < <(grep -E '^-\s*step \d+' "$OUTLINE")

if [[ "$MONOTONE" -eq 0 ]]; then
  log_pass "无连续单调 step（每步主导元素有变化 ✓）"
else
  log_warn "检测到 ${MONOTONE} 处连续使用相同开头的 step（建议变换视觉焦点）"
fi

# ── 9. 素材来源校验（MATERIAL-INDEX 对齐）── ─
echo ""
echo "${bold}[9/9] 素材来源有效性（信息池引用的 article 区域应在可用范围内）${reset}"

# 动态读取 MATERIAL-INDEX.md 标记的 SKIP 区域
INDEX_FILE="MATERIAL-INDEX.md"
SKIP_SECTIONS=""

if [[ -f "$INDEX_FILE" ]]; then
  SKIP_RAW=$(grep -oP '\[SKIP\][^§]*§\K[0-9.]+' "$INDEX_FILE" | tr '\n' '|' | sed 's/|$//')
  if [[ -n "$SKIP_RAW" ]]; then
    SKIP_SECTIONS=$(echo "$SKIP_RAW" | sed 's/\./\\./g')
  fi
else
  log_warn "未在项目根目录找到 MATERIAL-INDEX.md，跳过 SKIP 区域严格校验"
fi

BAD_SOURCE=0
TOTAL_SOURCED=0
while IFS= read -r item; do
  SOURCE_REF=$(echo "$item" | grep -oP '来源\s+article\s+§?\K[^)]+' || true)
  [[ -z "$SOURCE_REF" ]] && continue

  ((TOTAL_SOURCED++))

  if [[ -n "$SKIP_SECTIONS" ]] && echo "$SOURCE_REF" | grep -qiE "$SKIP_SECTIONS"; then
    log_fail "信息池条目引用了 SKIP 区域: 「${SOURCE_REF}」"
    ((BAD_SOURCE++))
  else
    log_pass "素材来源有效: ${SOURCE_REF}"
  fi
done < <(grep -E '^- .*——.*来源' "$OUTLINE")

if [[ "$TOTAL_SOURCED" -eq 0 ]]; then
  log_warn "未检测到任何带「来源」标注的信息池条目"
  log_warn "建议按 MATERIAL-INDEX.md 格式标注：`—— 来源 article §X LYY-ZZ`"
elif [[ "$BAD_SOURCE" -eq 0 ]]; then
  log_pass "所有素材来源均在可用区域内（共 ${TOTAL_SOURCED} 条）✓"
else
  log_fail "${BAD_SOURCE}/${TOTAL_SOURCED} 条信息池引用了非素材区域"
  log_fail "请参考 MATERIAL-INDEX.md 的 [SKIP] 区域列表，改用可用区域的素材"
fi

# ── 汇总 ──
echo ""
echo "${bold}━━━ 校验结果汇总 ━━━${reset}"
echo ""
echo "  ${green}✓ PASS${reset} : ${PASS}"
echo "  ${red}✗ FAIL${reset} : ${FAIL}"
echo "  ${yellow}⚠ WARN${reset} : ${WARN}"
echo ""

if [[ "$FAIL" -eq 0 ]]; then
  echo "${green}🎉 全部通过！outline 可以进入 Checkpoint Plan。${reset}"
  exit 0
else
  echo "${red}❌ 有 ${FAIL} 项 FAIL。请按上述提示修改 outline 后重新运行。${reset}"
  exit 1
fi
