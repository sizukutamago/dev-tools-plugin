#!/bin/bash
# lib/retry.sh - 指数バックオフ付きリトライロジック
#
# 使用例:
#   ./lib/retry.sh --max-attempts 3 --initial-delay 30 -- command args
#   ./lib/retry.sh check-rate-limit /tmp/error_output.txt

set -euo pipefail

# デフォルト設定
DEFAULT_MAX_ATTEMPTS=3
DEFAULT_INITIAL_DELAY=30
DEFAULT_MAX_DELAY=300
DEFAULT_BACKOFF_MULTIPLIER=2

# レート制限パターン
readonly RATE_LIMIT_PATTERNS=(
    "rate limit"
    "Rate limit"
    "RATE_LIMIT"
    "Too many requests"
    "429"
    "quota exceeded"
    "throttl"
)

# レート制限チェック
check_rate_limit() {
    local file="${1:-}"

    if [[ -z "$file" ]]; then
        echo "Error: file path required" >&2
        return 1
    fi

    if [[ ! -f "$file" ]]; then
        echo "false"
        return 0
    fi

    local content
    content=$(cat "$file" 2>/dev/null || echo "")

    for pattern in "${RATE_LIMIT_PATTERNS[@]}"; do
        if echo "$content" | grep -qi "$pattern"; then
            echo "true"
            return 0
        fi
    done

    echo "false"
    return 0
}

# 遅延計算（指数バックオフ + ジッター）
calculate_delay() {
    local attempt="$1"
    local initial_delay="$2"
    local max_delay="$3"
    local multiplier="$4"

    # 指数計算: initial_delay * multiplier^(attempt-1)
    local delay
    delay=$(echo "$initial_delay * ($multiplier ^ ($attempt - 1))" | bc 2>/dev/null || echo "$initial_delay")

    # 整数に変換
    delay=${delay%.*}

    # ジッター追加（±10%）
    local jitter=$((delay / 10))
    local random_jitter=$((RANDOM % (jitter * 2 + 1) - jitter))
    delay=$((delay + random_jitter))

    # 最大値制限
    if [[ "$delay" -gt "$max_delay" ]]; then
        delay="$max_delay"
    fi

    # 最小値保証
    if [[ "$delay" -lt 1 ]]; then
        delay=1
    fi

    echo "$delay"
}

# リトライ実行
execute_with_retry() {
    local max_attempts="$DEFAULT_MAX_ATTEMPTS"
    local initial_delay="$DEFAULT_INITIAL_DELAY"
    local max_delay="$DEFAULT_MAX_DELAY"
    local multiplier="$DEFAULT_BACKOFF_MULTIPLIER"
    local verbose=false

    # 引数解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --max-attempts)
                max_attempts="$2"
                shift 2
                ;;
            --initial-delay)
                initial_delay="$2"
                shift 2
                ;;
            --max-delay)
                max_delay="$2"
                shift 2
                ;;
            --multiplier)
                multiplier="$2"
                shift 2
                ;;
            --verbose|-v)
                verbose=true
                shift
                ;;
            --)
                shift
                break
                ;;
            *)
                break
                ;;
        esac
    done

    if [[ $# -eq 0 ]]; then
        echo "Error: command required" >&2
        return 1
    fi

    local command=("$@")
    local attempt=1
    local exit_code=0
    local output_file
    output_file=$(mktemp)

    while [[ "$attempt" -le "$max_attempts" ]]; do
        if [[ "$verbose" == true ]]; then
            echo "Attempt $attempt/$max_attempts: ${command[*]}" >&2
        fi

        # コマンド実行
        if "${command[@]}" > "$output_file" 2>&1; then
            cat "$output_file"
            rm -f "$output_file"
            return 0
        else
            exit_code=$?
        fi

        # 最後の試行なら終了
        if [[ "$attempt" -ge "$max_attempts" ]]; then
            if [[ "$verbose" == true ]]; then
                echo "All $max_attempts attempts failed" >&2
            fi
            cat "$output_file"
            rm -f "$output_file"
            return "$exit_code"
        fi

        # レート制限チェック
        local is_rate_limited
        is_rate_limited=$(check_rate_limit "$output_file")

        local delay
        if [[ "$is_rate_limited" == "true" ]]; then
            # レート制限時は長めの遅延
            delay=$((initial_delay * 2))
            if [[ "$verbose" == true ]]; then
                echo "Rate limit detected, using extended delay" >&2
            fi
        else
            delay=$(calculate_delay "$attempt" "$initial_delay" "$max_delay" "$multiplier")
        fi

        if [[ "$verbose" == true ]]; then
            echo "Waiting ${delay}s before retry..." >&2
        fi

        sleep "$delay"
        ((attempt++))
    done

    rm -f "$output_file"
    return "$exit_code"
}

# ヘルプ表示
show_help() {
    cat << 'EOF'
Usage: retry.sh [options] -- command [args...]
       retry.sh check-rate-limit <file>

Options:
  --max-attempts <n>      最大試行回数（デフォルト: 3）
  --initial-delay <sec>   初期遅延秒数（デフォルト: 30）
  --max-delay <sec>       最大遅延秒数（デフォルト: 300）
  --multiplier <n>        バックオフ乗数（デフォルト: 2）
  --verbose, -v           詳細出力

Commands:
  check-rate-limit <file>  ファイル内容からレート制限を検出

Examples:
  # コマンドをリトライ実行
  ./retry.sh --max-attempts 3 --initial-delay 30 -- codex exec "prompt"

  # レート制限チェック
  ./retry.sh check-rate-limit /tmp/error.txt
  # Output: true または false

  # 詳細モードで実行
  ./retry.sh -v --max-attempts 5 -- ./some_command.sh

Backoff Formula:
  delay = initial_delay * multiplier^(attempt-1) + jitter
  jitter = random(±10% of delay)
  delay = min(delay, max_delay)
EOF
}

# メイン処理
main() {
    local command="${1:-help}"

    case "$command" in
        check-rate-limit)
            shift
            check_rate_limit "$@"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            # リトライ実行（最初の引数がオプションまたはコマンド）
            execute_with_retry "$@"
            ;;
    esac
}

main "$@"
