#!/bin/bash
# フィードバック分析
# 使用法: analyze_feedback.sh [--stats] [--target <path>]

set -euo pipefail
shopt -s nullglob

FEEDBACK_DIR="${HOME}/.claude/feedback"

# 統計表示
show_stats() {
  local total=0 success=0 failure=0

  for file in "$FEEDBACK_DIR"/*.yaml; do
    [[ -f "$file" ]] || continue

    # YAML破損チェック
    if ! grep -q "^id:" "$file" 2>/dev/null; then
      echo "Warning: $file をスキップ" >&2
      continue
    fi

    ((total++)) || true
    if grep -q "success: true" "$file" 2>/dev/null; then
      ((success++)) || true
    else
      ((failure++)) || true
    fi
  done

  echo "=========================================="
  echo "フィードバック統計"
  echo "=========================================="
  echo "総数: $total"
  echo "成功: $success"
  echo "失敗: $failure"
  if [[ $total -gt 0 ]]; then
    local rate=$((success * 100 / total))
    echo "成功率: ${rate}%"
  fi
}

# 問題パターン分析
analyze_patterns() {
  local target_filter="${1:-}"

  echo "=========================================="
  echo "フィードバック分析レポート"
  echo "=========================================="
  echo ""

  # issue.type集計
  echo "【頻出問題タイプ】"
  for file in "$FEEDBACK_DIR"/*.yaml; do
    [[ -f "$file" ]] || continue

    # target フィルタ（固定文字列マッチ）
    if [[ -n "$target_filter" ]]; then
      grep -F "$target_filter" "$file" 2>/dev/null | grep -q "path:" || continue
    fi

    # issue typeを抽出
    grep "^    type:" "$file" 2>/dev/null | sed 's/.*type: //'
  done | sort | uniq -c | sort -rn | head -5 || true

  echo ""
  echo "【ターゲットファイル別】"
  for file in "$FEEDBACK_DIR"/*.yaml; do
    [[ -f "$file" ]] || continue
    grep "^      path:" "$file" 2>/dev/null | sed 's/.*path: //'
  done | sort | uniq -c | sort -rn | head -5 || true

  echo ""
  echo "=========================================="
}

# メイン処理
main() {
  local stats_only=false
  local target=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --stats) stats_only=true; shift ;;
      --target) target="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  if [[ ! -d "$FEEDBACK_DIR" ]]; then
    echo "フィードバックディレクトリがありません: $FEEDBACK_DIR" >&2
    exit 1
  fi

  if $stats_only; then
    show_stats
  else
    analyze_patterns "$target"
  fi
}

main "$@"
