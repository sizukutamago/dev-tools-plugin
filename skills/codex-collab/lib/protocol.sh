#!/bin/bash
# lib/protocol.sh - プロトコル検証・正規化・ルーティング判定
# 純粋関数層：副作用なし、標準入出力のみ
#
# 使用例:
#   ./lib/protocol.sh detect-type /tmp/message.txt
#   ./lib/protocol.sh validate-request DESIGN /tmp/prompt.txt
#   ./lib/protocol.sh detect-callbacks /tmp/response.txt
#   ./lib/protocol.sh extract-markers /tmp/response.txt

set -euo pipefail

# 戻り値定義
readonly EXIT_OK=0
readonly EXIT_INVALID=1
readonly EXIT_UNKNOWN_TYPE=2
readonly EXIT_NO_MARKER=3

# 正規表現パターン（Codex推奨に基づく）
readonly PATTERN_CONSULT='^\[CONSULT:(REQUIREMENTS|DESIGN|IMPLEMENTATION)\]$'
readonly PATTERN_REQUEST='^\[REQUEST:(REVIEW)\]$'
readonly PATTERN_RESPONSE='^\[RESPONSE:(REQUIREMENTS|DESIGN|IMPLEMENTATION|REVIEW)\]$'
readonly PATTERN_CALLBACK='^\[CONSULT:CLAUDE:(VERIFICATION|CONTEXT)\]$'
readonly PATTERN_ANY_MARKER='^\[(CONSULT|REQUEST|RESPONSE|MESSAGE|CHAT):[A-Z_:]+\]$'

# Codex → Claude アクティブメッセージパターン
readonly PATTERN_MESSAGE_TO_CLAUDE='^\[MESSAGE:CLAUDE:(QUESTION|SUGGESTION|ALERT)\]$'
readonly PATTERN_CHAT_CODEX='^\[CHAT:CODEX\]$'

# メッセージタイプを検出
# 引数: ファイルパス
# 出力: TYPE=<type> KIND=<kind> または空
# 戻り値: 0=検出成功, 1=無効, 2=不明タイプ, 3=マーカーなし
detect_type() {
    local file="${1:-}"

    if [[ -z "$file" ]]; then
        echo "Error: file path required" >&2
        return $EXIT_INVALID
    fi

    if [[ ! -f "$file" ]]; then
        echo "Error: file not found: $file" >&2
        return $EXIT_INVALID
    fi

    # 先頭行を抽出（Codex推奨：本文中の偶発マーカー誤検知を防ぐ）
    local first_line
    first_line=$(head -1 "$file" | tr -d '\r')

    # コールバック判定（最優先）
    if [[ $first_line =~ $PATTERN_CALLBACK ]]; then
        local callback_type="${BASH_REMATCH[1]}"
        echo "TYPE=CALLBACK KIND=$callback_type"
        return $EXIT_OK
    fi

    # MESSAGE:CLAUDE 判定（Codex → Claude アクティブメッセージ）
    if [[ $first_line =~ $PATTERN_MESSAGE_TO_CLAUDE ]]; then
        local message_type="${BASH_REMATCH[1]}"
        echo "TYPE=MESSAGE KIND=$message_type"
        return $EXIT_OK
    fi

    # CHAT:CODEX 判定（自由形式チャット）
    if [[ $first_line =~ $PATTERN_CHAT_CODEX ]]; then
        echo "TYPE=CHAT KIND=CODEX"
        return $EXIT_OK
    fi

    # CONSULT 判定
    if [[ $first_line =~ $PATTERN_CONSULT ]]; then
        local kind="${BASH_REMATCH[1]}"
        echo "TYPE=CONSULT KIND=$kind"
        return $EXIT_OK
    fi

    # REQUEST 判定
    if [[ $first_line =~ $PATTERN_REQUEST ]]; then
        local kind="${BASH_REMATCH[1]}"
        echo "TYPE=REQUEST KIND=$kind"
        return $EXIT_OK
    fi

    # RESPONSE 判定
    if [[ $first_line =~ $PATTERN_RESPONSE ]]; then
        local kind="${BASH_REMATCH[1]}"
        echo "TYPE=RESPONSE KIND=$kind"
        return $EXIT_OK
    fi

    # マーカーらしきものがあるが認識できない
    if [[ $first_line =~ $PATTERN_ANY_MARKER ]]; then
        echo "Error: unknown marker format: $first_line" >&2
        return $EXIT_UNKNOWN_TYPE
    fi

    # マーカーなし
    return $EXIT_NO_MARKER
}

