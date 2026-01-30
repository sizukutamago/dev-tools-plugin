#!/bin/bash
# Codexへのプロンプト送信スクリプト
# Context7検証: codex exec を使用（-p は profile フラグのため不可）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    cat << 'EOF'
Usage: send_to_codex.sh [session] <prompt_file> <output_file>

Arguments:
  session      (optional) tmux session name for visual output
  prompt_file  Path to file containing the prompt
  output_file  Path to save Codex response

Examples:
  # tmuxセッション内で実行（視覚的確認用）
  ./send_to_codex.sh $SESSION /tmp/prompt.txt /tmp/output.txt

  # 直接実行（バックグラウンド用）
  ./send_to_codex.sh /tmp/prompt.txt /tmp/output.txt
EOF
}

# 引数解析
if [[ $# -lt 2 ]]; then
    show_help
    exit 1
fi

# 引数が3つの場合はセッション指定あり
if [[ $# -eq 3 ]]; then
    SESSION="$1"
    PROMPT_FILE="$2"
    OUTPUT_FILE="$3"
else
    SESSION=""
    PROMPT_FILE="$1"
    OUTPUT_FILE="$2"
fi

# プロンプトファイル存在確認
if [[ ! -f "$PROMPT_FILE" ]]; then
    echo "Error: Prompt file not found: $PROMPT_FILE" >&2
    exit 1
fi

# 出力ディレクトリ作成
mkdir -p "$(dirname "$OUTPUT_FILE")"

# プロンプト読み込み
PROMPT=$(cat "$PROMPT_FILE")

if [[ -n "$SESSION" ]]; then
    # 方法1: tmux ペインで実行（視覚的確認用）
    # Codexペイン(1)にコマンド送信
    "$SCRIPT_DIR/tmux_manager.sh" send "$SESSION" 1 "codex exec \"\$(cat '$PROMPT_FILE')\" 2>&1 | tee '$OUTPUT_FILE'"

    echo "Command sent to tmux session: $SESSION"
    echo "Output will be saved to: $OUTPUT_FILE"
else
    # 方法2: 直接実行（バックグラウンド用）
    echo "Executing Codex directly..."

    # codex exec で非インタラクティブ実行
    if codex exec "$PROMPT" > "$OUTPUT_FILE" 2>&1; then
        echo "Codex execution completed successfully"
        echo "Output saved to: $OUTPUT_FILE"
    else
        echo "Codex execution failed" >&2
        cat "$OUTPUT_FILE" >&2
        exit 1
    fi
fi
