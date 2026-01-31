#!/bin/bash
# lib/session_state.sh - セッション状態管理
# 原子的書き込み（tmp→mv）+ flock によるロック
#
# 使用例:
#   ./lib/session_state.sh init --feature "auth" --project "my-app"
#   ./lib/session_state.sh get
#   ./lib/session_state.sh update --phase DESIGN --status in_progress
#   ./lib/session_state.sh list-active
#   ./lib/session_state.sh cleanup --older-than 7d

set -euo pipefail

# 設定
readonly SESSIONS_DIR="${CODEX_COLLAB_SESSIONS_DIR:-.codex-collab/sessions}"
readonly SCHEMA_VERSION=1
readonly LOCK_TIMEOUT=10

# 許容される phase/status の値
readonly VALID_PHASES="REQUIREMENTS DESIGN IMPLEMENTATION REVIEW"
readonly VALID_STATUSES="pending initializing in_progress paused completed failed"

# phase 値のバリデーション
validate_phase() {
    local phase="$1"
    if [[ -z "$phase" ]]; then
        return 0  # 空は許可（オプショナル）
    fi
    for valid in $VALID_PHASES; do
        if [[ "$phase" == "$valid" ]]; then
            return 0
        fi
    done
    echo "Error: invalid phase '$phase'. Valid values: $VALID_PHASES" >&2
    return 1
}

# status 値のバリデーション
validate_status() {
    local status="$1"
    if [[ -z "$status" ]]; then
        return 0  # 空は許可（オプショナル）
    fi
    for valid in $VALID_STATUSES; do
        if [[ "$status" == "$valid" ]]; then
            return 0
        fi
    done
    echo "Error: invalid status '$status'. Valid values: $VALID_STATUSES" >&2
    return 1
}

# 現在のセッション ID を格納するファイル
readonly CURRENT_SESSION_FILE="${SESSIONS_DIR}/.current"

# 日時取得（ISO 8601）
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# セッション ID 生成
generate_session_id() {
    local timestamp
    timestamp=$(date +%s)
    local random_suffix=$RANDOM
    echo "codex-collab-${timestamp}-${random_suffix}"
}

# セッションディレクトリ取得
get_session_dir() {
    local session_id="${1:-}"
    if [[ -z "$session_id" ]]; then
        # 現在のセッションを取得
        if [[ -f "$CURRENT_SESSION_FILE" ]]; then
            session_id=$(cat "$CURRENT_SESSION_FILE")
        else
            echo "Error: no active session" >&2
            return 1
        fi
    fi
    echo "${SESSIONS_DIR}/${session_id}"
}

# ロック取得（mkdir ベース - macOS/Linux 互換）
acquire_lock() {
    local session_dir="$1"
    local lock_dir="${session_dir}/.lock"
    local start_time
    start_time=$(date +%s)

    mkdir -p "$session_dir"

    while true; do
        if mkdir "$lock_dir" 2>/dev/null; then
            # ロック取得成功
            return 0
        fi

        # タイムアウトチェック
        local now
        now=$(date +%s)
        if [[ $((now - start_time)) -ge $LOCK_TIMEOUT ]]; then
            echo "Error: could not acquire lock (timeout ${LOCK_TIMEOUT}s)" >&2
            return 1
        fi

        sleep 0.1
    done
}

# ロック解放
release_lock() {
    local session_dir="$1"
    local lock_dir="${session_dir}/.lock"
    rmdir "$lock_dir" 2>/dev/null || true
}

