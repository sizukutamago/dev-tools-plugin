#!/bin/bash
# Codex出力の取得スクリプト
# Context7検証: codex exec は完了時に自動終了するため、ファイル監視で十分

set -euo pipefail

show_help() {
    cat << 'EOF'
Usage: capture_codex_output.sh <output_file> [timeout_seconds]

Arguments:
  output_file     Path to the output file to monitor
  timeout_seconds (optional) Maximum wait time in seconds (default: 120)

Description:
  Waits for Codex output file to be complete and returns its contents.
  Monitors file size changes to detect completion.

Examples:
  ./capture_codex_output.sh /tmp/codex_output.txt
  ./capture_codex_output.sh /tmp/codex_output.txt 180
EOF
}

if [[ $# -lt 1 ]]; then
    show_help
    exit 1
fi

OUTPUT_FILE="$1"
TIMEOUT="${2:-120}"
STABILITY_WAIT=2  # ファイルサイズが安定していることを確認する待機秒数

echo "Waiting for Codex output: $OUTPUT_FILE (timeout: ${TIMEOUT}s)" >&2

start_time=$(date +%s)

while true; do
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))

    # タイムアウトチェック
    if [[ $elapsed -ge $TIMEOUT ]]; then
        echo "Timeout waiting for Codex response after ${TIMEOUT}s" >&2
        if [[ -f "$OUTPUT_FILE" ]]; then
            echo "Partial output:" >&2
            cat "$OUTPUT_FILE" >&2
        fi
        exit 1
    fi

    # ファイル存在・サイズチェック
    if [[ -f "$OUTPUT_FILE" ]] && [[ -s "$OUTPUT_FILE" ]]; then
        # ファイルサイズ取得（macOS/Linux互換）
        if [[ "$(uname)" == "Darwin" ]]; then
            SIZE1=$(stat -f%z "$OUTPUT_FILE" 2>/dev/null || echo "0")
        else
            SIZE1=$(stat -c%s "$OUTPUT_FILE" 2>/dev/null || echo "0")
        fi

        # 安定性確認のため待機
        sleep $STABILITY_WAIT

        # 再度サイズ取得
        if [[ "$(uname)" == "Darwin" ]]; then
            SIZE2=$(stat -f%z "$OUTPUT_FILE" 2>/dev/null || echo "0")
        else
            SIZE2=$(stat -c%s "$OUTPUT_FILE" 2>/dev/null || echo "0")
        fi

        # サイズが安定していれば完了と判断
        if [[ "$SIZE1" == "$SIZE2" ]] && [[ "$SIZE1" != "0" ]]; then
            echo "Output captured successfully (${SIZE1} bytes)" >&2
            cat "$OUTPUT_FILE"
            exit 0
        fi
    fi

    # 進捗表示
    if [[ $((elapsed % 10)) -eq 0 ]] && [[ $elapsed -gt 0 ]]; then
        echo "Still waiting... (${elapsed}s elapsed)" >&2
    fi

    sleep 1
done
