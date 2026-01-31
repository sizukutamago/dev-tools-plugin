#!/bin/bash
# scripts/collab.sh - codex-collab 統合エントリポイント
# 全ての codex-collab 操作をこのスクリプト経由で実行
#
# 使用例:
#   ./collab.sh init --feature "user-auth" --project "my-app"
#   ./collab.sh send /tmp/prompt.txt
#   ./collab.sh status
#   ./collab.sh end

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"
DEPRECATED_DIR="${SCRIPT_DIR}/../deprecated"

# 色定義
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# デフォルト設定
DEFAULT_TIMEOUT=180
SESSIONS_DIR="${CODEX_COLLAB_SESSIONS_DIR:-.codex-collab/sessions}"

# ヘルプ表示
show_help() {
    cat << 'EOF'
Usage: collab.sh <command> [options]

Commands:
  init                     新規セッション開始
    --feature <name>       機能名
    --project <name>       プロジェクト名
    --tmux-session <name>  tmux セッション名

  send <prompt_file>       Codex にプロンプト送信
    --phase <phase>        フェーズ指定（REQUIREMENTS, DESIGN, IMPLEMENTATION, REVIEW）
    --timeout <sec>        タイムアウト秒数
    --output <file>        出力ファイル

  recv                     最後のレスポンスを取得

  status                   現在のセッション状態を表示

  resume                   中断したセッションを再開

  end                      セッション終了

  interactive              インタラクティブモード開始

  watch [--stop]           キュー監視デーモンの開始/停止
    --status               監視ステータス確認
    --stop                 監視停止

  check-messages           保留中メッセージ一覧を表示

  message <text>           Claude に直接メッセージ送信
    --type TYPE            メッセージタイプ (QUESTION|SUGGESTION|ALERT|CHAT)

Examples:
  # 新規セッション開始
  ./collab.sh init --feature "user-auth" --project "my-app"

  # 設計相談
  ./collab.sh send /tmp/design_prompt.txt --phase DESIGN

  # ステータス確認
  ./collab.sh status

  # セッション終了
  ./collab.sh end
EOF
}

# エラー出力
error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

# 情報出力
info() {
    echo -e "${CYAN}$1${NC}"
}

# 成功出力
success() {
    echo -e "${GREEN}$1${NC}"
}

# 警告出力
warn() {
    echo -e "${YELLOW}$1${NC}"
}

# 前提条件チェック
check_prerequisites() {
    local missing=()

    if ! command -v codex &> /dev/null; then
        missing+=("codex")
    fi

    if ! command -v jq &> /dev/null; then
        missing+=("jq")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing prerequisites: ${missing[*]}"
        echo "Install them with:"
        echo "  npm install -g @openai/codex"
        echo "  brew install jq"
        return 1
    fi

    return 0
}

# セッション初期化
cmd_init() {
    local feature=""
    local project=""
    local tmux_session=""

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
            *)
                error "Unknown option: $1"
                return 1
                ;;
        esac
    done

    check_prerequisites || return 1

    # tmux セッション自動検出
    if [[ -z "$tmux_session" ]] && [[ -n "${TMUX:-}" ]]; then
        tmux_session=$("${SCRIPT_DIR}/tmux_manager.sh" current 2>/dev/null || echo "")
    fi

    info "Initializing codex-collab session..."

    # セッション状態初期化
    local session_id
    session_id=$("${LIB_DIR}/session_state.sh" init \
        --feature "$feature" \
        --project "$project" \
        --tmux-session "$tmux_session")

    success "Session created: $session_id"
    echo ""
    echo "Feature: $feature"
    echo "Project: $project"
    [[ -n "$tmux_session" ]] && echo "tmux: $tmux_session"
    echo ""
    echo "Use './collab.sh send <prompt_file> --phase <phase>' to consult with Codex"
}