# セッション初期化
init_session() {
    local feature=""
    local project=""
    local tmux_session=""
    local working_dir=""

    # 引数解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --feature)
                feature="$2"
                shift 2
                ;;
            --project)
                project="$2"
                shift 2
                ;;
            --tmux-session)
                tmux_session="$2"
                shift 2
                ;;
            --working-dir)
                working_dir="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done

    # デフォルト値
    working_dir="${working_dir:-$(pwd)}"

    # セッション ID 生成
    local session_id
    session_id=$(generate_session_id)

    local session_dir
    session_dir=$(get_session_dir "$session_id")

    # ディレクトリ作成
    mkdir -p "$session_dir"

    # 現在時刻
    local now
    now=$(get_timestamp)

    # 初期状態の JSON を作成（jq 使用）
    local state_json
    state_json=$(jq -n \
        --argjson schema_version "$SCHEMA_VERSION" \
        --arg session_id "$session_id" \
        --arg status "initializing" \
        --arg current_phase "REQUIREMENTS" \
        --arg feature "$feature" \
        --arg project "$project" \
        --arg working_directory "$working_dir" \
        --arg tmux_session "$tmux_session" \
        --arg created_at "$now" \
        --arg updated_at "$now" \
        '{
            schema_version: $schema_version,
            session_id: $session_id,
            status: $status,
            current_phase: $current_phase,
            feature: $feature,
            project: $project,
            working_directory: $working_directory,
            tmux_session: $tmux_session,
            created_at: $created_at,
            updated_at: $updated_at,
            phases: {
                REQUIREMENTS: {status: "pending", consultations: []},
                DESIGN: {status: "pending", consultations: []},
                IMPLEMENTATION: {status: "pending", consultations: []},
                REVIEW: {status: "pending", consultations: []}
            },
            pending_callbacks: [],
            error_log: []
        }')

    # 原子的書き込み（tmp → mv）
    local tmp_file="${session_dir}/state.json.tmp"
    echo "$state_json" > "$tmp_file"
    mv "$tmp_file" "${session_dir}/state.json"

    # トランスクリプトログ初期化
    echo "# Session Transcript: $session_id" > "${session_dir}/transcript.log"
    echo "Created: $now" >> "${session_dir}/transcript.log"
    echo "---" >> "${session_dir}/transcript.log"

    # 現在のセッションとして設定
    mkdir -p "$(dirname "$CURRENT_SESSION_FILE")"
    echo "$session_id" > "$CURRENT_SESSION_FILE"

    # 結果出力
    echo "$session_id"
}

# セッション状態取得
get_session() {
    local session_id="${1:-}"
    local session_dir
    session_dir=$(get_session_dir "$session_id") || return 1

    local state_file="${session_dir}/state.json"
    if [[ ! -f "$state_file" ]]; then
        echo "Error: session state not found: $state_file" >&2
        return 1
    fi

    cat "$state_file"
}

# セッション状態更新
update_session() {
    local session_id=""
    local phase=""
    local status=""

    # 引数解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --session)
                session_id="$2"
                shift 2
                ;;
            --phase)
                phase="$2"
                shift 2
                ;;
            --status)
                status="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done

    # バリデーション
    validate_phase "$phase" || return 1
    validate_status "$status" || return 1

    local session_dir
    session_dir=$(get_session_dir "$session_id") || return 1

    # ロック取得
    acquire_lock "$session_dir"
    trap "release_lock '$session_dir'" EXIT

    local state_file="${session_dir}/state.json"
    if [[ ! -f "$state_file" ]]; then
        echo "Error: session state not found" >&2
        return 1
    fi

    local now
    now=$(get_timestamp)

    # 更新
    local updated_json
    updated_json=$(jq \
        --arg now "$now" \
        --arg phase "$phase" \
        --arg status "$status" \
        '.updated_at = $now |
         if $phase != "" then .current_phase = $phase else . end |
         if $status != "" then .status = $status else . end |
         if $phase != "" and $status != "" then
             .phases[$phase].status = $status |
             if $status == "in_progress" and .phases[$phase].started_at == null then
                 .phases[$phase].started_at = $now
             elif $status == "completed" then
                 .phases[$phase].completed_at = $now
             else .
             end
         else .
         end' "$state_file")

    # 原子的書き込み
    local tmp_file="${state_file}.tmp"
    echo "$updated_json" > "$tmp_file"
    mv "$tmp_file" "$state_file"

    echo "Session updated"
}

