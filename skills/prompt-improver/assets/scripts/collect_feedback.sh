#!/bin/bash
# Stop hook: フィードバック収集スクリプト
# セッション終了時に条件判断してフィードバックを保存
#
# 改善履歴:
# - P0: extract_transcript.py パス修正（$SCRIPT_DIR 相対参照）
# - P1: session_id upsert（同一セッションは上書き、message_count同値ならスキップ）
# - P2: 収集条件厳格化 + 15分クールダウン
# - P3: task_summary / success 自動推定（inferred + confidence 付与）

FEEDBACK_DIR="$HOME/.claude/feedback"
mkdir -p "$FEEDBACK_DIR"

# スクリプト自身のディレクトリ（extract_transcript.py の相対参照用）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 元の stderr を退避してからデバッグログにリダイレクト
exec 3>&2
exec 2>> "$FEEDBACK_DIR/debug.log"

# 標準入力からhookデータを読み取り
INPUT=$(cat)

# デバッグ
echo "=== $(date) ===" >> "$FEEDBACK_DIR/debug.log"

# 入力が空の場合は終了
if [ -z "$INPUT" ]; then
    echo '{"continue": true}'
    exit 0
fi

# transcript_path を抽出
if command -v jq &> /dev/null; then
    TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')
    SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
else
    TRANSCRIPT_PATH=$(echo "$INPUT" | grep -o '"transcript_path":"[^"]*"' | cut -d'"' -f4)
    SESSION_ID=$(echo "$INPUT" | grep -o '"session_id":"[^"]*"' | cut -d'"' -f4)
fi

echo "TRANSCRIPT_PATH=$TRANSCRIPT_PATH" >> "$FEEDBACK_DIR/debug.log"

# transcript_path がない、またはファイルが存在しない場合は終了
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
    echo "No transcript file found" >> "$FEEDBACK_DIR/debug.log"
    echo '{"continue": true}'
    exit 0
fi

# JSONLファイルからメッセージをカウント
MESSAGE_COUNT=$(wc -l < "$TRANSCRIPT_PATH" | tr -d ' ')
TOOL_USES=$(grep -c '"tool_use"' "$TRANSCRIPT_PATH" 2>/dev/null || true)
CODE_CHANGES=$(grep -cE '"(Write|Edit|Bash)"' "$TRANSCRIPT_PATH" 2>/dev/null || true)

# transcript が空/読み取り不能などで grep が何も出さなかった場合は 0 扱い
TOOL_USES=${TOOL_USES:-0}
CODE_CHANGES=${CODE_CHANGES:-0}

echo "MESSAGE_COUNT=$MESSAGE_COUNT, TOOL_USES=$TOOL_USES, CODE_CHANGES=$CODE_CHANGES" >> "$FEEDBACK_DIR/debug.log"

# ===== P2: 収集条件の厳格化 =====
SHOULD_COLLECT=false
REASON="none"

# 条件1: コード変更が3件以上
if [ "$CODE_CHANGES" -ge 3 ]; then
    SHOULD_COLLECT=true
    REASON="code_changes"
fi

# 条件2: 実質的なセッション（MESSAGE_COUNT>=30 かつ TOOL_USES>=5）
if [ "$MESSAGE_COUNT" -ge 30 ] && [ "$TOOL_USES" -ge 5 ]; then
    SHOULD_COLLECT=true
    REASON="substantial_session"
fi

# スキップ条件: メッセージが少なすぎる（JSONLの行数ベース）
if [ "$MESSAGE_COUNT" -lt 15 ]; then
    SHOULD_COLLECT=false
    REASON="too_few_messages"
fi

echo "SHOULD_COLLECT=$SHOULD_COLLECT, REASON=$REASON" >> "$FEEDBACK_DIR/debug.log"

# 収集しない場合は終了
if [ "$SHOULD_COLLECT" = false ]; then
    echo '{"continue": true}'
    exit 0
