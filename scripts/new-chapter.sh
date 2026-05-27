#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# new-chapter.sh —— 一键创建新章节脚手架。
#
# 用法：
#   bash scripts/new-chapter.sh --id=<chapter-id> --title="章节标题"
#   bash scripts/new-chapter.sh --id=why-good --title="为什么好"
#   bash scripts/new-chapter.sh --id=data-compare --title="数据对比分析"
#
# 在 presentation/ 项目根目录下执行。
# 自动完成：
#   1. 创建 src/chapters/<NN>-<id>/ 目录
#   2. 生成 <Chapter>.tsx 模板（含 step-driven 结构）
#   3. 生成 <Chapter>.css 模板（独立前缀）
#   4. 生成 narrations.ts（空数组）
#   5. 注册到 src/registry/chapters.ts
#
# 注意：生成的只是骨架模板，实际内容需按 CHAPTER-RULES-MINI.md + ANCHOR-CARD.md 填充。
# ─────────────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$PROJECT_ROOT/src"
CHAPTERS_DIR="$SRC/chapters"
REGISTRY="$SRC/registry/chapters.ts"

ID=""
TITLE=""

for arg in "$@"; do
  case "$arg" in
    --id=*)
      ID="${arg#--id=}"
      ;;
    --title=*)
      TITLE="${arg#--title=}"
      ;;
    *)
      echo "✗ 未知参数: $arg" >&2
      echo "用法: bash scripts/new-chapter.sh --id=<id> --title=\"标题\"" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$ID" ]]; then
  echo "✗ 缺少 --id 参数" >&2
  exit 1
fi
if [[ -z "$TITLE" ]]; then
  echo "✗ 缺少 --title 参数" >&2
  exit 1
fi

# id 合法性：小写 + 连字符
if ! echo "$ID" | grep -qE '^[a-z][a-z0-9]*(-[a-z0-9]+)*$'; then
  echo "✗ 章节 id 不合法: '${ID}'" >&2
  echo "  要求：小写字母开头，可用连字符（例：why-good, data-compare）" >&2
  exit 1
fi

# 自动计算序号
EXISTING=$(ls -d "$CHAPTERS_DIR"/[0-9][0-9]-* 2>/dev/null | sort -t'-' -k1 -V | tail -n1 || true)
if [[ -n "$EXISTING" ]]; then
  LAST_NUM=$(basename "$EXISTING" | grep -oP '^\K\d+')
  NEXT_NUM=$((LAST_NUM + 1))
  printf -v NEXT_NUM_PAD "%02d" "$NEXT_NUM"
else
  NEXT_NUM_PAD="02"
fi

DIR_NAME="${NEXT_NUM_PAD}-${ID}"
CHAPTER_DIR="$CHAPTERS_DIR/$DIR_NAME"

if [[ -d "$CHAPTER_DIR" ]]; then
  echo "✗ 章节目录已存在: ${CHAPTER_DIR}" >&2
  exit 1
fi

# PascalCase 组件名
COMPONENT_NAME=$(echo "$ID" | sed -E 's/(^|-)([a-z])/\U\2/g')

# CSS 前缀：取 id 前 2 字符（或每个单词首字母）
PREFIX=$(echo "$ID" | sed -E 's/-([a-z])/-\U\1/g' | grep -oP '^(.{2})' | tr '[:upper:]' '[:lower:]')

echo "▸ 创建新章节：${DIR_NAME}"
echo "▸ 标题：${TITLE}"
echo "▸ 组件：${COMPONENT_NAME}.tsx"
echo "▸ CSS 前缀：.${PREFIX}-"
echo ""

mkdir -p "$CHAPTER_DIR"

cat > "$CHAPTER_DIR/${COMPONENT_NAME}.tsx" <<TSXEOF
import { ChapterStepProps } from "../../registry/types";
import "./${COMPONENT_NAME}.css";

/**
 * ${TITLE}
 *
 * 按 CHAPTER-RULES-MINI.md 十条原则开发：
 * - 每步独占整屏 (if (step === N) return ...)
 * - 至少 1~2 处 CSS/SVG/Canvas/JS 视觉演示
 * - 清单逐个揭示 (1 项 = 1 step)
 * - 字号硬性下限：L1≥80 / L2≥56 / L3≥48 / L4≥32 / L5≥24 / L6≥18 / L7≥16 / L8≥14
 * - 颜色和字体全部走 token（语义例外需 SEMANTIC-HARDCODE 注释）
 */
