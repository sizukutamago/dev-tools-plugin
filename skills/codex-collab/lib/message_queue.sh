#!/bin/bash
# lib/message_queue.sh - ファイルベースのメッセージキュー管理
# JSONL 形式でメッセージを保存し、配信状態を追跡
#
# 使用例:
#   source lib/message_queue.sh
#   enqueue_to_claude "質問" QUESTION
#   dequeue_for_claude
#   list_pending
#   mark_delivered "msg-123"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# キューディレクトリ
QUEUE_DIR="${SKILL_DIR}/.codex-collab/queue"
QUEUE_FILE="${QUEUE_DIR}/to_claude.jsonl"
LOCK_FILE="${QUEUE_DIR}/.lock"

# キューディレクトリを初期化
init_queue() {
    mkdir -p "$QUEUE_DIR"
    touch "$QUEUE_FILE"
}

# ロックを取得（シンプルなファイルロック）
acquire_lock() {
    local timeout=${1:-10}
    local count=0

    while [[ -f "$LOCK_FILE" ]]; do
        sleep 0.1
        ((count++)) || true
        if [[ $count -ge $((timeout * 10)) ]]; then
            echo "Error: Failed to acquire lock after ${timeout}s" >&2
            return 1
        fi
    done

    echo $$ > "$LOCK_FILE"
}

# ロックを解放
release_lock() {
    rm -f "$LOCK_FILE"
}

# ユニークなメッセージIDを生成
generate_msg_id() {
    echo "msg-$(date +%s)-$$-$RANDOM"
}

# Claude へのメッセージをキューに追加
# 引数: message, type, [priority]
enqueue_to_claude() {
    local message="${1:-}"
    local type="${2:-CHAT}"
    local priority="${3:-normal}"

    if [[ -z "$message" ]]; then
        echo "Error: Message is required" >&2
        return 1
    fi

    init_queue
    acquire_lock || return 1

    local msg_id
    msg_id=$(generate_msg_id)

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # メッセージ内の特殊文字をエスケープ
    local escaped_message
    escaped_message=$(echo "$message" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ')

    # JSONL 形式で追記
    echo "{\"id\":\"$msg_id\",\"type\":\"$type\",\"message\":\"$escaped_message\",\"priority\":\"$priority\",\"timestamp\":\"$timestamp\",\"status\":\"pending\"}" >> "$QUEUE_FILE"

    release_lock

    echo "$msg_id"
}

# pending の最初のメッセージを取得（削除しない）
peek_for_claude() {
    init_queue

    if [[ ! -s "$QUEUE_FILE" ]]; then
        echo "null"
        return 0
    fi

    # pending ステータスの最初のメッセージを取得
    grep '"status":"pending"' "$QUEUE_FILE" | head -1 || echo "null"
}

# pending の最初のメッセージを取得して削除
dequeue_for_claude() {
    init_queue
    acquire_lock || return 1

    local message
    message=$(grep '"status":"pending"' "$QUEUE_FILE" | head -1 || echo "")

    if [[ -z "$message" ]]; then
        release_lock
        echo "null"
        return 0
    fi

    # メッセージIDを抽出
    local msg_id
    msg_id=$(echo "$message" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')

    # ステータスを processing に更新
    local temp_file="${QUEUE_FILE}.tmp"
    sed "s/\"id\":\"$msg_id\",\\(.*\\)\"status\":\"pending\"/\"id\":\"$msg_id\",\\1\"status\":\"processing\"/" "$QUEUE_FILE" > "$temp_file"
    mv "$temp_file" "$QUEUE_FILE"

    release_lock

    echo "$message"
}

# メッセージを配信済みとしてマーク
mark_delivered() {
    local msg_id="${1:-}"

    if [[ -z "$msg_id" ]]; then
        echo "Error: Message ID is required" >&2
        return 1
    fi

    init_queue
    acquire_lock || return 1

    local temp_file="${QUEUE_FILE}.tmp"
    local delivered_at
    delivered_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # ステータスを delivered に更新し、配信時刻を追加
    sed "s/\"id\":\"$msg_id\",\\(.*\\)\"status\":\"[^\"]*\"/\"id\":\"$msg_id\",\\1\"status\":\"delivered\",\"delivered_at\":\"$delivered_at\"/" "$QUEUE_FILE" > "$temp_file"
    mv "$temp_file" "$QUEUE_FILE"

    release_lock

    echo "Marked as delivered: $msg_id"
}

# 保留中のメッセージ一覧を取得
list_pending() {
    init_queue

    local pending
    pending=$(grep '"status":"pending"' "$QUEUE_FILE" 2>/dev/null || echo "")

    if [[ -z "$pending" ]]; then
        echo "[]"
        return 0
    fi

    # JSONL を JSON 配列に変換
    echo "["
    echo "$pending" | sed 's/$/,/' | sed '$ s/,$//'
    echo "]"
}

# キュー内のメッセージ数を取得
count_pending() {
    init_queue
    local count
    count=$(grep -c '"status":"pending"' "$QUEUE_FILE" 2>/dev/null) || count=0
    echo "$count"
}

# 古い配信済みメッセージをクリーンアップ（24時間以上前）
cleanup_delivered() {
    init_queue
    acquire_lock || return 1

    local temp_file="${QUEUE_FILE}.tmp"
    local cutoff_time
    cutoff_time=$(date -u -v-24H +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "24 hours ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "")

    if [[ -z "$cutoff_time" ]]; then
        # 日付計算ができない場合はスキップ
        release_lock
        return 0
    fi

    # pending と processing のメッセージのみ残す
    grep -E '"status":"(pending|processing)"' "$QUEUE_FILE" > "$temp_file" 2>/dev/null || true
    mv "$temp_file" "$QUEUE_FILE"

    release_lock
}

# キューをリセット（テスト用）
reset_queue() {
    init_queue
    acquire_lock || return 1

    > "$QUEUE_FILE"

    release_lock
    echo "Queue reset"
}

# ヘルプ表示
show_help() {
    cat << 'EOF'
Usage: message_queue.sh <command> [arguments]

Commands:
  enqueue <message> <type> [priority]  メッセージをキューに追加
  dequeue                              pending の最初のメッセージを取得
  peek                                 pending の最初のメッセージを確認（削除しない）
  mark-delivered <msg_id>              メッセージを配信済みにマーク
  list-pending                         保留中メッセージ一覧
  count-pending                        保留中メッセージ数
  cleanup                              古い配信済みメッセージを削除
  reset                                キューをリセット（テスト用）

Examples:
  ./message_queue.sh enqueue "質問です" QUESTION
  ./message_queue.sh list-pending
  ./message_queue.sh mark-delivered msg-1234567890-12345
EOF
}

# メイン処理（CLI として実行された場合）
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    command="${1:-help}"
    shift || true

    case "$command" in
        enqueue)
            enqueue_to_claude "$@"
            ;;
        dequeue)
            dequeue_for_claude
            ;;
        peek)
            peek_for_claude
            ;;
        mark-delivered)
            mark_delivered "$@"
            ;;
        list-pending)
            list_pending
            ;;
        count-pending)
            count_pending
            ;;
        cleanup)
            cleanup_delivered
            ;;
        reset)
            reset_queue
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
fi