fi

# ===== P2: 15分クールダウン =====
COOLDOWN_SECS=900  # 15分
LAST_SAVE_FILE="$FEEDBACK_DIR/.last_save_${SESSION_ID}"
NOW=$(date +%s)

if [ -f "$LAST_SAVE_FILE" ]; then
    LAST_SAVE=$(cat "$LAST_SAVE_FILE" 2>/dev/null || echo "0")
    ELAPSED=$((NOW - LAST_SAVE))
    if [ "$ELAPSED" -lt "$COOLDOWN_SECS" ]; then
        echo "COOLDOWN: ${ELAPSED}s < ${COOLDOWN_SECS}s, skipping" >> "$FEEDBACK_DIR/debug.log"
        echo '{"continue": true}'
        exit 0
    fi
fi

# ===== P1: session_id upsert（重複排除） =====
DATE=$(date +%Y%m%d)
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# 同一 session_id の既存ファイルを検索
EXISTING=""
if [ "$SESSION_ID" != "unknown" ]; then
    EXISTING=$(grep -l "session_id: $SESSION_ID" "$FEEDBACK_DIR"/fb-*.yaml 2>/dev/null | head -1)
fi

if [ -n "$EXISTING" ]; then
    # 既存ファイルの message_count を取得
    PREV_MSG_COUNT=$(grep 'message_count:' "$EXISTING" 2>/dev/null | head -1 | awk '{print $2}')
    if [ "$PREV_MSG_COUNT" = "$MESSAGE_COUNT" ]; then
        echo "UPSERT_SKIP: message_count unchanged ($MESSAGE_COUNT)" >> "$FEEDBACK_DIR/debug.log"
        echo '{"continue": true}'
        exit 0
    fi
    # 上書き: 既存ファイル名を再利用
    FILENAME=$(basename "$EXISTING")
    echo "UPSERT: overwriting $FILENAME (msg: $PREV_MSG_COUNT -> $MESSAGE_COUNT)" >> "$FEEDBACK_DIR/debug.log"
else
    # 新規: シーケンス番号を決定
    SEQ=1
    while [ -f "$FEEDBACK_DIR/fb-$DATE-$(printf '%03d' $SEQ).yaml" ]; do
        SEQ=$((SEQ + 1))
    done
    FILENAME="fb-$DATE-$(printf '%03d' $SEQ).yaml"
    echo "NEW: creating $FILENAME" >> "$FEEDBACK_DIR/debug.log"
fi

# ===== P3: task_summary / success 自動推定 =====
TASK_SUMMARY=""
SUCCESS="unknown"
CONFIDENCE="low"

