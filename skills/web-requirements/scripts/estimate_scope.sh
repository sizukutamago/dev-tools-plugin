#!/bin/bash
#
# estimate_scope.sh - Scope Estimation Script
#
# プロジェクトのファイル数と LOC を計算し、
# スコープ分割が必要かどうかを判定する。
#

set -euo pipefail

# デフォルト値
TARGET_DIR="${1:-.}"
OUTPUT_FORMAT="${2:-json}"

# 閾値
FILE_THRESHOLD=150
LOC_THRESHOLD=20000

# カラー出力（JSON以外の場合）
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 対象ファイル拡張子
EXTENSIONS=(
    "ts" "tsx" "js" "jsx"
    "py" "rb" "go" "rs"
    "java" "kt" "scala"
    "vue" "svelte"
    "css" "scss" "less"
)

# 除外パターン
EXCLUDE_DIRS=(
    "node_modules"
    ".git"
    "dist"
    "build"
    ".next"
    "coverage"
    "__pycache__"
    ".venv"
    "vendor"
)

# Run find with safe arguments (avoids eval injection)
# Uses process substitution to return file list
safe_find() {
    local dir="$1"
    local -a args=("$dir")

    # Add exclude patterns
    for exclude_dir in "${EXCLUDE_DIRS[@]}"; do
        args+=(-path "*/${exclude_dir}/*" -prune -o)
    done

    # Add type and extension patterns
    args+=(-type f \()
    local first=true
    for ext in "${EXTENSIONS[@]}"; do
        if $first; then
            args+=(-name "*.${ext}")
            first=false
        else
            args+=(-o -name "*.${ext}")
        fi
    done
    args+=(\) -print)

    find "${args[@]}" 2>/dev/null
}

# ファイル数を計算
count_files() {
    local dir="$1"
    safe_find "$dir" | wc -l | tr -d ' '
}

# LOC を計算
count_loc() {
    local dir="$1"
    local files
    files=$(safe_find "$dir")

    if [[ -z "$files" ]]; then
        echo "0"
        return
    fi

# ファイル名にスペースがある場合も対応
    echo "$files" | tr '\n' '\0' | xargs -0 wc -l 2>/dev/null | tail -1 | awk '{print $1}'
}

# ディレクトリ構造を分析
analyze_structure() {
    local dir="$1"

    # トップレベルディレクトリを取得（macOS/BSD互換）
    local top_dirs=$(find "$dir" -maxdepth 1 -type d ! -name ".*" ! -name "node_modules" ! -name "dist" ! -name "build" 2>/dev/null | xargs -I{} basename {} | sort)

    local shards="[]"
    local shard_list=""

    for subdir in $top_dirs; do
        if [[ "$subdir" == "." || "$subdir" == ".." ]]; then
            continue
        fi

        local subdir_path="$dir/$subdir"
        if [[ ! -d "$subdir_path" ]]; then
            continue
        fi

        local subdir_files=$(count_files "$subdir_path")
        local subdir_loc=$(count_loc "$subdir_path")

        # ファイルが存在するディレクトリのみ対象
        if [[ "$subdir_files" -gt 0 ]]; then
            local shard=$(cat <<EOF
{
  "id": "$subdir",
  "paths": ["$subdir/**"],
  "files": $subdir_files,
  "loc": $subdir_loc
}
EOF
)
            if [[ -z "$shard_list" ]]; then
                shard_list="$shard"
            else
                shard_list="$shard_list,$shard"
            fi
        fi
    done

    if [[ -n "$shard_list" ]]; then
        shards="[$shard_list]"
    fi

    echo "$shards"
}

# モード判定
detect_mode() {
    local dir="$1"

    # .git が存在し、コードファイルがある場合は brownfield
    if [[ -d "$dir/.git" ]]; then
        local file_count=$(count_files "$dir")
        if [[ "$file_count" -gt 0 ]]; then
            echo "brownfield"
            return
        fi
    fi

    echo "greenfield"
}

# メイン処理
main() {
    local dir="$TARGET_DIR"

    # 入力検証: ダッシュで始まるパスは find オプションと誤解される可能性がある
    if [[ "$dir" == -* ]]; then
        echo "Error: Directory path cannot start with '-': $dir" >&2
        exit 1
    fi

    # ディレクトリの存在確認
    if [[ ! -d "$dir" ]]; then
        echo "Error: Directory not found: $dir" >&2
        exit 1
    fi

    # 計算
    local total_files=$(count_files "$dir")
    local total_loc=$(count_loc "$dir")
    local mode=$(detect_mode "$dir")

    # 分割が必要か判定
    local needs_sharding=false
    if [[ "$total_files" -gt "$FILE_THRESHOLD" ]] || [[ "$total_loc" -gt "$LOC_THRESHOLD" ]]; then
        needs_sharding=true
    fi

    # 構造分析（分割が必要な場合）
    local shards="[]"
    if [[ "$needs_sharding" == "true" ]]; then
        shards=$(analyze_structure "$dir")
    fi

    # 出力
    case "$OUTPUT_FORMAT" in
        json)
            cat <<EOF
{
  "mode": "$mode",
  "total_files": $total_files,
  "total_loc": $total_loc,
  "needs_sharding": $needs_sharding,
  "thresholds": {
    "files": $FILE_THRESHOLD,
    "loc": $LOC_THRESHOLD
  },
  "shards": $shards
}
EOF
            ;;
        text)
            echo "Scope Estimation Report"
            echo "======================"
            echo ""
            echo "Mode: $mode"
            echo "Total Files: $total_files"
            echo "Total LOC: $total_loc"
            echo ""

            if [[ "$needs_sharding" == "true" ]]; then
                echo -e "${YELLOW}⚠ Sharding recommended${NC}"
                echo "  Files > $FILE_THRESHOLD or LOC > $LOC_THRESHOLD"
            else
                echo -e "${GREEN}✓ No sharding needed${NC}"
            fi
            ;;
        *)
            echo "Error: Unknown format: $OUTPUT_FORMAT" >&2
            exit 1
            ;;
    esac
}

main
