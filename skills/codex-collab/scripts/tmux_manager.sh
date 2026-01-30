#!/bin/bash
# tmuxセッション管理スクリプト
# Claude Code と Codex のペアプログラミング用

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# セッション名生成
generate_session_name() {
    echo "codex-collab-$$-$(date +%s)"
}

# セッション開始
start_session() {
    local session_name="${1:-$(generate_session_name)}"

    # 新規セッション作成、ペイン分割
    tmux new-session -d -s "$session_name" -n "pairing"
    tmux split-window -h -t "$session_name"

    # ペインにタイトル設定
    tmux select-pane -t "$session_name:0.0" -T "Claude"
    tmux select-pane -t "$session_name:0.1" -T "Codex"

    # 左ペイン（Claude）を選択状態に
    tmux select-pane -t "$session_name:0.0"

    echo "$session_name"
}

# セッション終了
stop_session() {
    local session_name="$1"

    if tmux has-session -t "$session_name" 2>/dev/null; then
        tmux kill-session -t "$session_name"
        echo "Session '$session_name' terminated"
    else
        echo "Session '$session_name' not found" >&2
        return 1
    fi
}

# ペインにコマンド送信
send_to_pane() {
    local session_name="$1"
    local pane_index="$2"  # 0: Claude, 1: Codex
    local command="$3"

    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        echo "Session '$session_name' not found" >&2
        return 1
    fi

    tmux send-keys -t "$session_name:0.$pane_index" "$command" Enter
}

# ペイン出力キャプチャ
capture_pane() {
    local session_name="$1"
    local pane_index="$2"
    local lines="${3:-500}"  # デフォルト500行

    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        echo "Session '$session_name' not found" >&2
        return 1
    fi

    tmux capture-pane -t "$session_name:0.$pane_index" -p -S "-$lines"
}

# セッションにアタッチ
attach_session() {
    local session_name="$1"

    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        echo "Session '$session_name' not found" >&2
        return 1
    fi

    tmux attach-session -t "$session_name"
}

# セッション一覧
list_sessions() {
    tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "^codex-collab-" || true
}

# セッション存在確認
check_session() {
    local session_name="$1"

    if tmux has-session -t "$session_name" 2>/dev/null; then
        echo "exists"
        return 0
    else
        echo "not_found"
        return 1
    fi
}

# ヘルプ表示
show_help() {
    cat << 'EOF'
Usage: tmux_manager.sh <command> [arguments]

Commands:
  start [session_name]       新規セッション開始（ペイン分割済み）
  stop <session_name>        セッション終了
  send <session> <pane> <cmd> ペインにコマンド送信 (pane: 0=Claude, 1=Codex)
  capture <session> <pane>   ペイン出力キャプチャ
  attach <session_name>      セッションにアタッチ
  list                       codex-collab セッション一覧
  check <session_name>       セッション存在確認

Examples:
  # セッション開始
  SESSION=$(./tmux_manager.sh start)

  # Codexペイン(1)にコマンド送信
  ./tmux_manager.sh send $SESSION 1 "codex exec 'Hello'"

  # Codexペインの出力取得
  ./tmux_manager.sh capture $SESSION 1

  # セッション終了
  ./tmux_manager.sh stop $SESSION
EOF
}

# メイン処理
main() {
    local command="${1:-help}"
    shift || true

    case "$command" in
        start)
            start_session "$@"
            ;;
        stop)
            if [[ $# -lt 1 ]]; then
                echo "Error: session_name required" >&2
                exit 1
            fi
            stop_session "$1"
            ;;
        send)
            if [[ $# -lt 3 ]]; then
                echo "Error: session, pane, and command required" >&2
                exit 1
            fi
            send_to_pane "$1" "$2" "$3"
            ;;
        capture)
            if [[ $# -lt 2 ]]; then
                echo "Error: session and pane required" >&2
                exit 1
            fi
            capture_pane "$1" "$2" "${3:-500}"
            ;;
        attach)
            if [[ $# -lt 1 ]]; then
                echo "Error: session_name required" >&2
                exit 1
            fi
            attach_session "$1"
            ;;
        list)
            list_sessions
            ;;
        check)
            if [[ $# -lt 1 ]]; then
                echo "Error: session_name required" >&2
                exit 1
            fi
            check_session "$1"
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
