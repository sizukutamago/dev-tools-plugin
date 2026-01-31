#!/bin/bash
# scripts/watch_for_codex_messages.sh - キュー監視デーモン
# バックグラウンドでキューを監視し、pending メッセージを Claude に配信
#
# 使用例:
#   ./watch_for_codex_messages.sh              # フォアグラウンド実行
#   ./watch_for_codex_messages.sh --daemon     # バックグラウンド実行
#   ./watch_for_codex_messages.sh --stop       # 停止
#   ./watch_for_codex_messages.sh --status     # ステータス確認

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
LIB_DIR="${SKILL_DIR}/lib"

# 設定
POLL_INTERVAL=5  # 秒
PID_FILE="${SKILL_DIR}/.codex-collab/watcher.pid"
LOG_FILE="${SKILL_DIR}/.codex-collab/watcher.log"

# ライブラリを読み込み
source "${LIB_DIR}/message_queue.sh"

# 使用方法を表示
show_usage() {
    cat << 'EOF'
Usage: watch_for_codex_messages.sh [OPTIONS]

Codex からのメッセージキューを監視し、Claude に配信します。

Options:
  --daemon       バックグラウンドで実行
  --stop         実行中の watcher を停止
  --status       watcher のステータスを確認
  --interval N   ポーリング間隔（秒、デフォルト: 5）
  -h, --help     このヘルプを表示

Examples:
  ./watch_for_codex_messages.sh              # フォアグラウンド実行
  ./watch_for_codex_messages.sh --daemon     # バックグラウンド実行
  ./watch_for_codex_messages.sh --stop       # 停止
  ./watch_for_codex_messages.sh --status     # ステータス確認
EOF
}

# PID ファイルのディレクトリを確保
ensure_dirs() {
    mkdir -p "$(dirname "$PID_FILE")"
}

# watcher が実行中か確認
is_running() {
    if [[ ! -f "$PID_FILE" ]]; then
        return 1
    fi

    local pid
    pid=$(cat "$PID_FILE")

    if kill -0 "$pid" 2>/dev/null; then
        return 0
    else
        # PID ファイルがあるが、プロセスがない
        rm -f "$PID_FILE"
        return 1
    fi
}

# ステータスを表示
show_status() {
    if is_running; then
        local pid
        pid=$(cat "$PID_FILE")
        echo "✓ Watcher is running (PID: $pid)"

        local pending_count
        pending_count=$(count_pending)
        echo "  Pending messages: $pending_count"

        if [[ -f "$LOG_FILE" ]]; then
            echo "  Last log entries:"
            tail -3 "$LOG_FILE" | sed 's/^/    /'
        fi
    else
        echo "✗ Watcher is not running"
    fi
}

# watcher を停止
stop_watcher() {
    if ! is_running; then
        echo "Watcher is not running"
        return 0
    fi

    local pid
    pid=$(cat "$PID_FILE")

    echo "Stopping watcher (PID: $pid)..."
    kill "$pid" 2>/dev/null || true

    # プロセスが終了するまで待機
    local count=0
    while kill -0 "$pid" 2>/dev/null; do
        sleep 0.5
        ((count++)) || true
        if [[ $count -ge 10 ]]; then
            echo "Force killing..."
            kill -9 "$pid" 2>/dev/null || true
            break
        fi
    done

    rm -f "$PID_FILE"
    echo "✓ Watcher stopped"
}

# メッセージを Claude に配信
deliver_message() {
    local message_json="$1"

    # JSON からフィールドを抽出
    local msg_id
    msg_id=$(echo "$message_json" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')

    local msg_type
    msg_type=$(echo "$message_json" | sed -n 's/.*"type":"\([^"]*\)".*/\1/p')

    local msg_content
    msg_content=$(echo "$message_json" | sed -n 's/.*"message":"\([^"]*\)".*/\1/p')

    # send_to_claude.sh を使用して配信
    if "${SCRIPT_DIR}/send_to_claude.sh" --type "$msg_type" "$msg_content"; then
        mark_delivered "$msg_id"
        log_message "Delivered: $msg_id (type: $msg_type)"
        return 0
    else
        log_message "Failed to deliver: $msg_id"
        return 1
    fi
}

# ログを記録
log_message() {
    local message="$1"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

# メインループ
watch_loop() {
    log_message "Watcher started (interval: ${POLL_INTERVAL}s)"
    echo "Watching for Codex messages (interval: ${POLL_INTERVAL}s)..."
    echo "Press Ctrl+C to stop"

    trap 'log_message "Watcher stopped"; exit 0' INT TERM

    while true; do
        # pending メッセージを確認
        local message
        message=$(dequeue_for_claude)

        if [[ "$message" != "null" && -n "$message" ]]; then
            deliver_message "$message"
        fi

        sleep "$POLL_INTERVAL"
    done
}

# デーモンとして起動
start_daemon() {
    if is_running; then
        local pid
        pid=$(cat "$PID_FILE")
        echo "Watcher is already running (PID: $pid)"
        return 1
    fi

    ensure_dirs

    # バックグラウンドで起動
    nohup "$0" > /dev/null 2>&1 &
    local pid=$!

    echo "$pid" > "$PID_FILE"
    echo "✓ Watcher started in background (PID: $pid)"
    echo "  Log: $LOG_FILE"
    echo "  Stop: $0 --stop"
}

# メイン処理
main() {
    local daemon_mode=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --daemon)
                daemon_mode=true
                shift
                ;;
            --stop)
                stop_watcher
                exit 0
                ;;
            --status)
                show_status
                exit 0
                ;;
            --interval)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --interval requires a number" >&2
                    exit 1
                fi
                POLL_INTERVAL="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                echo "Error: Unknown option: $1" >&2
                show_usage
                exit 1
                ;;
        esac
    done

    ensure_dirs

    if [[ "$daemon_mode" == true ]]; then
        start_daemon
    else
        # フォアグラウンド実行時は PID を記録
        echo $$ > "$PID_FILE"
        trap 'rm -f "$PID_FILE"' EXIT
        watch_loop
    fi
}

main "$@"
