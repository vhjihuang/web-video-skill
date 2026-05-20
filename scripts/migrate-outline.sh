#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# migrate-outline.sh — 将 outline.md 的信息池从 v1（纯文本）迁移到 v2（YAML 内嵌）
#
# 用法：
#   bash scripts/migrate-outline.sh <outline.md>
#   bash scripts/migrate-outline.sh <outline.md> --dry-run     # 仅预览，不写文件
#   bash scripts/migrate-outline.sh <outline.md> --rollback    # 回滚到备份
#
# 功能：
#   1. 备份原文件为 outline.md.pre-yaml-backup
#   2. 检测每章的信息池格式（v1 / v2 / mixed）
#   3. 将 v1 格式的 `- key: value —— source` 转换为 YAML 代码块
#   4. 自动推断 type 枚举值（基于关键词匹配）
#   5. 生成全局唯一 id（基于 label 的 kebab-case）
# ─────────────────────────────────────────────────────────────
set -euo pipefail

red=$'\033[0;31m'
green=$'\033[0;32m'
yellow=$'\033[0;33m'
bold=$'\033[1m'
reset=$'\033[0m'

OUTLINE="${1:-outline.md}"
DRY_RUN=false
ROLLBACK=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --rollback) ROLLBACK=true ;;
  esac
done

if [[ ! -f "$OUTLINE" ]]; then
  echo "✗ 文件不存在: ${OUTLINE}" >&2; exit 1;
fi

# ── 回滚模式 ──
if [[ "$ROLLBACK" == true ]]; then
  BACKUP="${OUTLINE}.pre-yaml-backup"
  if [[ ! -f "$BACKUP" ]]; then
    echo "✗ 回滚备份不存在: ${BACKUP}" >&2; exit 1;
  fi
  cp "$BACKUP" "$OUTLINE"
  echo "✓ 已回滚: ${OUTLINE} ← ${BACKUP}"
  exit 0
fi

# ── 创建备份 ──
BACKUP="${OUTLINE}.pre-yaml-backup"
if [[ ! -f "$BACKUP" ]]; then
  cp "$OUTLINE" "$BACKUP"
  echo "▸ 已创建备份: ${BACKUP}"
else
  echo "⚠️  备份已存在: ${BACKUP}（跳过重新备份）"
fi

# ── 分析当前格式 ──
echo ""
echo "${bold}━━━ outline.md 格式分析 ━━━${reset}"

V1_COUNT=0
V2_COUNT=0
CHAPTERS=()