export function ${COMPONENT_NAME}({ step }: ChapterStepProps) {
  switch (step) {
    case 0:
      return (
        <div className="\${prefix}-scene">
          {/* TODO: step 0 — 根据 outline 设计 */}
        </div>
      );

    default:
      return (
        <div className="\${prefix}-scene">
          <h1 className="\${prefix}-hero">${TITLE}</h1>
        </div>
      );
  }
}
TSXEOF

# 替换模板中的 prefix 占位符
sed -i '' "s/\\\${prefix}/${PREFIX}/g" "$CHAPTER_DIR/${COMPONENT_NAME}.tsx"

cat > "$CHAPTER_DIR/${COMPONENT_NAME}.css" <<CSSEOF
/* ============================================================
 * ${TITLE} — ${COMPONENT_NAME}.css
 * CSS 前缀：.${PREFIX}-
 *
 * 规则：
 * - 颜色用 token（--text / --surface / --accent 等），禁硬编码 hex
 * - 字体家族用 token（--font-display-cn 等），禁硬编码字体名
 * - 字号可硬编码（hero ≥80px / sub ≥48px / body ≥28px / cue ≥18px）
 * - 动画用 CSS keyframes，禁 setTimeout/setInterval
 * ============================================================ */

.${PREFIX}-scene {
  position: relative;
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}

.${PREFIX}-hero {
  font-family: var(--font-display-cn);
  font-size: 96px;
  color: var(--text);
  text-align: center;
}
CSSEOF

cat > "$CHAPTER_DIR/narrations.ts" <<NARREOF
// TODO: 按 script.md 对应段落填写口播文本
// 规则：
// - 数组长度 = 组件中 switch(step) 的最大 case N + 1
// - 每条 = 该 step 的口播文本（来自 script.md，语义一致）
// - 无音频过场用空串 ""
// 这是音频合成 + Auto 推进的唯一真相源

export const narrations: string[] = [
  // step 0: "",
];
NARREOF

echo "✓ 创建 ${CHAPTER_DIR}/"
echo "  ├── ${COMPONENT_NAME}.tsx"
echo "  ├── ${COMPONENT_NAME}.css"
echo "  └── narrations.ts"

# ── 注册到 chapters.ts ──

IMPORT_LINE="import ${COMPONENT_NAME} from \"../chapters/${DIR_NAME}/${COMPONENT_NAME}\";"
ARRAY_ENTRY="  { id: \"${ID}\", title: \"${TITLE}\", component: ${COMPONENT_NAME}, narrations: () => import(/* webpackChunkName: \"${ID}\" */ \"../chapters/${DIR_NAME}/narrations.ts\").then(m => m.narrations) },"

if ! grep -q "$IMPORT_LINE" "$REGISTRY" 2>/dev/null; then
  # 在最后一个 import 后面插入新 import
  if grep -q "^import " "$REGISTRY"; then
    LAST_IMPORT=$(grep -n "^import " "$REGISTRY" | tail -n1 | cut -d: -f1)
    sed -i '' "${LAST_IMPORT} a\\
\\
${IMPORT_LINE}" "$REGISTRY"
  else
    echo "" >> "$REGISTRY"
    echo "$IMPORT_LINE" >> "$REGISTRY"
  fi

  # 在 CHAPTERS 数组的最后一项后插入新条目（在 ] 之前]
  ARRAY_END=$(grep -n "^]" "$REGISTRY" | tail -n1 | cut -d: -f1)
  PREV_LINE=$((ARRAY_END - 1))
  sed -i '' "${PREV_LINE} a\\
${ARRAY_ENTRY}" "$REGISTRY"

  echo "✓ 已注册到 ${REGISTRY}"
else
  echo "⚠ ${ID} 似乎已在 chapters.ts 中注册，跳过注册步骤"
fi

echo ""
echo "下一步："
echo "  1. 打开 ${COMPONENT_NAME}.tsx 按 outline 填充每步内容"
echo "  2. 打开 narrations.ts 填写口播文本"
echo "  3. 打开 ${COMPONENT_NAME}.css 编写样式（记得用 token）"
echo "  4. 跑 npx tsc --noEmit 确认类型正确"
echo "  5. 按 CHAPTER-RULES-MINI.md §7 完工自检清单逐项核查"
