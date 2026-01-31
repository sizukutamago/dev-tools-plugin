#!/bin/bash
# tests/test_interactive_chat.sh - Codex → Claude インタラクティブチャット機能のテスト
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# 色定義
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

PASSED=0
FAILED=0

# テスト関数
test_case() {
    local name="$1"
    local result="$2"

    if [[ "$result" == "0" ]]; then
        echo -e "${GREEN}✓${NC} $name"
        ((PASSED++)) || true
    else
        echo -e "${RED}✗${NC} $name"
        ((FAILED++)) || true
    fi
}

echo -e "${CYAN}━━━ codex-collab v2.1.0 テスト ━━━${NC}"
echo ""

# ===== protocol.sh テスト =====
echo -e "${CYAN}## protocol.sh${NC}"

# MESSAGE:CLAUDE:QUESTION パターン
echo '[MESSAGE:CLAUDE:QUESTION]' > /tmp/test_msg_q.txt
echo 'テスト質問' >> /tmp/test_msg_q.txt
result=$("$SKILL_DIR/lib/protocol.sh" detect-type /tmp/test_msg_q.txt)
[[ "$result" == "TYPE=MESSAGE KIND=QUESTION" ]] && test_case "MESSAGE:CLAUDE:QUESTION 検出" 0 || test_case "MESSAGE:CLAUDE:QUESTION 検出" 1

# MESSAGE:CLAUDE:SUGGESTION パターン
echo '[MESSAGE:CLAUDE:SUGGESTION]' > /tmp/test_msg_s.txt
result=$("$SKILL_DIR/lib/protocol.sh" detect-type /tmp/test_msg_s.txt)
[[ "$result" == "TYPE=MESSAGE KIND=SUGGESTION" ]] && test_case "MESSAGE:CLAUDE:SUGGESTION 検出" 0 || test_case "MESSAGE:CLAUDE:SUGGESTION 検出" 1

# MESSAGE:CLAUDE:ALERT パターン
echo '[MESSAGE:CLAUDE:ALERT]' > /tmp/test_msg_a.txt
result=$("$SKILL_DIR/lib/protocol.sh" detect-type /tmp/test_msg_a.txt)
[[ "$result" == "TYPE=MESSAGE KIND=ALERT" ]] && test_case "MESSAGE:CLAUDE:ALERT 検出" 0 || test_case "MESSAGE:CLAUDE:ALERT 検出" 1

# CHAT:CODEX パターン
echo '[CHAT:CODEX]' > /tmp/test_chat.txt
result=$("$SKILL_DIR/lib/protocol.sh" detect-type /tmp/test_chat.txt)
[[ "$result" == "TYPE=CHAT KIND=CODEX" ]] && test_case "CHAT:CODEX 検出" 0 || test_case "CHAT:CODEX 検出" 1

echo ""

# ===== message_queue.sh テスト =====
echo -e "${CYAN}## message_queue.sh${NC}"

# キューリセット
"$SKILL_DIR/lib/message_queue.sh" reset > /dev/null 2>&1
test_case "キューリセット" $?

# エンキュー
msg_id=$("$SKILL_DIR/lib/message_queue.sh" enqueue "テストメッセージ" QUESTION)
[[ -n "$msg_id" ]] && test_case "エンキュー" 0 || test_case "エンキュー" 1

# カウント
count=$("$SKILL_DIR/lib/message_queue.sh" count-pending)
[[ "$count" == "1" ]] && test_case "カウント (1)" 0 || test_case "カウント (1)" 1

# リスト
list=$("$SKILL_DIR/lib/message_queue.sh" list-pending)
echo "$list" | grep -q '"status":"pending"' && test_case "リスト (pending)" 0 || test_case "リスト (pending)" 1

# デキュー
dequeued=$("$SKILL_DIR/lib/message_queue.sh" dequeue)
echo "$dequeued" | grep -q '"type":"QUESTION"' && test_case "デキュー" 0 || test_case "デキュー" 1

# 配信済みマーク
"$SKILL_DIR/lib/message_queue.sh" mark-delivered "$msg_id" > /dev/null 2>&1
test_case "配信済みマーク" $?

echo ""

# ===== send_to_claude.sh テスト =====
echo -e "${CYAN}## send_to_claude.sh${NC}"

# ヘルプ表示
"$SKILL_DIR/scripts/send_to_claude.sh" --help > /dev/null 2>&1
test_case "ヘルプ表示" $?

# 無効なタイプでエラー
"$SKILL_DIR/scripts/send_to_claude.sh" --type INVALID "test" > /dev/null 2>&1 && test_case "無効タイプ拒否" 1 || test_case "無効タイプ拒否" 0

# ファイルから読み込み（キューモードで動作確認）
echo "ファイルからの質問" > /tmp/test_file_msg.txt
"$SKILL_DIR/scripts/send_to_claude.sh" --file /tmp/test_file_msg.txt --type QUESTION 2>&1 | grep -q "Message sent to Claude" && test_case "ファイル読み込み（キューモード）" 0 || test_case "ファイル読み込み（キューモード）" 1

echo ""

# ===== collab.sh テスト =====
echo -e "${CYAN}## collab.sh${NC}"

# check-messages コマンド
"$SKILL_DIR/scripts/collab.sh" check-messages > /dev/null 2>&1
test_case "check-messages コマンド" $?

# message コマンド（キューモードで動作確認）
"$SKILL_DIR/scripts/collab.sh" message "テスト" --type QUESTION 2>&1 | grep -q "Message sent to Claude" && test_case "message コマンド（キューモード）" 0 || test_case "message コマンド（キューモード）" 1

echo ""

# ===== session_state.sh テスト =====
echo -e "${CYAN}## session_state.sh${NC}"

# セッション初期化
session_id=$("$SKILL_DIR/lib/session_state.sh" init --feature "test" --project "test" 2>&1)
[[ "$session_id" =~ ^codex-collab- ]] && test_case "セッション初期化" 0 || test_case "セッション初期化" 1

# 双方向メッセージ追加
msg_id=$("$SKILL_DIR/lib/session_state.sh" add-message --direction codex_to_claude --type QUESTION --content "テスト質問")
[[ "$msg_id" =~ ^msg- ]] && test_case "双方向メッセージ追加" 0 || test_case "双方向メッセージ追加" 1

# メッセージ履歴取得
messages=$("$SKILL_DIR/lib/session_state.sh" get-messages)
echo "$messages" | grep -q '"direction":.*"codex_to_claude"' && test_case "メッセージ履歴取得" 0 || test_case "メッセージ履歴取得" 1

echo ""

# ===== 結果サマリー =====
echo -e "${CYAN}━━━ 結果 ━━━${NC}"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"

# クリーンアップ
rm -f /tmp/test_msg_*.txt /tmp/test_chat.txt /tmp/test_file_msg.txt

if [[ $FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed${NC}"
    exit 1
fi
