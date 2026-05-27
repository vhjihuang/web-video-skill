#!/bin/bash
# ledger-check.sh — 轻量级 Step Focus Ledger 字段完整性校验
# 只检查 Agent 汇报文本中的 Ledger 字段是否存在、articleExtra ≤ 3
# 不检查画面内容

set -euo pipefail

LEDGER_FILE="${1:-/dev/stdin}"

echo "[ledger-check] 检查 Step Focus Ledger 字段完整性..."

FAILS=0

LEDGER=$(cat "$LEDGER_FILE")

if ! echo "$LEDGER" | grep -qE 'S[0-9]+:'; then
  echo "[FAIL] 未检测到 Step Focus Ledger 行（格式: S0: [...]）"
  FAILS=$((FAILS + 1))
fi

STEPS=$(echo "$LEDGER" | grep -oE 'S[0-9]+:')
STEP_COUNT=$(echo "$STEPS" | wc -l | tr -d ' ')
echo "[INFO]  检测到 ${STEP_COUNT} 个 Step"

if echo "$LEDGER" | grep -qE 'S[0-9]+:'; then
  while IFS= read -r line; do
    if echo "$line" | grep -qE 'S[0-9]+:'; then
      if ! echo "$line" | grep -q '焦点='; then
        echo "[WARN] ${line:0:40}... 缺少 mainFocus（焦点=）"
      fi
    fi
  done <<< "$LEDGER"
fi

if echo "$LEDGER" | grep -qE 'articleExtra|额外信息'; then
  EXTRAS=$(echo "$LEDGER" | grep -oE '[0-9]+' | head -1)
  if echo "$LEDGER" | grep -qE '(4|5|6|7|8|9)个额外信息|articleExtra[^=]*[4-9]'; then
    echo "[WARN] articleExtra 可能 > 3，请人工确认"
  fi
fi

if [ $FAILS -eq 0 ]; then
  echo "[PASS] ledger-check 通过"
  exit 0
else
  echo "[FAIL] ledger-check 发现 ${FAILS} 个问题"
  exit 1
fi