#!/bin/bash
# Codex を直接実行（tmux なしでも動作）
# Context7検証: codex exec コマンドを使用

set -euo pipefail

show_help() {
    cat << 'EOF'
Usage: invoke_codex.sh <prompt_file> <output_file> [options]

Arguments:
  prompt_file   Path to file containing the prompt
  output_file   Path to save Codex response

Options:
  --full-auto   Enable full auto mode (default: true)
  --sandbox     Sandbox mode: none, network-only, workspace-write (default: workspace-write)
  --timeout     Timeout in seconds (default: 300)

Description:
  Invokes Codex CLI in non-interactive mode for pair programming.
  Uses codex exec for direct prompt execution.

Examples:
  ./invoke_codex.sh /tmp/prompt.txt /tmp/output.txt
  ./invoke_codex.sh /tmp/prompt.txt /tmp/output.txt --timeout 600
EOF
}

# デフォルト値
FULL_AUTO=true
SANDBOX="workspace-write"
TIMEOUT=300

# 引数解析
if [[ $# -lt 2 ]]; then
    show_help
    exit 1
fi

PROMPT_FILE="$1"
OUTPUT_FILE="$2"
shift 2

# オプション解析
while [[ $# -gt 0 ]]; do
    case "$1" in
        --full-auto)
            FULL_AUTO=true
            shift
            ;;
        --no-full-auto)
            FULL_AUTO=false
            shift
            ;;
        --sandbox)
            SANDBOX="$2"
            shift 2
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            show_help
            exit 1
            ;;
    esac
done

# プロンプトファイル存在確認
if [[ ! -f "$PROMPT_FILE" ]]; then
    echo "Error: Prompt file not found: $PROMPT_FILE" >&2
    exit 1
fi

# 出力ディレクトリ作成
mkdir -p "$(dirname "$OUTPUT_FILE")"

# プロンプト読み込み
PROMPT=$(cat "$PROMPT_FILE")

echo "Invoking Codex..." >&2
echo "  Prompt file: $PROMPT_FILE" >&2
echo "  Output file: $OUTPUT_FILE" >&2
echo "  Full auto: $FULL_AUTO" >&2
echo "  Sandbox: $SANDBOX" >&2
echo "  Timeout: ${TIMEOUT}s" >&2

# Codex CLI オプション構築
CODEX_OPTS=()

if [[ "$FULL_AUTO" == "true" ]]; then
    CODEX_OPTS+=("--full-auto")
fi

CODEX_OPTS+=("--sandbox" "$SANDBOX")

# タイムアウト付きで実行
if timeout "$TIMEOUT" codex exec "${CODEX_OPTS[@]}" "$PROMPT" > "$OUTPUT_FILE" 2>&1; then
    echo "Codex execution completed successfully" >&2
    echo "Output saved to: $OUTPUT_FILE" >&2
    exit 0
else
    EXIT_CODE=$?
    if [[ $EXIT_CODE -eq 124 ]]; then
        echo "Codex execution timed out after ${TIMEOUT}s" >&2
    else
        echo "Codex execution failed with exit code: $EXIT_CODE" >&2
    fi
    if [[ -f "$OUTPUT_FILE" ]]; then
        echo "Partial output:" >&2
        head -50 "$OUTPUT_FILE" >&2
    fi
    exit $EXIT_CODE
fi