# リクエストの検証
# 引数: 期待するタイプ, ファイルパス
# 出力: JSON形式の検証結果
# 戻り値: 0=有効, 1=無効
validate_request() {
    local expected_kind="${1:-}"
    local file="${2:-}"

    if [[ -z "$expected_kind" || -z "$file" ]]; then
        echo '{"valid":false,"error":"missing arguments"}'
        return $EXIT_INVALID
    fi

    if [[ ! -f "$file" ]]; then
        echo '{"valid":false,"error":"file not found"}'
        return $EXIT_INVALID
    fi

    local result
    result=$(detect_type "$file" 2>/dev/null) || {
        echo '{"valid":false,"error":"no valid marker found"}'
        return $EXIT_INVALID
    }

    # 結果をパース
    local type kind
    type=$(echo "$result" | sed -n 's/TYPE=\([^ ]*\).*/\1/p')
    kind=$(echo "$result" | sed -n 's/.*KIND=\([^ ]*\)/\1/p')

    # CONSULT または REQUEST であることを確認
    if [[ "$type" != "CONSULT" && "$type" != "REQUEST" ]]; then
        echo "{\"valid\":false,\"error\":\"expected CONSULT or REQUEST, got $type\"}"
        return $EXIT_INVALID
    fi

    # 期待するタイプと一致するか確認
    if [[ "$kind" != "$expected_kind" ]]; then
        echo "{\"valid\":false,\"error\":\"expected $expected_kind, got $kind\",\"type\":\"$type\",\"kind\":\"$kind\"}"
        return $EXIT_INVALID
    fi

    local first_line
    first_line=$(head -1 "$file" | tr -d '\r')

    echo "{\"valid\":true,\"type\":\"$type\",\"kind\":\"$kind\",\"marker\":\"$first_line\"}"
    return $EXIT_OK
}

# コールバックを検出
# 引数: ファイルパス
# 出力: JSON配列形式のコールバック一覧
# 戻り値: 0=成功（0個以上検出）, 1=エラー
detect_callbacks() {
    local file="${1:-}"

    if [[ -z "$file" ]]; then
        echo "Error: file path required" >&2
        return $EXIT_INVALID
    fi

    if [[ ! -f "$file" ]]; then
        echo "Error: file not found: $file" >&2
        return $EXIT_INVALID
    fi

    local callbacks=()
    local line_num=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_num++)) || true
        line=$(echo "$line" | tr -d '\r')

        if [[ $line =~ $PATTERN_CALLBACK ]]; then
            local callback_type="${BASH_REMATCH[1]}"
            callbacks+=("{\"type\":\"$callback_type\",\"line\":$line_num}")
        fi
    done < "$file"

    # JSON配列として出力
    if [[ ${#callbacks[@]} -eq 0 ]]; then
        echo "[]"
    else
        local json_array
        json_array=$(printf "%s," "${callbacks[@]}")
        echo "[${json_array%,}]"
    fi

    return $EXIT_OK
}

# マーカーを抽出
# 引数: ファイルパス
# 出力: JSON配列形式のマーカー一覧
# 戻り値: 0=成功, 1=エラー
extract_markers() {
    local file="${1:-}"

    if [[ -z "$file" ]]; then
        echo "Error: file path required" >&2
        return $EXIT_INVALID
    fi

    if [[ ! -f "$file" ]]; then
        echo "Error: file not found: $file" >&2
        return $EXIT_INVALID
    fi

    local markers=()

    while IFS= read -r line || [[ -n "$line" ]]; do
        line=$(echo "$line" | tr -d '\r')

        # すべてのマーカーパターンをチェック
        if [[ $line =~ $PATTERN_CONSULT ]] || \
           [[ $line =~ $PATTERN_REQUEST ]] || \
           [[ $line =~ $PATTERN_RESPONSE ]] || \
           [[ $line =~ $PATTERN_CALLBACK ]] || \
           [[ $line =~ $PATTERN_MESSAGE_TO_CLAUDE ]] || \
           [[ $line =~ $PATTERN_CHAT_CODEX ]]; then
            markers+=("\"$line\"")
        fi
    done < "$file"

    # JSON配列として出力
    if [[ ${#markers[@]} -eq 0 ]]; then
        echo "[]"
    else
        local json_array
        json_array=$(printf "%s," "${markers[@]}")
        echo "[${json_array%,}]"
    fi

    return $EXIT_OK
}

# ヘルプ表示
show_help() {
    cat << 'EOF'
Usage: protocol.sh <command> [arguments]

Commands:
  detect-type <file>              メッセージタイプを検出
  validate-request <kind> <file>  リクエストの検証
  detect-callbacks <file>         コールバックを検出
  extract-markers <file>          すべてのマーカーを抽出

Exit Codes:
  0 - 成功
  1 - 無効な入力
  2 - 不明なタイプ
  3 - マーカーなし

Examples:
  ./protocol.sh detect-type /tmp/message.txt
  # Output: TYPE=CONSULT KIND=DESIGN

  ./protocol.sh validate-request DESIGN /tmp/prompt.txt
  # Output: {"valid":true,"type":"CONSULT","kind":"DESIGN","marker":"[CONSULT:DESIGN]"}

  ./protocol.sh detect-callbacks /tmp/response.txt
  # Output: [{"type":"VERIFICATION","line":15}]

  ./protocol.sh extract-markers /tmp/response.txt
  # Output: ["[RESPONSE:DESIGN]","[CONSULT:CLAUDE:VERIFICATION]"]
EOF
}

# メイン処理
main() {
    local command="${1:-help}"
    shift || true

    case "$command" in
        detect-type)
            detect_type "$@"
            ;;
        validate-request)
            validate_request "$@"
            ;;
        detect-callbacks)
            detect_callbacks "$@"
            ;;
        extract-markers)
            extract_markers "$@"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo "Unknown command: $command" >&2
            show_help
            return $EXIT_INVALID
            ;;
    esac
}

main "$@"
