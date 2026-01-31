#!/bin/bash
# tests/e2e_tmux_test.sh - tmux 環境での E2E 動作確認テスト
# codex-collab スキルの実際の動作をシミュレート

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
TEST_SESSION="codex-collab-e2e-test"
SAMPLE_APP_DIR="$SKILL_DIR/examples/todo-app"

# 色定義
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
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

# クリーンアップ関数
cleanup() {
    echo -e "\n${CYAN}クリーンアップ中...${NC}"
    tmux kill-session -t "$TEST_SESSION" 2>/dev/null || true
    rm -f "$SAMPLE_APP_DIR/todos.json" 2>/dev/null || true
    rm -rf /tmp/.codex-collab-* 2>/dev/null || true
    "$SKILL_DIR/lib/message_queue.sh" reset 2>/dev/null || true
}

# 終了時にクリーンアップ
trap cleanup EXIT

echo -e "${CYAN}━━━ codex-collab E2E テスト ━━━${NC}"
echo "サンプルアプリ: $SAMPLE_APP_DIR"
echo ""

# ===== 前提条件チェック =====
echo -e "${CYAN}## 前提条件チェック${NC}"

# tmux 確認
if command -v tmux &> /dev/null; then
    test_case "tmux インストール確認" 0
else
    test_case "tmux インストール確認" 1
    echo -e "${RED}tmux がインストールされていません。テストを中止します。${NC}"
    exit 1
fi

# Node.js 確認
if command -v node &> /dev/null; then
    test_case "Node.js インストール確認" 0
else
    test_case "Node.js インストール確認" 1
fi

# サンプルアプリ確認
if [[ -f "$SAMPLE_APP_DIR/index.js" ]]; then
    test_case "サンプルアプリ存在確認" 0
else
    test_case "サンプルアプリ存在確認" 1
    echo -e "${RED}サンプルアプリが見つかりません${NC}"
    exit 1
fi

echo ""

# ===== tmux セッション作成 =====
echo -e "${CYAN}## tmux セッション作成${NC}"

# 既存セッションがあれば削除
tmux kill-session -t "$TEST_SESSION" 2>/dev/null || true

# 新規セッション作成（デタッチモード）
tmux new-session -d -s "$TEST_SESSION" -n "test" -c "$SAMPLE_APP_DIR"
test_case "tmux セッション作成" $?

# 右ペイン作成（Codex 役）
tmux split-window -h -t "$TEST_SESSION" -c "$SAMPLE_APP_DIR"
test_case "右ペイン作成" $?

# セッション確認
tmux has-session -t "$TEST_SESSION" 2>/dev/null
test_case "セッション存在確認" $?

echo ""

# ===== サンプルアプリ動作確認 =====
echo -e "${CYAN}## サンプルアプリ動作確認${NC}"

# Todo 追加
output=$(cd "$SAMPLE_APP_DIR" && node index.js add "テストタスク1" 2>&1)
echo "$output" | grep -q "Added" && test_case "Todo 追加" 0 || test_case "Todo 追加" 1

# Todo 一覧
output=$(cd "$SAMPLE_APP_DIR" && node index.js list 2>&1)
echo "$output" | grep -q "テストタスク1" && test_case "Todo 一覧表示" 0 || test_case "Todo 一覧表示" 1

# Todo 完了
output=$(cd "$SAMPLE_APP_DIR" && node index.js done 1 2>&1)
echo "$output" | grep -q "Completed" && test_case "Todo 完了" 0 || test_case "Todo 完了" 1

echo ""

# ===== tmux 経由のメッセージ送受信テスト =====
echo -e "${CYAN}## tmux メッセージ送受信テスト${NC}"

# 左ペイン（Claude 役）にメッセージ送信
tmux send-keys -t "${TEST_SESSION}:0.0" "echo '[MESSAGE:CLAUDE:QUESTION]' && echo 'Todo アプリに優先度機能を追加したいのですが、どう設計すべきですか？'" Enter
sleep 1

# 左ペインの出力をキャプチャ
captured=$(tmux capture-pane -t "${TEST_SESSION}:0.0" -p 2>/dev/null || echo "")
echo "$captured" | grep -q "MESSAGE:CLAUDE:QUESTION" && test_case "tmux メッセージ送信（QUESTION）" 0 || test_case "tmux メッセージ送信（QUESTION）" 1

# 右ペイン（Codex 役）にレスポンス送信
tmux send-keys -t "${TEST_SESSION}:0.1" "echo '[RESPONSE:DESIGN]' && echo '優先度は 1-5 の整数で管理し、Todo オブジェクトに priority フィールドを追加することを推奨します。'" Enter
sleep 1

# 右ペインの出力をキャプチャ
captured=$(tmux capture-pane -t "${TEST_SESSION}:0.1" -p 2>/dev/null || echo "")
echo "$captured" | grep -q "RESPONSE:DESIGN" && test_case "tmux メッセージ送信（RESPONSE）" 0 || test_case "tmux メッセージ送信（RESPONSE）" 1

echo ""

