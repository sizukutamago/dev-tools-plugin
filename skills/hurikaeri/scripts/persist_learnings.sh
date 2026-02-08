#!/bin/bash
# persist_learnings.sh - KPT レポート永続化ヘルパー
#
# 使用方法:
#   echo "$KPT_YAML_CONTENT" | persist_learnings.sh
#   persist_learnings.sh < kpt_data.yaml
#
# 標準入力から YAML 形式の KPT データを受け取り、
# ~/.claude/hurikaeri/ に原子的 ID で保存する。
#
# ID 採番方式: kpt-YYYYMMDD-NNN（prompt-improver の collect_feedback.sh と同一パターン）

set -euo pipefail

HURIKAERI_DIR="$HOME/.claude/hurikaeri"
mkdir -p "$HURIKAERI_DIR"

# 原子的 ID 生成
DATE=$(date +%Y%m%d)
SEQ=1
while [ -f "$HURIKAERI_DIR/kpt-$DATE-$(printf '%03d' $SEQ).yaml" ]; do
    SEQ=$((SEQ + 1))
done
FILENAME="kpt-$DATE-$(printf '%03d' $SEQ).yaml"

# 標準入力から KPT データを保存
cat > "$HURIKAERI_DIR/$FILENAME"

echo "保存完了: $HURIKAERI_DIR/$FILENAME"
