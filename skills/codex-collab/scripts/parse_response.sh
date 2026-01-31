#!/bin/bash
# scripts/parse_response.sh - 構造化レスポンス解析（jq ベース強化版）
# Codex からの応答を解析してセクションを抽出
#
# 使用例:
#   ./parse_response.sh /tmp/codex_output.txt
#   ./parse_response.sh /tmp/codex_output.txt --section ASSESSMENT
#   ./parse_response.sh /tmp/codex_output.txt --validate
#   ./parse_response.sh /tmp/codex_output.txt --format json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

# デフォルト設定
OUTPUT_FORMAT="json"
SECTION=""
VALIDATE=false

# セクション定義（関数で取得 - bash 3.x 互換）
get_sections_for_type() {
    local response_type="$1"
    case "$response_type" in
        REQUIREMENTS)
            echo "CLARIFICATION_QUESTIONS CONSIDERATIONS"
            ;;
        DESIGN)
            echo "ASSESSMENT RISKS ALTERNATIVES RECOMMENDATION"
            ;;
        IMPLEMENTATION)
            echo "ADVICE PATTERNS CAVEATS"
            ;;
        REVIEW)
            echo "STRENGTHS ISSUES SUGGESTIONS"
            ;;
        *)
            echo ""
            ;;
    esac
}

show_help() {
    cat << 'EOF'
Usage: parse_response.sh <response_file> [options]

Arguments:
  response_file          Codex レスポンスファイルへのパス

Options:
  --section <name>       特定のセクションのみ抽出
  --validate             プロトコル準拠を検証
  --format <type>        出力形式: json (default), text, raw
  --detect-callbacks     コールバックマーカーを検出

Response Types and Sections:
  REQUIREMENTS: CLARIFICATION_QUESTIONS, CONSIDERATIONS
  DESIGN:       ASSESSMENT, RISKS, ALTERNATIVES, RECOMMENDATION
  IMPLEMENTATION: ADVICE, PATTERNS, CAVEATS
  REVIEW:       STRENGTHS, ISSUES, SUGGESTIONS

Examples:
  ./parse_response.sh /tmp/codex_output.txt
  ./parse_response.sh /tmp/codex_output.txt --section ISSUES
  ./parse_response.sh /tmp/codex_output.txt --validate
EOF
}