# 相談を追加
add_consultation() {
    local session_id=""
    local phase=""
    local prompt_file=""
    local response_file=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --session)
                session_id="$2"
                shift 2
                ;;
            --phase)
                phase="$2"
                shift 2
                ;;
            --prompt-file)
                prompt_file="$2"
                shift 2
                ;;
            --response-file)
                response_file="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done

    # バリデーション
    validate_phase "$phase" || return 1

    local session_dir
    session_dir=$(get_session_dir "$session_id") || return 1

    acquire_lock "$session_dir"
    trap "release_lock '$session_dir'" EXIT

    local state_file="${session_dir}/state.json"
    local now
    now=$(get_timestamp)

    local consultation_id
    consultation_id="cons-$(date +%s)-$RANDOM"

    local updated_json
    updated_json=$(jq \
        --arg now "$now" \
        --arg phase "$phase" \
        --arg id "$consultation_id" \
        --arg prompt_file "$prompt_file" \
        --arg response_file "$response_file" \
        '.updated_at = $now |
         .phases[$phase].consultations += [{
             id: $id,
             timestamp: $now,
             prompt_file: $prompt_file,
             response_file: $response_file
         }]' "$state_file")

    local tmp_file="${state_file}.tmp"
    echo "$updated_json" > "$tmp_file"
    mv "$tmp_file" "$state_file"

    echo "$consultation_id"
}

# 双方向メッセージを追加（Codex ↔ Claude）
add_bidirectional_message() {
    local session_id=""
    local direction=""
    local message_type=""
    local content=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --session)
                session_id="$2"
                shift 2
                ;;
            --direction)
                direction="$2"
                shift 2
                ;;
            --type)
                message_type="$2"
                shift 2
                ;;
            --content)
                content="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done

    # バリデーション
    if [[ ! "$direction" =~ ^(codex_to_claude|claude_to_codex)$ ]]; then
        echo "Error: direction must be 'codex_to_claude' or 'claude_to_codex'" >&2
        return 1
    fi

    if [[ -z "$message_type" ]]; then
        message_type="CHAT"
    fi

    local session_dir
    session_dir=$(get_session_dir "$session_id") || return 1

    acquire_lock "$session_dir"
    trap "release_lock '$session_dir'" EXIT

    local state_file="${session_dir}/state.json"
    local now
    now=$(get_timestamp)

    local msg_id
    msg_id="msg-$(date +%s)-$RANDOM"

    # bidirectional_messages 配列が存在しない場合は作成
    local updated_json
    updated_json=$(jq \
        --arg now "$now" \
        --arg id "$msg_id" \
        --arg direction "$direction" \
        --arg type "$message_type" \
        --arg content "$content" \
        '.updated_at = $now |
         .bidirectional_messages = ((.bidirectional_messages // []) + [{
             id: $id,
             direction: $direction,
             type: $type,
             content: $content,
             timestamp: $now,
             status: "delivered"
         }])' "$state_file")

    local tmp_file="${state_file}.tmp"
    echo "$updated_json" > "$tmp_file"
    mv "$tmp_file" "$state_file"

    echo "$msg_id"
}

# 双方向メッセージ履歴を取得
get_bidirectional_messages() {
    local session_id="${1:-}"
    local limit="${2:-50}"

    local session_dir
    session_dir=$(get_session_dir "$session_id") || return 1

    local state_file="${session_dir}/state.json"

    if [[ ! -f "$state_file" ]]; then
        echo "[]"
        return 0
    fi

    jq --argjson limit "$limit" \
        '(.bidirectional_messages // []) | .[-$limit:]' "$state_file"
}

