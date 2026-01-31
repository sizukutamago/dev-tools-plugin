#!/bin/bash
# scripts/send_to_claude.sh - Codex → Claude 直接メッセージ送信
# tmux send-keys を使用して Claude Code のペインにメッセージを送信
#
# 使用例:
#   ./send_to_claude.sh "質問テキスト"
#   ./send_to_claude.sh --type QUESTION "認証方式はどれがいい？"
#   ./send_to_claude.sh --type SUGGESTION "レート制限を検討すべき"
#   ./send_to_claude.sh --type ALERT "セキュリティリスクを発見"
#   ./send_to_claude.sh --file /tmp/message.txt
#   ./send_to_claude.sh --queue --type QUESTION "キュー経由で送信"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# デフォルト値
MESSAGE_TYPE="CHAT"
USE_QUEUE=false
MESSAGE=""
MESSAGE_FILE=""

# 使用方法を表示
show_usage() {
    cat << 'EOF'
Usage: send_to_claude.sh [OPTIONS] [MESSAGE]

Codex から Claude Code へメッセージを送信します。

Options:
  --type TYPE      メッセージタイプ (QUESTION|SUGGESTION|ALERT|CHAT)
                   デフォルト: CHAT
  --file FILE      ファイルからメッセージを読み込む
  --queue          キュー経由で送信（watcher が必要）
  -h, --help       このヘルプを表示

Message Types:
  QUESTION    質問（Claude の回答を期待）
  SUGGESTION  提案（コードや設計への提案）
  ALERT       警告（問題検出の通知）
  CHAT        自由形式チャット（デフォルト）

Examples:
  send_to_claude.sh "簡単なメッセージ"
  send_to_claude.sh --type QUESTION "認証方式はJWTとセッションどちらが良い？"
  send_to_claude.sh --type SUGGESTION "ここにバリデーションを追加すべき"
  send_to_claude.sh --type ALERT "N+1クエリを検出しました"
  send_to_claude.sh --file /tmp/detailed_question.txt --type QUESTION

Aliases (setup_pair_env.sh で設定):
  ask-claude      = send_to_claude.sh --type QUESTION
  suggest-claude  = send_to_claude.sh --type SUGGESTION
  alert-claude    = send_to_claude.sh --type ALERT
  chat-claude     = send_to_claude.sh --type CHAT
EOF
}

# 引数をパース
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --type)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --type requires an argument" >&2
                    exit 1
                fi
                MESSAGE_TYPE="$2"
                shift 2
                ;;
            --file)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --file requires an argument" >&2
                    exit 1
                fi
                MESSAGE_FILE="$2"
                shift 2
                ;;
            --queue)
                USE_QUEUE=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*)
                echo "Error: Unknown option: $1" >&2
                show_usage
                exit 1
                ;;
            *)
                # 残りの引数はメッセージとして扱う
                MESSAGE="$*"
                break
                ;;
        esac
    done
}

# メッセージタイプを検証
validate_type() {
    case "$MESSAGE_TYPE" in
        QUESTION|SUGGESTION|ALERT|CHAT)
            return 0
            ;;
        *)
            echo "Error: Invalid message type: $MESSAGE_TYPE" >&2
            echo "Valid types: QUESTION, SUGGESTION, ALERT, CHAT" >&2
            exit 1
            ;;
    esac
}

# メッセージを取得
get_message() {
    if [[ -n "$MESSAGE_FILE" ]]; then
        if [[ ! -f "$MESSAGE_FILE" ]]; then
            echo "Error: File not found: $MESSAGE_FILE" >&2
            exit 1
        fi
        cat "$MESSAGE_FILE"
    elif [[ -n "$MESSAGE" ]]; then
        echo "$MESSAGE"
    else
        # stdin から読み取り
        if [[ -t 0 ]]; then
            echo "Error: No message provided" >&2
            show_usage
            exit 1
        fi
        cat
    fi
}

# プロトコルタグでメッセージをラップ
wrap_message() {
    local message="$1"
    local type="$MESSAGE_TYPE"

    if [[ "$type" == "CHAT" ]]; then
        echo "[CHAT:CODEX]"
    else
        echo "[MESSAGE:CLAUDE:$type]"
    fi
    echo "$message"
}

# tmux セッション情報を取得
get_tmux_info() {
    if [[ -z "${TMUX:-}" ]]; then
        echo "Error: Not running inside tmux" >&2
        exit 1
    fi

    # 現在のセッション名を取得
    tmux display-message -p '#S'
}

# tmux send-keys で Claude ペイン（Pane 0）に送信
send_via_tmux() {
    local wrapped_message="$1"
    local session
    session=$(get_tmux_info)

    # メッセージをエスケープ（シングルクォート対策）
    local escaped_message
    escaped_message=$(echo "$wrapped_message" | sed "s/'/'\\\\''/g")

    # Pane 0 (Claude Code) に送信
    # Enter キーを送信してメッセージを確定
    tmux send-keys -t "${session}:0.0" "$escaped_message" Enter

    echo "✓ Message sent to Claude (type: $MESSAGE_TYPE)"
}

# キュー経由で送信
send_via_queue() {
    local message="$1"
    local queue_lib="$SKILL_DIR/lib/message_queue.sh"

    if [[ ! -f "$queue_lib" ]]; then
        echo "Error: message_queue.sh not found" >&2
        echo "Queue feature requires message_queue.sh to be installed" >&2
        exit 1
    fi

    source "$queue_lib"
    enqueue_to_claude "$message" "$MESSAGE_TYPE"
    echo "✓ Message queued for Claude (type: $MESSAGE_TYPE)"
}

# メイン処理
main() {
    parse_args "$@"
    validate_type

    local message
    message=$(get_message)

    if [[ -z "$message" ]]; then
        echo "Error: Empty message" >&2
        exit 1
    fi

    local wrapped_message
    wrapped_message=$(wrap_message "$message")

    if [[ "$USE_QUEUE" == true ]]; then
        send_via_queue "$message"
    else
        send_via_tmux "$wrapped_message"
    fi
}

main "$@"
