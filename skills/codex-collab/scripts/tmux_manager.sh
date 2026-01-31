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

# 現在の tmux セッション名を取得
get_current_session() {
    if [[ -n "${TMUX:-}" ]]; then
        tmux display-message -p '#{session_name}'
    else
        echo "Not running in tmux" >&2
        return 1
    fi
}

# 現在のセッションにペイン分割を追加（Codex 用）
ensure_codex_pane() {
    local session_name="${1:-$(get_current_session)}"

    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        echo "Session '$session_name' not found" >&2
        return 1
    fi

    # ペイン数を確認
    local pane_count
    pane_count=$(tmux list-panes -t "$session_name" -F "#{pane_index}" | wc -l | tr -d ' ')

    if [[ "$pane_count" -lt 2 ]]; then
        # 右側にペインを追加
        tmux split-window -h -t "$session_name"
        # 左ペイン（元のペイン）を選択
        tmux select-pane -t "$session_name:0.0"
        echo "Added Codex pane to session '$session_name'"
    else
        echo "Session '$session_name' already has $pane_count panes"
    fi
}

# 最新のセッションを取得（既存セッション再利用用）
get_latest_session() {
    local sessions
    sessions=$(tmux list-sessions -F "#{session_name}:#{session_created}" 2>/dev/null | grep "^codex-collab-" | sort -t: -k2 -rn | head -1 | cut -d: -f1)
    if [[ -n "$sessions" ]]; then
        echo "$sessions"
        return 0
    else
        return 1
    fi
}

# セッション取得または作成（冪等性）
get_or_create_session() {
    local session_name="${1:-}"

    # 1. 現在の tmux セッション内で実行されていればそれを使用（最優先）
    if [[ -n "${TMUX:-}" ]]; then
        get_current_session
        return 0
    fi

    # 2. 指定されたセッション名があればそれを使用
    if [[ -n "$session_name" ]] && tmux has-session -t "$session_name" 2>/dev/null; then
        echo "$session_name"
        return 0
    fi

    # 3. 既存の codex-collab セッションがあれば最新を再利用
    local existing
    existing=$(get_latest_session 2>/dev/null) || true
    if [[ -n "$existing" ]]; then
        echo "$existing"
        return 0
    fi

    # 4. なければ新規作成
    start_session "$session_name"
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

# ペインにテキスト表示（視覚的コラボ用）
display_to_pane() {
    local session_name="$1"
    local pane_index="$2"
    local text="$3"

    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        echo "Session '$session_name' not found" >&2
        return 1
    fi

    # エスケープ処理してテキストを表示
    local escaped_text
    escaped_text=$(printf '%s' "$text" | sed "s/'/'\\\\''/g")
    tmux send-keys -t "$session_name:0.$pane_index" "echo '$escaped_text'" Enter
}

# ペインクリア
clear_pane() {
    local session_name="$1"
    local pane_index="$2"

    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        echo "Session '$session_name' not found" >&2
        return 1
    fi

    tmux send-keys -t "$session_name:0.$pane_index" "clear" Enter
}

# ペインタイトル設定
set_pane_title() {
    local session_name="$1"
    local pane_index="$2"
    local title="$3"

    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        echo "Session '$session_name' not found" >&2
        return 1
    fi

    tmux select-pane -t "$session_name:0.$pane_index" -T "$title"
}

# ヘルプ表示
show_help() {
    cat << 'EOF'
Usage: tmux_manager.sh <command> [arguments]

Commands:
  current                    現在の tmux セッション名を取得（推奨）
  ensure-pane [session]      Codex 用ペインを追加（なければ）
  start [session_name]       新規セッション開始（ペイン分割済み）
  get-or-create [name]       現在のセッション取得または新規作成（冪等）
  latest                     最新の codex-collab セッション名を取得
  stop <session_name>        セッション終了
  send <session> <pane> <cmd> ペインにコマンド送信 (pane: 0=Claude, 1=Codex)
  capture <session> <pane>   ペイン出力キャプチャ
  attach <session_name>      セッションにアタッチ
  list                       codex-collab セッション一覧
  check <session_name>       セッション存在確認
  display <session> <pane> <text>  ペインにテキスト表示（視覚的コラボ用）
  clear <session> <pane>     ペインクリア
  title <session> <pane> <title>   ペインタイトル設定

Examples:
  # セッション開始
  SESSION=$(./tmux_manager.sh start)

  # Codexペイン(1)にコマンド送信
  ./tmux_manager.sh send $SESSION 1 "codex exec 'Hello'"

  # Codexペインの出力取得
  ./tmux_manager.sh capture $SESSION 1

  # ペインにテキスト表示（視覚的コラボ）
  ./tmux_manager.sh display $SESSION 0 "Claude: レビューをお願いします"
  ./tmux_manager.sh display $SESSION 1 "Codex: LGTMです"

  # ペインクリア
  ./tmux_manager.sh clear $SESSION 0

  # セッション終了
  ./tmux_manager.sh stop $SESSION
EOF
}

# メイン処理
main() {
    local command="${1:-help}"
    shift || true

    case "$command" in
        current)
            get_current_session
            ;;
        ensure-pane)
            ensure_codex_pane "$@"
            ;;
        start)
            start_session "$@"
            ;;
        get-or-create)
            get_or_create_session "$@"
            ;;
        latest)
            get_latest_session
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
        display)
            if [[ $# -lt 3 ]]; then
                echo "Error: session, pane, and text required" >&2
                exit 1
            fi
            display_to_pane "$1" "$2" "$3"
            ;;
        clear)
            if [[ $# -lt 2 ]]; then
                echo "Error: session and pane required" >&2
                exit 1
            fi
            clear_pane "$1" "$2"
            ;;
        title)
            if [[ $# -lt 3 ]]; then
                echo "Error: session, pane, and title required" >&2
                exit 1
            fi
            set_pane_title "$1" "$2" "$3"
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