# アクティブセッション一覧
list_active() {
    if [[ ! -d "$SESSIONS_DIR" ]]; then
        echo "[]"
        return 0
    fi

    local sessions=()
    for dir in "$SESSIONS_DIR"/codex-collab-*; do
        if [[ -d "$dir" ]] && [[ -f "$dir/state.json" ]]; then
            local status
            status=$(jq -r '.status' "$dir/state.json" 2>/dev/null || echo "unknown")
            if [[ "$status" == "initializing" || "$status" == "in_progress" || "$status" == "paused" ]]; then
                local session_id
                session_id=$(basename "$dir")
                sessions+=("\"$session_id\"")
            fi
        fi
    done

    if [[ ${#sessions[@]} -eq 0 ]]; then
        echo "[]"
    else
        local json_array
        json_array=$(printf "%s," "${sessions[@]}")
        echo "[${json_array%,}]"
    fi
}

# ISO 8601 日時をタイムスタンプに変換（クロスプラットフォーム）
parse_iso_timestamp() {
    local iso_date="$1"
    local ts

    # macOS の date -j -f を試す
    ts=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$iso_date" +%s 2>/dev/null) && echo "$ts" && return 0

    # GNU date (Linux) の date -d を試す
    ts=$(date -d "$iso_date" +%s 2>/dev/null) && echo "$ts" && return 0

    # gdate (macOS with coreutils) を試す
    ts=$(gdate -d "$iso_date" +%s 2>/dev/null) && echo "$ts" && return 0

    # フォールバック: 正規表現でパース
    if [[ "$iso_date" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})Z$ ]]; then
        # Python を使用（最終手段）
        ts=$(python3 -c "import datetime; print(int(datetime.datetime.strptime('$iso_date', '%Y-%m-%dT%H:%M:%SZ').timestamp()))" 2>/dev/null) && echo "$ts" && return 0
    fi

    echo "0"
    return 1
}

# 古いセッションのクリーンアップ
cleanup_sessions() {
    local older_than="${1:-7d}"

    # 日数を秒に変換
    local days
    days=$(echo "$older_than" | sed 's/d$//')
    local seconds=$((days * 86400))
    local cutoff
    cutoff=$(($(date +%s) - seconds))

    local cleaned=0
    for dir in "$SESSIONS_DIR"/codex-collab-*; do
        if [[ -d "$dir" ]] && [[ -f "$dir/state.json" ]]; then
            local status
            status=$(jq -r '.status' "$dir/state.json" 2>/dev/null || echo "unknown")
            if [[ "$status" == "completed" || "$status" == "failed" ]]; then
                local created
                created=$(jq -r '.created_at' "$dir/state.json" 2>/dev/null || echo "")
                if [[ -n "$created" ]]; then
                    local created_ts
                    created_ts=$(parse_iso_timestamp "$created")
                    # パース失敗時（0）は誤削除を防ぐためスキップ
                    if [[ "$created_ts" -gt 0 ]] && [[ "$created_ts" -lt "$cutoff" ]]; then
                        rm -rf "$dir"
                        ((cleaned++))
                    fi
                fi
            fi
        fi
    done

    echo "Cleaned $cleaned sessions"
}

# ヘルプ表示
show_help() {
    cat << 'EOF'
Usage: session_state.sh <command> [options]

Commands:
  init                           新規セッション初期化
    --feature <name>             機能名
    --project <name>             プロジェクト名
    --tmux-session <name>        tmux セッション名
    --working-dir <path>         作業ディレクトリ

  get [session_id]               セッション状態取得

  update                         セッション状態更新
    --session <id>               セッション ID（省略時は現在のセッション）
    --phase <phase>              フェーズ名
    --status <status>            ステータス

  add-consultation               相談を追加
    --session <id>               セッション ID
    --phase <phase>              フェーズ名
    --prompt-file <path>         プロンプトファイル
    --response-file <path>       レスポンスファイル

  add-message                    双方向メッセージを追加
    --session <id>               セッション ID
    --direction <dir>            方向 (codex_to_claude|claude_to_codex)
    --type <type>                メッセージタイプ (QUESTION|SUGGESTION|ALERT|CHAT)
    --content <text>             メッセージ内容

  get-messages [session_id]      双方向メッセージ履歴を取得
    [limit]                      取得件数（デフォルト: 50）

  list-active                    アクティブセッション一覧

  cleanup [--older-than <days>]  古いセッションをクリーンアップ

Examples:
  ./session_state.sh init --feature "user-auth" --project "my-app"
  ./session_state.sh get
  ./session_state.sh update --phase DESIGN --status in_progress
  ./session_state.sh list-active
  ./session_state.sh cleanup --older-than 7d
EOF
}

# メイン処理
main() {
    local command="${1:-help}"
    shift || true

    case "$command" in
        init)
            init_session "$@"
            ;;
        get)
            get_session "$@"
            ;;
        update)
            update_session "$@"
            ;;
        add-consultation)
            add_consultation "$@"
            ;;
        add-message)
            add_bidirectional_message "$@"
            ;;
        get-messages)
            get_bidirectional_messages "$@"
            ;;
        list-active)
            list_active
            ;;
        cleanup)
            local older_than="7d"
            if [[ "${1:-}" == "--older-than" ]]; then
                older_than="${2:-7d}"
            fi
            cleanup_sessions "$older_than"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo "Unknown command: $command" >&2
            show_help
            return 1
            ;;
    esac
}

main "$@"