# Codex にプロンプト送信
cmd_send() {
    local prompt_file=""
    local phase=""
    local timeout="$DEFAULT_TIMEOUT"
    local output_file=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --phase)
                phase="$2"
                shift 2
                ;;
            --timeout)
                timeout="$2"
                shift 2
                ;;
            --output)
                output_file="$2"
                shift 2
                ;;
            *)
                if [[ -z "$prompt_file" ]]; then
                    prompt_file="$1"
                else
                    error "Unknown option: $1"
                    return 1
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$prompt_file" ]]; then
        error "prompt_file required"
        return 1
    fi

    if [[ ! -f "$prompt_file" ]]; then
        error "File not found: $prompt_file"
        return 1
    fi

    # 出力ファイル設定
    if [[ -z "$output_file" ]]; then
        output_file=$(mktemp)
    fi

    info "Sending prompt to Codex..."
    echo "  Prompt: $prompt_file"
    echo "  Phase: ${phase:-auto}"
    echo "  Timeout: ${timeout}s"

    # プロトコル検証（オプション）
    if [[ -n "$phase" ]] && [[ -f "${LIB_DIR}/protocol.sh" ]]; then
        local validation
        validation=$("${LIB_DIR}/protocol.sh" validate-request "$phase" "$prompt_file" 2>/dev/null || echo '{"valid":false}')
        if ! echo "$validation" | jq -e '.valid' > /dev/null 2>&1; then
            warn "Prompt does not contain expected [$phase] marker"
        fi
    fi

    # tmux インタラクティブ方式で Codex に送信
    # ⚠️ codex exec は禁止（MCP サーバー起動オーバーヘッドのため）
    local tmux_session
    tmux_session=$("${SCRIPT_DIR}/tmux_manager.sh" current 2>/dev/null || echo "")

    if [[ -z "$tmux_session" ]]; then
        error "No active tmux session. Run 'collab.sh interactive' first."
        return 1
    fi

    # Codex ペイン（pane 1）にプロンプトを送信
    local prompt_content
    prompt_content=$(cat "$prompt_file")

    # 古いレスポンスマーカー誤検知を防ぐため、tmux 履歴をクリア
    # clear コマンドを送ると Codex への入力になるため、tmux clear-history を使用
    tmux clear-history -t "${tmux_session}:0.1" 2>/dev/null || true

    if ! "${SCRIPT_DIR}/tmux_manager.sh" send "$tmux_session" 1 "$prompt_content"; then
        error "Failed to send prompt to Codex pane"
        return 1
    fi

    info "Waiting for Codex response (timeout: ${timeout}s)..."

    # ポーリングで応答を待機
    local elapsed=0
    local poll_interval=5
    local last_output=""
    local stable_count=0

    while [[ $elapsed -lt $timeout ]]; do
        sleep "$poll_interval"
        elapsed=$((elapsed + poll_interval))

        local current_output
        current_output=$("${SCRIPT_DIR}/tmux_manager.sh" capture "$tmux_session" 1 200 2>/dev/null || echo "")

        # [RESPONSE:*] マーカーを検出したら完了
        if echo "$current_output" | grep -qE '\[RESPONSE:(REQUIREMENTS|DESIGN|IMPLEMENTATION|REVIEW)\]'; then
            echo "$current_output" > "$output_file"
            break
        fi

        # 出力が安定したら（3回連続で同じ）完了とみなす
        if [[ "$current_output" == "$last_output" ]]; then
            ((stable_count++))
            if [[ $stable_count -ge 3 ]]; then
                echo "$current_output" > "$output_file"
                break
            fi
        else
            stable_count=0
            last_output="$current_output"
        fi

        echo -n "."
    done
    echo ""

    if [[ $elapsed -ge $timeout ]]; then
        warn "Timeout reached. Capturing current output..."
        "${SCRIPT_DIR}/tmux_manager.sh" capture "$tmux_session" 1 500 > "$output_file" 2>/dev/null || true
    fi

    if [[ ! -s "$output_file" ]]; then
        error "No response received from Codex"
        return 1
    fi

    success "Response received"

    # セッション状態更新
    if [[ -n "$phase" ]] && [[ -f "${LIB_DIR}/session_state.sh" ]]; then
        "${LIB_DIR}/session_state.sh" add-consultation \
            --phase "$phase" \
            --prompt-file "$prompt_file" \
            --response-file "$output_file" > /dev/null 2>&1 || true
    fi

    # レスポンス解析
    if [[ -f "${SCRIPT_DIR}/parse_response.sh" ]]; then
        info "Parsed response:"
        "${SCRIPT_DIR}/parse_response.sh" "$output_file" | jq .
    else
        cat "$output_file"
    fi

    echo ""
    echo "Raw output saved to: $output_file"
}

# 現在のセッション状態表示
cmd_status() {
    if ! [[ -f "${LIB_DIR}/session_state.sh" ]]; then
        error "session_state.sh not found"
        return 1
    fi

    local state
    state=$("${LIB_DIR}/session_state.sh" get 2>/dev/null) || {
        warn "No active session"
        return 0
    }

    info "Current Session Status"
    echo ""
    echo "$state" | jq '{
        session_id,
        status,
        current_phase,
        feature,
        project,
        phases: .phases | to_entries | map({(.key): .value.status}) | add
    }'
}

