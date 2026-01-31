#!/bin/bash
# 構造化レスポンス解析スクリプト
# Codex からの応答を解析してセクションを抽出

set -euo pipefail

show_help() {
    cat << 'EOF'
Usage: parse_response.sh <response_file> [section]

Arguments:
  response_file   Path to the Codex response file
  section         (optional) Specific section to extract

Available sections:
  RESPONSE:REQUIREMENTS
    - CLARIFICATION_QUESTIONS
    - CONSIDERATIONS

  RESPONSE:DESIGN
    - ASSESSMENT
    - RISKS
    - ALTERNATIVES
    - RECOMMENDATION

  RESPONSE:IMPLEMENTATION
    - ADVICE
    - PATTERNS
    - CAVEATS

  RESPONSE:REVIEW
    - STRENGTHS
    - ISSUES
    - SUGGESTIONS

  ALL (default)
    - Extract all sections

Examples:
  # 全セクションを表示
  ./parse_response.sh /tmp/codex_output.txt

  # 特定セクションを抽出
  ./parse_response.sh /tmp/codex_output.txt ASSESSMENT
  ./parse_response.sh /tmp/codex_output.txt ISSUES

Output format:
  JSON object with extracted sections
EOF
}

if [[ $# -lt 1 ]]; then
    show_help
    exit 1
fi

RESPONSE_FILE="$1"
SECTION="${2:-ALL}"

if [[ ! -f "$RESPONSE_FILE" ]]; then
    echo "Error: Response file not found: $RESPONSE_FILE" >&2
    exit 1
fi

# レスポンス読み込み
CONTENT=$(cat "$RESPONSE_FILE")

# セクション抽出関数
extract_section() {
    local section_name="$1"
    local content="$2"

    # セクションヘッダーの後から次のセクションヘッダーまたはファイル末尾まで抽出
    # 対応パターン: "## SECTION_NAME", "### SECTION_NAME", "SECTION_NAME:", "**SECTION_NAME**:"
    # tolower() で case-insensitive マッチ
    echo "$content" | awk -v section="$section_name" '
        BEGIN { found=0; output=""; sec_lower=tolower(section) }
        {
            line_lower = tolower($0)
            # パターンマッチ: "## SECTION", "**SECTION**", "SECTION:"
            if (match(line_lower, "^##+ +" sec_lower) || match(line_lower, "^\\*\\*" sec_lower "s?\\*\\*") || match(line_lower, "^" sec_lower ":")) {
                found=1
                next
            }
        }
        found && /^##+ +[A-Za-z]/ { found=0 }
        found && /^\*\*[A-Za-z_]+\*\*/ { found=0 }
        found && /^[A-Za-z_]+:$/ { found=0 }
        found { output = output $0 "\n" }
        END { print output }
    ' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | head -c 10000
}

# JSON出力用エスケープ
json_escape() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\t'/\\t}"
    str="${str//$'\r'/}"
    echo "$str"
}

# セクション存在チェック
section_exists() {
    local section_name="$1"
    local content="$2"

    # パターン: "## SECTION_NAME", "### SECTION_NAME", "SECTION_NAME:", "**SECTION_NAME**"
    # -i で case-insensitive マッチ
    if echo "$content" | grep -qiE "^##+ +$section_name|^\*\*$section_name\*\*|^$section_name:"; then
        return 0
    else
        return 1
    fi
}

# レスポンスタイプ検出
detect_response_type() {
    local content="$1"

    # -i で case-insensitive マッチ
    if echo "$content" | grep -qiE '\[RESPONSE:REQUIREMENTS\]|CLARIFICATION_QUESTIONS|CONSIDERATIONS'; then
        echo "REQUIREMENTS"
    elif echo "$content" | grep -qiE '\[RESPONSE:DESIGN\]|ASSESSMENT|RISKS|ALTERNATIVES|RECOMMENDATION'; then
        echo "DESIGN"
    elif echo "$content" | grep -qiE '\[RESPONSE:IMPLEMENTATION\]|ADVICE|PATTERNS|CAVEATS'; then
        echo "IMPLEMENTATION"
    elif echo "$content" | grep -qiE '\[RESPONSE:REVIEW\]|STRENGTHS|ISSUES|SUGGESTIONS'; then
        echo "REVIEW"
    else
        echo "UNKNOWN"
    fi
}

# メイン処理
if [[ "$SECTION" == "ALL" ]]; then
    # レスポンスタイプを検出して全セクション抽出
    RESPONSE_TYPE=$(detect_response_type "$CONTENT")

    echo "{"
    echo "  \"response_type\": \"$RESPONSE_TYPE\","
    echo "  \"sections\": {"

    case "$RESPONSE_TYPE" in
        REQUIREMENTS)
            sections=("CLARIFICATION_QUESTIONS" "CONSIDERATIONS")
            ;;
        DESIGN)
            sections=("ASSESSMENT" "RISKS" "ALTERNATIVES" "RECOMMENDATION")
            ;;
        IMPLEMENTATION)
            sections=("ADVICE" "PATTERNS" "CAVEATS")
            ;;
        REVIEW)
            sections=("STRENGTHS" "ISSUES" "SUGGESTIONS")
            ;;
        *)
            # 全セクションを試行
            sections=("CLARIFICATION_QUESTIONS" "CONSIDERATIONS" "ASSESSMENT" "RISKS" "ALTERNATIVES" "RECOMMENDATION" "ADVICE" "PATTERNS" "CAVEATS" "STRENGTHS" "ISSUES" "SUGGESTIONS")
            ;;
    esac

    first=true
    for sec in "${sections[@]}"; do
        if section_exists "$sec" "$CONTENT"; then
            extracted=$(extract_section "$sec" "$CONTENT")
            if [[ -n "$extracted" ]]; then
                if [[ "$first" == "true" ]]; then
                    first=false
                else
                    echo ","
                fi
                echo -n "    \"$sec\": \"$(json_escape "$extracted")\""
            fi
        fi
    done

    echo ""
    echo "  },"
    echo "  \"raw_length\": ${#CONTENT}"
    echo "}"
else
    # 特定セクションのみ抽出
    if section_exists "$SECTION" "$CONTENT"; then
        extracted=$(extract_section "$SECTION" "$CONTENT")
        echo "{"
        echo "  \"section\": \"$SECTION\","
        echo "  \"content\": \"$(json_escape "$extracted")\","
        echo "  \"found\": true"
        echo "}"
    else
        echo "{"
        echo "  \"section\": \"$SECTION\","
        echo "  \"content\": \"\","
        echo "  \"found\": false,"
        echo "  \"error\": \"Section '$SECTION' not found in response\""
        echo "}"
        exit 1
    fi
fi