while IFS= read -r line; do
  if [[ "$line" =~ ^\#\#[[:space:]]+[0-9]+\. ]]; then
    CHAPTERS+=("$line")
  fi
  # v1 检测：`- xxx —— 来源` 或 `- key: value`（无 YAML 缩进）
  if [[ "$line" =~ ^-\ .*——.*来源 ]] || \
     [[ "$line" =~ ^-\ [^*\`]+:[^\`] ]]; then
    ((V1_COUNT++))
  fi
  # v2 检测：YAML 代码块内的 `- id:` 或 `label:`
  if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+id:[[:space:]] || "$line" =~ ^[[:space:]]+label:[[:space:]] ]]; then
    ((V2_COUNT++))
  fi
done < "$OUTLINE"

echo "  章节数: ${#CHAPTERS[@]}"
echo "  v1 条目 (纯文本): ${V1_COUNT}"
echo "  v2 条目 (YAML):    ${V2_COUNT}"

if [[ "$V1_COUNT" -eq 0 && "$V2_COUNT" -gt 0 ]]; then
  echo ""
  echo "🎉 已经是 v2 YAML 格式，无需迁移！"
  exit 0
fi

if [[ "$V1_COUNT" -eq 0 && "$V2_COUNT" -eq 0 ]]; then
  echo ""
  echo "⚠️  未检测到任何信息池条目（可能使用了非标准格式）"
  exit 1
fi

# ── 类型推断函数 ──
infer_type() {
  local text="$1"
  if echo "$text" | grep -qiE '❌|→|✅|对比|vs|A vs B|划掉'; then
    echo "term-pair"
  elif echo "$text" | grep -qiE '数字|数据|%|倍|效率|比例|时长|统计'; then
    echo "data"
  elif echo "$text" | grep -qiE '案例|故事|人物|工程师|经理|用户|场景'; then
    echo "case"
  elif echo "$text" | grep -qiE '概念|原理|方法论|金字塔|层|结构|框架|模式'; then
    echo "concept"
  elif echo "$text" | grep -qiE '对比|比较|传统|找专家|自己研究|花钱|时间'; then
    echo "comparison"
  else
    echo "text-quote"
  fi
}

# ── label → id 转换 ──
label_to_id() {
  echo "$1" | sed -E '
    s/[：:]/-/g
    s/[^a-zA-Z\u4e00-\u9fff0-9-]//g
    s/^\s+//; s/\s+$//
    s/--+/-/g
    s/(.*)//g
    s/^-(.)/\1/
  ' | head -c 40
}

# ── 执行迁移 ──
echo ""
echo "${bold}━━━ 执行 v1 → v2 迁移 ━━━${reset}"

TEMP_FILE=$(mktemp)
IN_POOL_BLOCK=0
POOL_CONTENT=""
CURRENT_CHAPTER="unknown"
CHANGED=0

while IFS= read -r line || [[ -n "$line" ]]; do
  # 检测章节标题
  if [[ "$line" =~ ^\#\#[[:space:]]+(第.+章|[0-9]+\..+) ]]; then
    CURRENT_CHAPTER=$(echo "$line" | sed -E 's/^#+[[:space:]]*//')
  fi

  # 检测进入信息池区块
  if [[ "$line" =~ ^(\*\*)?信息池[：:] ]]; then
    IN_POOL_BLOCK=1
    POOL_CONTENT=""
    echo "$line" >> "$TEMP_FILE"
    continue
  fi

  # 检测离开信息池区块（遇到 **Step** 或 **开发计划** 或 --- 或 ## ）
  if [[ "$IN_POOL_BLOCK" == 1 && ( \
    "$line" =~ ^(Step|开发计划|\*\*Step|\*\*开发计划|---|\*\*---|\#\#) || \
    "$line" =~ ^\*\*Step\ 规划 ) ]]; then
    IN_POOL_BLOCK=0

    # 输出收集到的内容 + YAML 包裹
    if [[ -n "$POOL_CONTENT" ]]; then
      # 判断是否已经是 YAML 格式
      if echo "$POOL_CONTENT" | grep -q '^- *id:'; then
        # 已是 v2，原样输出
        echo "$POOL_CONTENT" >> "$TEMP_FILE"
      else
        # v1 → v2 转换
        echo '```yaml' >> "$TEMP_FILE"
        echo "# 信息池（v2 — 由 migrate-outline.sh 从 v1 自动转换）" >> "$TEMP_FILE"
        echo "$POOL_CONTENT" | while IFS= read -r pline; do
          if [[ "$pline" =~ ^-\ (.+):\ (.+)$ ]] || \
             [[ "$pline" =~ ^-\ (.+)\ ——\ (.+)$ ]]; then
            local content="${BASH_REMATCH[1]}"
            local source_or_extra="${BASH_REMATCH[2]:-}"
            local id=$(label_to_id "$content")
            local type=$(infer_type "$content")

            # 判断是否有明确的 source 标注
            if echo "$source_or_extra" | grep -qiE '^(来源|article|§|L)'; then
              local source="$source_or_extra"
              source=$(echo "$source" | sed -E 's/^来源[：:]?\s*//' | sed -E 's/文章/article/')
            else
              # 没有明确 source，用 extra 内容作为 label 后缀提示
              local source="待确认"
            fi
            printf "  - id: %s\n    label: \"%s\"\n    type: %s\n    source: %s\n    priority: should\n" \
              "$id" "$content" "$type" "$source" >> "$TEMP_FILE"
            ((CHANGED++))
          else
            # 非标准行，保留原样加注释
            echo "  # (未转换) ${pline}" >> "$TEMP_FILE"
          fi
        done
        echo '```' >> "$TEMP_FILE"
      fi
      POOL_CONTENT=""
    fi

    echo "$line" >> "$TEMP_FILE"
    continue
  fi

  # 在信息池内，收集行
  if [[ "$IN_POOL_BLOCK" == 1 ]]; then
    # 跳过空行和已有的 YAML 标记
    if [[ -n "$(echo "$line" | tr -d '[:space:]')" ]]; then
      POOL_CONTENT="${POOL_CONTENT}${line}"$'\n'
    fi
    echo "$line" >> "$TEMP_FILE"
  else
    echo "$line" >> "$TEMP_FILE"
  fi
done < "$OUTLINE"

# ── 写回或预览 ──
if [[ "$DRY_RUN" == true ]]; then
  echo ""
  echo "━━━ DRY RUN 结果（未写入文件）━━━"
  echo "  转换了 ${CHANGED} 条 v1 条目 → v2 YAML"
  echo "  使用 --dry-run=false（去掉 --dry-run）执行实际写入"
  rm -f "$TEMP_FILE"
else
  cp "$TEMP_FILE" "$OUTLINE"
  rm -f "$TEMP_FILE"
  echo ""
  echo "✅ 迁移完成！转换了 ${CHANGED} 条信息池条目为 v2 YAML 格式"
  echo "  原文件备份: ${BACKUP}"
  echo "  回滚命令: bash $0 ${OUTLINE} --rollback"
  echo ""
  echo "下一步：运行 validate-outline.sh 校验新格式"
fi