# ===== send_to_claude.sh テスト（tmux 内から） =====
echo -e "${CYAN}## send_to_claude.sh tmux 統合テスト${NC}"

# セッション名を環境変数で設定してテスト
export TMUX="/tmp/tmux-$(id -u)/default,12345,0"

# キューモードでのメッセージ送信
output=$("$SKILL_DIR/scripts/send_to_claude.sh" --type SUGGESTION "テスト提案メッセージ" 2>&1)
echo "$output" | grep -q "Message sent" && test_case "send_to_claude.sh キューモード送信" 0 || test_case "send_to_claude.sh キューモード送信" 1

# キュー確認
count=$("$SKILL_DIR/lib/message_queue.sh" count-pending 2>/dev/null || echo "0")
[[ "$count" -ge 1 ]] && test_case "メッセージキュー登録確認" 0 || test_case "メッセージキュー登録確認" 1

echo ""

# ===== collab.sh 統合テスト =====
echo -e "${CYAN}## collab.sh 統合テスト${NC}"

# セッション初期化
session_id=$("$SKILL_DIR/lib/session_state.sh" init --feature "priority" --project "todo-app" 2>&1)
[[ "$session_id" =~ ^codex-collab- ]] && test_case "セッション初期化" 0 || test_case "セッション初期化" 1

# 双方向メッセージ追加
msg_id=$("$SKILL_DIR/lib/session_state.sh" add-message \
    --direction codex_to_claude \
    --type QUESTION \
    --content "優先度機能の実装方法について相談" 2>/dev/null)
[[ "$msg_id" =~ ^msg- ]] && test_case "メッセージ追加（Codex→Claude）" 0 || test_case "メッセージ追加（Codex→Claude）" 1

# Claude からの返信追加
msg_id2=$("$SKILL_DIR/lib/session_state.sh" add-message \
    --direction claude_to_codex \
    --type SUGGESTION \
    --content "priority フィールドを追加し、ソート機能を実装することを推奨" 2>/dev/null)
[[ "$msg_id2" =~ ^msg- ]] && test_case "メッセージ追加（Claude→Codex）" 0 || test_case "メッセージ追加（Claude→Codex）" 1

# メッセージ履歴取得
messages=$("$SKILL_DIR/lib/session_state.sh" get-messages 2>/dev/null)
msg_count=$(echo "$messages" | grep -c '"direction"' || echo "0")
[[ "$msg_count" -ge 2 ]] && test_case "メッセージ履歴取得（双方向）" 0 || test_case "メッセージ履歴取得（双方向）" 1

echo ""

# ===== プロトコル検証テスト =====
echo -e "${CYAN}## プロトコル検証テスト${NC}"

# 各種メッセージパターンの検出
test_patterns() {
    local pattern="$1"
    local expected_type="$2"
    local expected_kind="$3"
    local name="$4"

    echo "$pattern" > /tmp/test_pattern.txt
    local result
    result=$("$SKILL_DIR/lib/protocol.sh" detect-type /tmp/test_pattern.txt 2>/dev/null || echo "")

    if [[ "$result" == "TYPE=$expected_type KIND=$expected_kind" ]]; then
        test_case "$name" 0
    else
        test_case "$name" 1
        echo -e "${YELLOW}  Expected: TYPE=$expected_type KIND=$expected_kind${NC}"
        echo -e "${YELLOW}  Got: $result${NC}"
    fi
    rm -f /tmp/test_pattern.txt
}

test_patterns "[MESSAGE:CLAUDE:QUESTION]" "MESSAGE" "QUESTION" "QUESTION パターン検出"
test_patterns "[MESSAGE:CLAUDE:SUGGESTION]" "MESSAGE" "SUGGESTION" "SUGGESTION パターン検出"
test_patterns "[MESSAGE:CLAUDE:ALERT]" "MESSAGE" "ALERT" "ALERT パターン検出"
test_patterns "[CHAT:CODEX]" "CHAT" "CODEX" "CHAT:CODEX パターン検出"
test_patterns "[CONSULT:DESIGN]" "CONSULT" "DESIGN" "CONSULT:DESIGN パターン検出"
test_patterns "[RESPONSE:IMPLEMENTATION]" "RESPONSE" "IMPLEMENTATION" "RESPONSE:IMPLEMENTATION パターン検出"

echo ""

# ===== 結果サマリー =====
echo -e "${CYAN}━━━ E2E テスト結果 ━━━${NC}"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"

if [[ $FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}✅ All E2E tests passed!${NC}"
    echo ""
    echo -e "${CYAN}次のステップ:${NC}"
    echo "  1. 実際の tmux 環境で試す:"
    echo "     ./scripts/setup_pair_env.sh test-session $SAMPLE_APP_DIR"
    echo ""
    echo "  2. Codex ペインから Claude に質問:"
    echo "     ask-claude \"Todo アプリに期限機能を追加したい\""
    echo ""
    exit 0
else
    echo -e "\n${RED}❌ Some E2E tests failed${NC}"
    exit 1
fi
