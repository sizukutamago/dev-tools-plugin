#!/bin/bash
#
# hook_router.sh - Web Requirements Hook Router
#
# Write/Edit ツールの実行前後で呼び出され、
# docs/requirements/ 配下の許可されたパスのみ編集を許可する。
#
# 入力: stdin から JSON（tool_input.file_path を含む）
# 出力: stdout に JSON（permissionDecision）、ログは stderr
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 許可されたパスパターン（docs/requirements/ 配下で編集可能なパス）
ALLOWED_PATTERNS=(
    "docs/requirements/user-stories.md"
    "docs/requirements/.work/*"
)

# ログ関数（stderr に出力）
log() {
    echo "[hook_router] $*" >&2
}

# stdin から JSON を読んで file_path を抽出
get_file_path_from_stdin() {
    local json
    json=$(cat)

    # jq があれば使用、なければ Python（printf で安全に渡す）
    if command -v jq &>/dev/null; then
        printf '%s' "$json" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo ""
    elif command -v python3 &>/dev/null; then
        printf '%s' "$json" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('tool_input', {}).get('file_path', ''))" 2>/dev/null || echo ""
    else
        log "Warning: neither jq nor python3 available"
        echo ""
    fi
}

# パスが docs/requirements/ 配下かチェック
is_in_docs_requirements() {
    local path="$1"
    [[ "$path" == *"docs/requirements/"* ]] || [[ "$path" == "docs/requirements/"* ]]
}

# パスが許可されているかチェック
is_allowed_path() {
    local path="$1"

    # 絶対パスから相対パスを抽出（docs/requirements/ を含む場合）
    if [[ "$path" == /* ]]; then
        local rel_path="${path##*/docs/requirements/}"
        if [[ "$rel_path" != "$path" ]]; then
            path="docs/requirements/$rel_path"
        fi
    fi

    # 中間成果物は常に許可（docs/requirements/.work/ 配下のみ）
    if [[ "$path" == docs/requirements/.work/* ]] || [[ "$path" == *"docs/requirements/.work/"* ]]; then
        return 0
    fi

    # 許可パターンとマッチするかチェック
    for pattern in "${ALLOWED_PATTERNS[@]}"; do
        if [[ "$path" == $pattern ]]; then
            return 0
        fi
    done

    return 1
}

# JSON 出力: 許可
output_allow() {
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
}

# JSON 出力: 拒否
output_deny() {
    local reason="$1"
    cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"$reason"}}
EOF
}

# Pre-hook: ツール実行前のチェック
pre_hook() {
    local file_path
    file_path=$(get_file_path_from_stdin)

    if [[ -z "$file_path" ]]; then
        log "Warning: file_path not provided, allowing"
        output_allow
        exit 0
    fi

    # docs/requirements/ 配下でなければ常に許可（他スキルへの影響を避ける）
    if ! is_in_docs_requirements "$file_path"; then
        log "Outside docs/requirements/, allowing: $file_path"
        output_allow
        exit 0
    fi

    # docs/requirements/ 配下の場合、許可リストをチェック
    if is_allowed_path "$file_path"; then
        log "Allowed: $file_path"
        output_allow
        exit 0
    else
        log "Blocked: $file_path is not in allowed paths"
        output_deny "web-requirements: このパスへの書き込みは許可されていません。許可: docs/requirements/user-stories.md, docs/requirements/.work/*"
        exit 0  # JSON で deny を返すので exit 0
    fi
}

# Post-hook: ツール実行後のバリデーション
post_hook() {
    local file_path
    file_path=$(get_file_path_from_stdin)

    if [[ -z "$file_path" ]]; then
        exit 0
    fi

    # user-stories.md が更新された場合はバリデーション実行
    if [[ "$file_path" == *"user-stories.md" ]]; then
        log "Running validation on $file_path"

        if python3 "$SCRIPT_DIR/validate_user_stories.py" "$file_path" --json >&2; then
            log "Validation passed"
        else
            log "Validation failed (non-blocking)"
            # Post-hook では警告のみ、ブロックはしない
        fi
    fi

    exit 0
}

# メイン処理
main() {
    local mode="${1:-}"

    case "$mode" in
        pre)
            pre_hook
            ;;
        post)
            post_hook
            ;;
        *)
            echo "Usage: $0 {pre|post}" >&2
            exit 1
            ;;
    esac
}

main "$@"