if command -v python3 &> /dev/null; then
    TASK_SUMMARY=$(python3 -c "
import json, sys
for line in open('$TRANSCRIPT_PATH', encoding='utf-8'):
    try:
        d = json.loads(line.strip())
        if d.get('type') == 'human':
            content = d.get('message', {}).get('content', '')
            if isinstance(content, list):
                for c in content:
                    if isinstance(c, dict) and c.get('type') == 'text':
                        text = c.get('text', '')
                        if text.strip():
                            # system-reminder や hook 出力を除外
                            if not text.startswith('<system-reminder>') and not text.startswith('<command-'):
                                print(text[:100])
                                sys.exit(0)
            elif isinstance(content, str) and content.strip():
                if not content.startswith('<system-reminder>') and not content.startswith('<command-'):
                    print(content[:100])
                    sys.exit(0)
    except:
        pass
" 2>/dev/null || echo "")
fi

# task_summary が取得できなかった場合のフォールバック
if [ -z "$TASK_SUMMARY" ]; then
    TASK_SUMMARY="(自動抽出失敗)"
fi

# YAML のダブルクォート内で安全な文字列にする
TASK_SUMMARY=$(echo "$TASK_SUMMARY" | tr -d '\n' | sed 's/"/\\"/g' | head -c 100)

# success 推定
ERROR_COUNT=$(grep -c '"is_error":true' "$TRANSCRIPT_PATH" 2>/dev/null || true)
ERROR_COUNT=${ERROR_COUNT:-0}

if [ "$ERROR_COUNT" -eq 0 ]; then
    SUCCESS="true"
    CONFIDENCE="medium"
elif [ "$ERROR_COUNT" -le 2 ]; then
    SUCCESS="unknown"
    CONFIDENCE="low"
else
    SUCCESS="false"
    CONFIDENCE="medium"
fi

echo "AUTO_SUMMARY: task='${TASK_SUMMARY:0:50}...' success=$SUCCESS confidence=$CONFIDENCE errors=$ERROR_COUNT" >> "$FEEDBACK_DIR/debug.log"

# フィードバックテンプレート生成
# P1: FILENAME は upsert の場合は既存名、新規の場合は採番済み
FB_ID="${FILENAME%.yaml}"
cat > "$FEEDBACK_DIR/$FILENAME" << EOF
# Auto-generated by Stop hook
id: $FB_ID
created_at: $TIMESTAMP
session_id: $SESSION_ID
transcript_path: $TRANSCRIPT_PATH

# セッション統計
stats:
  message_count: $MESSAGE_COUNT
  tool_uses: $TOOL_USES
  code_changes: $CODE_CHANGES
  collection_reason: $REASON

# P3: 自動推定（inferred: true = ヒューリスティック推定値）
task_summary: "$TASK_SUMMARY"
outcome:
  success: $SUCCESS
  score: null
  rationale: "自動推定"
  inferred: true
  confidence: $CONFIDENCE

issues: []

# プライバシー
privacy:
  redacted: false

# トリアージ（初期状態）
triage:
  status: open
  priority: medium

EOF

# クールダウン: 最終保存時刻を記録
echo "$NOW" > "$LAST_SAVE_FILE"

# ===== P0: extract_transcript.py パス修正 =====
# $SCRIPT_DIR 相対参照（デプロイ先に依存しない）
EXTRACT_SCRIPT="$SCRIPT_DIR/extract_transcript.py"
if [ -f "$EXTRACT_SCRIPT" ] && command -v python3 &> /dev/null; then
    echo "Running extract_transcript.py from $EXTRACT_SCRIPT" >> "$FEEDBACK_DIR/debug.log"
    EXTRACTED=$(python3 "$EXTRACT_SCRIPT" "$TRANSCRIPT_PATH" 2>> "$FEEDBACK_DIR/debug.log")
    if [ -n "$EXTRACTED" ]; then
        echo "" >> "$FEEDBACK_DIR/$FILENAME"
        echo "# 自動抽出された詳細情報" >> "$FEEDBACK_DIR/$FILENAME"
        echo "$EXTRACTED" >> "$FEEDBACK_DIR/$FILENAME"
        echo "Extracted data appended" >> "$FEEDBACK_DIR/debug.log"
    else
        echo "No extracted data (script returned empty)" >> "$FEEDBACK_DIR/debug.log"
    fi
else
    echo "extract_transcript.py not found at $EXTRACT_SCRIPT or python3 not available" >> "$FEEDBACK_DIR/debug.log"
fi

echo "SAVED: $FILENAME" >> "$FEEDBACK_DIR/debug.log"

# === 閾値チェック: 未処理フィードバックが多い場合は通知 ===
THRESHOLD=${FEEDBACK_THRESHOLD:-5}
pending_count=$(grep -l "status: open" "$FEEDBACK_DIR"/*.yaml 2>/dev/null | wc -l | tr -d ' ')

if [ "$pending_count" -ge "$THRESHOLD" ]; then
    echo "" >&3
    echo "📊 未処理フィードバック: ${pending_count}件 → /improve で改善適用" >&3
fi

# 成功メッセージを出力
echo '{"continue": true}'
