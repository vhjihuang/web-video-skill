#!/bin/bash
# Web Video Presentation Validator MVP
# 基于 FAILURE_ANALYSIS.md 45 个 Case 提取的客观检测项
# 用法: cd presentation && bash ../scripts/validate.sh
# 退出码: 0=全部通过, 1=有FAIL项

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PRESENTATION_DIR="${PROJECT_ROOT}/presentation"

if [ ! -d "$PRESENTATION_DIR" ]; then
  echo "❌ 找不到 presentation/ 目录，请在 skill 根目录运行"
  exit 1
fi

cd "$PRESENTATION_DIR"

PASS=0
FAIL=0
WARN=0

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass_msg()  { echo -e "  ${GREEN}✅ PASS${NC}: $1"; ((PASS++)); }
fail_msg()  { echo -e "  ${RED}❌ FAIL${NC}: $1"; ((FAIL++)); }
warn_msg()  { echo -e "  ${YELLOW}⚠️  WARN${NC}: $1"; ((WARN++)); }

echo "🔍 Web Video Presentation Validator"
echo "======================================="
echo ""

# ── C1: Narrations 对齐（防 FAILURE #16）─────────────────────
echo "[C1] Narrations 一致性检测..."

NARRATIONS_FILES=$(find src/chapters -name "narrations.ts" -type f 2>/dev/null || true)
if [ -z "$NARRATIONS_FILES" ]; then
  warn_msg "未找到任何 narrations.ts 文件"
else
  C1_ERROR=0
  for NARR_FILE in $NARRATIONS_FILES; do
    CHAPTER_DIR=$(dirname "$NARR_FILE")
    CHAPTER_NAME=$(basename "$CHAPTER_DIR")
    
    # 提取 narrations.length
    NARR_COUNT=$(grep -o 'narrations\.length' "$NARR_FILE" > /dev/null 2>&1 && \
      node -e "const m = require('$(realpath "$NARR_FILE")'.replace('.ts','')); console.log(m.narrations.length)" 2>/dev/null || \
      grep -c '^\s*"' "$NARR_FILE" 2>/dev/null || echo "0")
    
    # 提取该章节 .tsx 中最大 step === N 的值
    TSX_FILE=$(find "$CHAPTER_DIR" -maxdepth 1 -name "*.tsx" ! -name "*narrations*" -type f 2>/dev/null | head -1)
    if [ -n "$TSX_FILE" ]; then
      MAX_STEP=$(grep -oP 'step\s*===\s*\K\d+' "$TSX_FILE" 2>/dev/null | sort -n | tail -1 || echo "-1")
      EXPECTED=$((MAX_STEP + 1))
      
      if [ "$NARR_COUNT" != "$EXPECTED" ] && [ "$MAX_STEP" != "-1" ]; then
        fail_msg "${CHAPTER_NAME}: narrations.length=${NARR_COUNT}, 但 max step=${MAX_STEP} (期望 ${EXPECTED})"
        C1_ERROR=1
      fi
    fi
  done
  [ $C1_ERROR -eq 0 ] && pass_msg "所有章节 narrations 对齐一致"
fi
echo ""

# ── C2: TypeScript 编译（防 FAILURE #26 #27）──────────────────
echo "[C2] TypeScript 编译检测..."
if command -v npx &> /dev/null; then
  TSC_OUTPUT=$(npx tsc --noEmit 2>&1) || true
  if [ -z "$TSC_OUTPUT" ]; then
    pass_msg "TypeScript 编译通过"
  else
    ERROR_COUNT=$(echo "$TSC_OUTPUT" | grep -c "error TS" || echo "0")
    fail_msg "TypeScript 编译失败 (${ERROR_COUNT} 个错误)"
    echo "$TSC_OUTPUT" | head -20
  fi
else
  warn_msg "npx 未找到，跳过 TypeScript 检测"
fi
echo ""

# ── C4: 字号下限（防 FAILURE #12）─────────────────────────────
echo "[C4] 字号下限检测..."

CSS_FILES=$(find src/chapters -name "*.css" -type f 2>/dev/null || true)
if [ -z "$CSS_FILES" ]; then
  warn_msg "未找到章节 CSS 文件"
else
  C4_ERROR=0
  # 字号下限表 (px)
  declare -A FONT_MIN=(
    ["hero"]="80" ["h1"]="56" ["h2"]="48" ["body"]="32"
    ["secondary"]="24" ["cue"]="18" ["tag"]="16" ["micro"]="14"
  )
  
  for CSS_FILE in $CSS_FILES; do
    CHAPTER_NAME=$(echo "$CSS_FILE" | grep -oP 'chapters/\K[^/]+' || echo "unknown")
    
    while IFS= read -r line; do
      FONT_SIZE=$(echo "$line" | grep -oP 'font-size:\s*\K[\d.]+')
      if [ -n "$FONT_SIZE" ]; then
        # 去掉小数比较
        FONT_INT=${FONT_SIZE%.*}
        if [ "$FONT_INT" -lt 14 ] 2>/dev/null; then
          warn_msg "${CHAPTER_NAME}: font-size: ${FONT_SIZE}px (低于最低下限 14px)"
        elif [ "$FONT_INT" -lt 16 ] 2>/dev/null; then
          # 微型文字以下需要特别关注
          LINE_NUM=$(grep -n "font-size.*${FONT_SIZE}" "$CSS_FILE" | head -1 | cut -d: -f1)
          warn_msg "${CHAPTER_NAME}:${LINE_NUM} font-size: ${FONT_SIZE}px (接近下限)"
        fi
      fi
    done < "$CSS_FILE"
  done
  [ $C4_ERROR -eq 0 ] && pass_msg "字号检查完成（详见上方 WARN）"