# セッション再開
cmd_resume() {
    if ! [[ -f "${LIB_DIR}/session_state.sh" ]]; then
        error "session_state.sh not found"
        return 1
    fi

    local active_sessions
    active_sessions=$("${LIB_DIR}/session_state.sh" list-active 2>/dev/null)

    if [[ "$active_sessions" == "[]" ]]; then
        warn "No active sessions to resume"
        return 0
    fi

    info "Active sessions:"
    echo "$active_sessions" | jq -r '.[]'

    # 最新のセッションを再開
    local latest
    latest=$(echo "$active_sessions" | jq -r '.[0]')
    echo "$latest" > "${SESSIONS_DIR}/.current"

    success "Resumed session: $latest"
    cmd_status
}

# セッション終了
cmd_end() {
    if ! [[ -f "${LIB_DIR}/session_state.sh" ]]; then
        error "session_state.sh not found"
        return 1
    fi

    "${LIB_DIR}/session_state.sh" update --status completed > /dev/null 2>&1 || {
        warn "No active session to end"
        return 0
    }

    success "Session ended"
}

# インタラクティブモード
cmd_interactive() {
    local session=""

    # tmux セッション検出
    if [[ -n "${TMUX:-}" ]]; then
        session=$("${SCRIPT_DIR}/tmux_manager.sh" current 2>/dev/null || echo "")
    fi

    if [[ -z "$session" ]]; then
        error "Not in a tmux session. Use 'setup_pair_env.sh' to start one."
        return 1
    fi

    info "Starting interactive mode in tmux session: $session"

    # 右ペインで codex 起動
    "${SCRIPT_DIR}/tmux_manager.sh" send "$session" 1 "codex"

    success "Codex started in right pane"
    echo "Use the right pane to interact with Codex directly"
}

# キュー監視コマンド
cmd_watch() {
    local action="start"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --stop)
                action="stop"
                shift
                ;;
            --status)
                action="status"
                shift
                ;;
            *)
                error "Unknown option: $1"
                return 1
                ;;
        esac
    done

    case "$action" in
        start)
            "${SCRIPT_DIR}/watch_for_codex_messages.sh" --daemon
            ;;
        stop)
            "${SCRIPT_DIR}/watch_for_codex_messages.sh" --stop
            ;;
        status)
            "${SCRIPT_DIR}/watch_for_codex_messages.sh" --status
            ;;
    esac
}

# 保留メッセージ確認
cmd_check_messages() {
    if [[ ! -f "${LIB_DIR}/message_queue.sh" ]]; then
        error "message_queue.sh not found"
        return 1
    fi

    source "${LIB_DIR}/message_queue.sh"

    local count
    count=$(count_pending)

    if [[ "$count" -eq 0 ]]; then
        info "No pending messages"
    else
        info "Pending messages: $count"
        list_pending | jq .
    fi
}

# Claude に直接メッセージ送信
cmd_message() {
    local message=""
    local msg_type="CHAT"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --type)
                msg_type="$2"
                shift 2
                ;;
            *)
                if [[ -z "$message" ]]; then
                    message="$1"
                else
                    message="$message $1"
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$message" ]]; then
        error "Message is required"
        echo "Usage: collab.sh message \"your message\" --type TYPE"
        return 1
    fi

    "${SCRIPT_DIR}/send_to_claude.sh" --type "$msg_type" "$message"
}

# メイン処理
main() {
    local command="${1:-help}"
    shift || true

    case "$command" in
        init)
            cmd_init "$@"
            ;;
        send)
            cmd_send "$@"
            ;;
        recv)
            # 最後のレスポンスを取得（セッションから）
            local state
            state=$("${LIB_DIR}/session_state.sh" get 2>/dev/null) || {
                error "No active session"
                return 1
            }
            # 最後の相談のレスポンスファイルを取得
            local last_response
            last_response=$(echo "$state" | jq -r '.phases | to_entries | map(.value.consultations[-1].response_file // empty) | .[-1] // empty')
            if [[ -n "$last_response" ]] && [[ -f "$last_response" ]]; then
                cat "$last_response"
            else
                warn "No response file found"
            fi
            ;;
        status)
            cmd_status
            ;;
        resume)
            cmd_resume
            ;;
        end)
            cmd_end
            ;;
        interactive)
            cmd_interactive
            ;;
        watch)
            cmd_watch "$@"
            ;;
        check-messages)
            cmd_check_messages
            ;;
        message)
            cmd_message "$@"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            error "Unknown command: $command"
            show_help
            return 1
            ;;
    esac
}

main "$@"
