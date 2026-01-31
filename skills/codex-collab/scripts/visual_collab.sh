#!/bin/bash
# visual_collab.sh - Codex ペインでの視覚的コラボレーション
# 右ペインで codex をインタラクティブモードで起動し、チャットに直接指示を送信

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 現在のセッションを取得
get_session() {
    "$SCRIPT_DIR/tmux_manager.sh" current
}

# 右ペインで codex を起動
start_codex() {
    local session
    session=$(get_session)

    # 右ペインをクリアして codex を起動
    "$SCRIPT_DIR/tmux_manager.sh" send "$session" 1 "clear"
    sleep 0.3
    "$SCRIPT_DIR/tmux_manager.sh" send "$session" 1 "codex"

    echo "Codex started in right pane (session: $session)"
    echo "Waiting for Codex to initialize..."
    sleep 5
}

# Codex のチャットにメッセージを送信
send_message() {
    local message="$1"
    local session
    session=$(get_session)

    # メッセージを送信
    "$SCRIPT_DIR/tmux_manager.sh" send "$session" 1 "$message"
    sleep 0.3

    # Enter キーを送信
    tmux send-keys -t "$session:0.1" Enter

    echo "Message sent to Codex"
}

# プロンプトファイルの内容を送信
send_prompt_file() {
    local prompt_file="$1"
    local session
    session=$(get_session)

    if [[ ! -f "$prompt_file" ]]; then
        echo "Error: Prompt file not found: $prompt_file" >&2
        return 1
    fi

    # ファイル内容を読み込んで送信（改行を適切に処理）
    local content
    content=$(cat "$prompt_file")

    # メッセージを送信
    "$SCRIPT_DIR/tmux_manager.sh" send "$session" 1 "$content"
    sleep 0.3

    # Enter キーを送信
    tmux send-keys -t "$session:0.1" Enter

    echo "Prompt sent to Codex from: $prompt_file"
}

# Codex が起動しているか確認
check_codex() {
    local session
    session=$(get_session)

    # 右ペインの内容をキャプチャして codex が動いているか確認
    local output
    output=$("$SCRIPT_DIR/tmux_manager.sh" capture "$session" 1 50)

    if echo "$output" | grep -q "codex\|Codex\|OpenAI"; then
        echo "running"
        return 0
    else
        echo "not_running"
        return 1
    fi
}

# ヘルプ表示
show_help() {
    cat << 'EOF'
Usage: visual_collab.sh <command> [args]

Commands:
  start                     右ペインで codex を起動
  send <message>            Codex のチャットにメッセージ送信
  send-file <prompt_file>   プロンプトファイルの内容を送信
  check                     Codex が起動しているか確認

Examples:
  ./visual_collab.sh start
  ./visual_collab.sh send "このコードをレビューしてください"
  ./visual_collab.sh send-file /tmp/review_prompt.txt
  ./visual_collab.sh check
EOF
}

# メイン処理
main() {
    local command="${1:-help}"
    shift || true

    case "$command" in
        start)
            start_codex
            ;;
        send)
            if [[ $# -lt 1 ]]; then
                echo "Error: message required" >&2
                exit 1
            fi
            send_message "$*"
            ;;
        send-file)
            if [[ $# -lt 1 ]]; then
                echo "Error: prompt_file required" >&2
                exit 1
            fi
            send_prompt_file "$1"
            ;;
        check)
            check_codex
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo "Unknown command: $command" >&2
            show_help
            exit 1
            ;;
    esac
}

main "$@"