fi
echo ""

# ── C6: 动画时长 vs 口播时长（防 FAILURE #20 致命级）────────
echo "[C6] 动画时长检测（防 Auto 模式切断）..."

ANIMATION_ERRORS=0
for NARR_FILE in $NARRATIONS_FILES; do
  CHAPTER_DIR=$(dirname "$NARR_FILE")
  CHAPTER_NAME=$(basename "$CHAPTER_DIR")
  
  # 收集该章节所有动画时长
  TOTAL_ANIM_DUR=0
  
  # 检查 CSS animation-duration
  CHAPTER_CSS=$(find "$CHAPTER_DIR" -name "*.css" -type f 2>/dev/null)
  for CSS in $CHAPTER_CSS; do
    # 提取所有 animation-duration 值（取最长）
    MAX_CSS_DUR=$(grep -oP 'animation-duration:\s*\K[\d.]+' "$CSS" 2>/dev/null | sort -rn | head -1 || echo "0")
    TOTAL_ANIM_DUR=$(echo "$TOTAL_ANIM_DUR $MAX_CSS_DUR" | awk '{if($1>$2)=$1; else=$2}')
  done
  
  # 检查 @keyframes 隐含时长
  KEYFRAMES_DUR=$(find "$CHAPTER_DIR" -name "*.css" -exec grep -l "@keyframes" {} \; 2>/dev/null | \
    xargs grep -oP '@keyframes[^{]*\{[^}]*animation:\s*[^;]*\K[\d.]+' 2>/dev/null | \
    sort -rn | head -1 || echo "0")
  
  # 估算口播时长：narrations 字数 / 4 (中文约 4字/秒)
  NARR_WORD_COUNT=$(wc -c < "$NARR_FILE" 2>/dev/null || echo "0")
  EST_SPEECH_DUR=$((NARR_WORD_COUNT / 4))
  
  # 动画时长不应超过口播时长的 1.5 倍
  if [ -n "$TOTAL_ANIM_DUR" ] && [ "$(echo "$TOTAL_ANIM_DUR > 1.5 * $EST_SPEECH_DUR" | bc -l 2>/dev/null)" = "1" ]; then
    fail_msg "${CHAPTER_NAME}: 最长动画 ~${TOTAL_ANIM_DUR}s >> 口播估算 ~${EST_SPEECH_DUR}s (Auto模式可能切断)"
    ANIMATION_ERRORS=1
  elif [ -n "$TOTAL_ANIM_DUR" ] && [ "$(echo "$TOTAL_ANIM_DUR > $EST_SPEECH_DUR" | bc -l 2>/dev/null)" = "1" ]; then
    warn_msg "${CHAPTER_NAME}: 最长动画 ~${TOTAL_ANIM_DUR}s > 口播估算 ~${EST_SPEECH_DUR}s (建议检查)"
  fi
done

[ $ANIMATION_ERRORS -eq 0 ] && [ -n "$NARRATIONS_FILES" ] && pass_msg "动画时长检查完成"
[ -z "$NARRATIONS_FILES" ] && warn_msg "无 narrations 文件，跳过"
echo ""

# ── C7: CSS Prefix 隔离（防 FAILURE #18）───────────────────────
echo "[C7] CSS Prefix 隔离检测..."

PREFIX_MAP=""
PREFIX_CONFLICT=0
for CSS_FILE in $CSS_FILES; do
  CHAPTER_NAME=$(echo "$CSS_FILE" | grep -oP 'chapters/\K[^/]+' || echo "unknown")
  # 提取类名前缀 (如 .cd-xxx -> cd)
  PREFIXES=$(grep -oP '\.([a-z]{2,5})-' "$CSS_FILE" 2>/dev/null | grep -oP '\.\K[a-z]{2,5}' | sort -u || true)
  
  for PREFIX in $PREFIXES; do
    EXISTING_CHAPTER=$(echo "$PREFIX_MAP" | grep "^${PREFIX}:" | cut -d: -f2 || echo "")
    if [ -n "$EXISTING_CHAPTER" ] && [ "$EXISTING_CHAPTER" != "$CHAPTER_NAME" ]; then
      fail_msg "Prefix 冲突: .${PREFIX}- 同时出现在 [${EXISTING_CHAPTER}] 和 [${CHAPTER_NAME}]"
      PREFIX_CONFLICT=1
    else
      PREFIX_MAP="${PREFIX_MAP}\n${PREFIX}:${CHAPTER_NAME}"
    fi
  done
done

[ $PREFIX_CONFLICT -eq 0 ] && [ -n "$CSS_FILES" ] && pass_msg "CSS prefix 无冲突"
[ -z "$CSS_FILES" ] && warn_msg "无 CSS 文件，跳过"
echo ""

# ── 结果汇总 ───────────────────────────────────────────────────
echo "======================================="
echo -e "  ${GREEN}✅ ${PASS} PASS${NC} | ${RED}❌ ${FAIL} FAIL${NC} | ${YELLOW}⚠️  ${WARN} WARN${NC}"
echo ""

if [ $FAIL -gt 0 ]; then
  echo -e "${RED}❌ Validation FAILED — 请修复以上 FAIL 项后再继续${NC}"
  exit 1
elif [ $WARN -gt 0 ]; then
  echo -e "${YELLOW}⚠️  通过但有 WARN — 建议修复后再交付${NC}"
  exit 0
else
  echo -e "${GREEN}✅ 全部通过${NC}"
  exit 0
fi