# セクション抽出（改良版）
extract_section() {
    local section_name="$1"
    local content="$2"
    local section_lower
    section_lower=$(echo "$section_name" | tr '[:upper:]' '[:lower:]')

    # パターンマッチ: ## SECTION, **SECTION**, SECTION:
    echo "$content" | awk -v section="$section_lower" '
        BEGIN { found=0; output="" }
        {
            line_lower = tolower($0)
            if (match(line_lower, "^##+ +" section) || match(line_lower, "^\\*\\*" section "s?\\*\\*") || match(line_lower, "^" section "s?:") || match(line_lower, "^" section "s?$")) { found=1; next }
            if (found && (match($0, /^##+ +[A-Za-z]/) || match($0, /^\*\*[A-Za-z_]+\*\*/) || match($0, /^[A-Z][A-Za-z_]+:$/))) { found=0 }
            if (found) { output = output $0 "\n" }
        }
        END { print output }
    ' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | head -c 50000
}

# レスポンスタイプ検出
detect_response_type() {
    local content="$1"

    # lib/protocol.sh を使用して検出
    local first_line
    first_line=$(echo "$content" | head -1)

    if echo "$first_line" | grep -q '\[RESPONSE:REQUIREMENTS\]'; then
        echo "REQUIREMENTS"
    elif echo "$first_line" | grep -q '\[RESPONSE:DESIGN\]'; then
        echo "DESIGN"
    elif echo "$first_line" | grep -q '\[RESPONSE:IMPLEMENTATION\]'; then
        echo "IMPLEMENTATION"
    elif echo "$first_line" | grep -q '\[RESPONSE:REVIEW\]'; then
        echo "REVIEW"
    else
        # コンテンツベースの検出
        if echo "$content" | grep -qiE 'CLARIFICATION_QUESTIONS|CONSIDERATIONS'; then
            echo "REQUIREMENTS"
        elif echo "$content" | grep -qiE 'ASSESSMENT.*RISKS|RISKS.*ALTERNATIVES'; then
            echo "DESIGN"
        elif echo "$content" | grep -qiE 'ADVICE.*PATTERNS|PATTERNS.*CAVEATS'; then
            echo "IMPLEMENTATION"
        elif echo "$content" | grep -qiE 'STRENGTHS.*ISSUES|ISSUES.*SUGGESTIONS'; then
            echo "REVIEW"
        else
            echo "UNKNOWN"
        fi
    fi
}

# コールバック検出
detect_callbacks() {
    local content="$1"

    # lib/protocol.sh を使用
    if [[ -f "${LIB_DIR}/protocol.sh" ]]; then
        local tmp_file
        tmp_file=$(mktemp)
        echo "$content" > "$tmp_file"
        "${LIB_DIR}/protocol.sh" detect-callbacks "$tmp_file"
        rm -f "$tmp_file"
    else
        # フォールバック: 直接検出
        local callbacks=()
        local line_num=0
        while IFS= read -r line; do
            ((line_num++)) || true
            if echo "$line" | grep -qE '^\[CONSULT:CLAUDE:(VERIFICATION|CONTEXT)\]'; then
                local type
                type=$(echo "$line" | sed -n 's/.*CONSULT:CLAUDE:\([A-Z]*\).*/\1/p')
                callbacks+=("{\"type\":\"$type\",\"line\":$line_num}")
            fi
        done <<< "$content"

        if [[ ${#callbacks[@]} -eq 0 ]]; then
            echo "[]"
        else
            local json_array
            json_array=$(printf "%s," "${callbacks[@]}")
            echo "[${json_array%,}]"
        fi
    fi
}

# プロトコル検証
validate_response() {
    local content="$1"

    local first_line
    first_line=$(echo "$content" | head -1)

    local valid=true
    local errors=()

    # マーカー存在チェック
    if ! echo "$first_line" | grep -qE '^\[RESPONSE:(REQUIREMENTS|DESIGN|IMPLEMENTATION|REVIEW)\]'; then
        valid=false
        errors+=("Missing or invalid response marker in first line")
    fi

    # 必須セクションチェック
    local response_type
    response_type=$(detect_response_type "$content")

    if [[ "$response_type" != "UNKNOWN" ]]; then
        local sections
        sections=$(get_sections_for_type "$response_type")
        local missing=()
        for sec in $sections; do
            if ! echo "$content" | grep -qiE "^##+ +$sec|^\*\*$sec\*\*|^$sec:"; then
                missing+=("$sec")
            fi
        done
        if [[ ${#missing[@]} -gt 0 ]]; then
            errors+=("Missing sections: ${missing[*]}")
        fi
    fi

    # JSON 出力
    if [[ "$valid" == true && ${#errors[@]} -eq 0 ]]; then
        jq -n \
            --arg type "$response_type" \
            '{valid: true, response_type: $type, errors: []}'
    else
        jq -n \
            --arg type "$response_type" \
            --argjson errors "$(printf '%s\n' "${errors[@]}" | jq -R . | jq -s .)" \
            '{valid: false, response_type: $type, errors: $errors}'
    fi
}

# メイン処理
main() {
    local response_file=""
    local detect_callbacks_flag=false

    # 引数解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --section)
                SECTION="$2"
                shift 2
                ;;
            --validate)
                VALIDATE=true
                shift
                ;;
            --format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            --detect-callbacks)
                detect_callbacks_flag=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                if [[ -z "$response_file" ]]; then
                    response_file="$1"
                else
                    echo "Unknown option: $1" >&2
                    exit 1
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$response_file" ]]; then
        echo "Error: response_file required" >&2
        show_help
        exit 1
    fi

    if [[ ! -f "$response_file" ]]; then
        echo "Error: file not found: $response_file" >&2
        exit 1
    fi

    local content
    content=$(cat "$response_file")

    # コールバック検出モード
    if [[ "$detect_callbacks_flag" == true ]]; then
        detect_callbacks "$content"
        return 0
    fi

    # 検証モード
    if [[ "$VALIDATE" == true ]]; then
        validate_response "$content"
        return $?
    fi

    # レスポンスタイプ検出
    local response_type
    response_type=$(detect_response_type "$content")

    # 特定セクション抽出
    if [[ -n "$SECTION" ]]; then
        local extracted
        extracted=$(extract_section "$SECTION" "$content")

        if [[ -n "$extracted" ]]; then
            if [[ "$OUTPUT_FORMAT" == "json" ]]; then
                jq -n \
                    --arg section "$SECTION" \
                    --arg content "$extracted" \
                    '{section: $section, content: $content, found: true}'
            else
                echo "$extracted"
            fi
        else
            if [[ "$OUTPUT_FORMAT" == "json" ]]; then
                jq -n \
                    --arg section "$SECTION" \
                    '{section: $section, content: "", found: false, error: "Section not found"}'
            else
                echo "Section '$SECTION' not found" >&2
            fi
            exit 1
        fi
        return 0
    fi

    # 全セクション抽出
    local sections_to_extract=""
    if [[ "$response_type" != "UNKNOWN" ]]; then
        sections_to_extract=$(get_sections_for_type "$response_type")
    else
        # 全セクションを試行
        sections_to_extract="CLARIFICATION_QUESTIONS CONSIDERATIONS ASSESSMENT RISKS ALTERNATIVES RECOMMENDATION ADVICE PATTERNS CAVEATS STRENGTHS ISSUES SUGGESTIONS"
    fi

    # JSON 構築
    local sections_json="{}"
    for sec in $sections_to_extract; do
        local extracted
        extracted=$(extract_section "$sec" "$content")
        if [[ -n "$extracted" ]]; then
            sections_json=$(echo "$sections_json" | jq \
                --arg sec "$sec" \
                --arg content "$extracted" \
                '.[$sec] = $content')
        fi
    done

    # コールバック検出
    local callbacks
    callbacks=$(detect_callbacks "$content")

    # 最終出力
    jq -n \
        --arg type "$response_type" \
        --argjson sections "$sections_json" \
        --argjson callbacks "$callbacks" \
        --argjson raw_length "${#content}" \
        '{
            response_type: $type,
            sections: $sections,
            callbacks: $callbacks,
            raw_length: $raw_length
        }'
}

main "$@"
