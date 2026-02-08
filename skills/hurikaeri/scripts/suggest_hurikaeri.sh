#!/bin/bash
# suggest_hurikaeri.sh - Stop hook: 複雑セッションで振り返り提案
#
# 判定基準:
#   - JSONL 行数 >= 50 かつ ツール使用 >= 10
#   - OR コード変更（Write/Edit）>= 5
#   - OR エラー >= 3
#   - ただし JSONL 行数 < 20 は除外（軽微セッション）
#
# 出力: stderr に提案メッセージ（他の Stop hook と共存可能）

set -euo pipefail

# 標準入力から hook データを読み取り
INPUT=$(cat)

# 入力が空の場合は終了
if [ -z "$INPUT" ]; then
    echo '{"continue": true}'
    exit 0
fi

# transcript_path を抽出
if command -v jq &>/dev/null; then
    TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')
else
    TRANSCRIPT_PATH=$(echo "$INPUT" | grep -o '"transcript_path":"[^"]*"' | cut -d'"' -f4)
fi

# ファイルなければ終了
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
    echo '{"continue": true}'
    exit 0
fi

# メトリクス取得
MESSAGE_COUNT=$(wc -l < "$TRANSCRIPT_PATH" | tr -d ' ')
# ツール使用カウント（"type": "tool_use" パターンで精度向上）
TOOL_USES=$(grep -c '"type"[[:space:]]*:[[:space:]]*"tool_use"' "$TRANSCRIPT_PATH" 2>/dev/null || echo "0")
# コード変更カウント（"name": "Write" / "Edit" パターン）
CODE_CHANGES=$(grep -cE '"name"[[:space:]]*:[[:space:]]*"(Write|Edit)"' "$TRANSCRIPT_PATH" 2>/dev/null || echo "0")
ERROR_COUNT=$(grep -c '"is_error"[[:space:]]*:[[:space:]]*true' "$TRANSCRIPT_PATH" 2>/dev/null || echo "0")

# 軽微セッションは除外
if [ "$MESSAGE_COUNT" -lt 20 ]; then
    echo '{"continue": true}'
    exit 0
fi

# 判定
SUGGEST=false
if [ "$MESSAGE_COUNT" -ge 50 ] && [ "$TOOL_USES" -ge 10 ]; then
    SUGGEST=true
fi
if [ "$CODE_CHANGES" -ge 5 ]; then
    SUGGEST=true
fi
if [ "$ERROR_COUNT" -ge 3 ]; then
    SUGGEST=true
fi

# 提案出力（stderr 経由でユーザーに表示）
if [ "$SUGGEST" = true ]; then
    # stderr に出力（元の stderr を復元して出力）
    exec 3>&2
    echo "" >&3
    echo "🔄 複雑なセッションでした（lines:${MESSAGE_COUNT}, tools:${TOOL_USES}, changes:${CODE_CHANGES}）" >&3
    echo "   → /hurikaeri で振り返りを実行できます" >&3
fi

echo '{"continue": true}'
