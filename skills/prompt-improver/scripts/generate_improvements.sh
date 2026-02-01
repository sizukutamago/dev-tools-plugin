#!/bin/bash
# 改善提案生成
# 使用法: generate_improvements.sh [--target <path>]

set -euo pipefail
shopt -s nullglob

FEEDBACK_DIR="${HOME}/.claude/feedback"

# ターゲットファイル別に改善提案を生成
generate() {
  local target_filter="${1:-}"

  echo "=========================================="
  echo "改善提案レポート"
  echo "=========================================="
  echo ""

  # openステータスのフィードバックを抽出
  local targets=()

  for file in "$FEEDBACK_DIR"/*.yaml; do
    [[ -f "$file" ]] || continue

    # YAML破損チェック
    if ! grep -q "^id:" "$file" 2>/dev/null; then
      echo "Warning: $file をスキップ" >&2
      continue
    fi

    # open ステータスのみ
    if ! grep -q "status: open" "$file" 2>/dev/null; then
      continue
    fi

    # targetフィルタ（固定文字列マッチ）
    if [[ -n "$target_filter" ]]; then
      grep -F "$target_filter" "$file" 2>/dev/null | grep -q "path:" || continue
    fi

    # ターゲットパスを抽出（全issue分）
    while IFS= read -r target_path; do
      if [[ -n "$target_path" ]]; then
        targets+=("$target_path")
      fi
    done < <(grep "^      path:" "$file" 2>/dev/null | sed 's/.*path: //')
  done

  # ユニークなターゲット別に集計
  if [[ ${#targets[@]} -eq 0 ]]; then
    echo "未解決のフィードバックはありません。"
    return 0
  fi

  echo "【優先改善対象】"
  printf '%s\n' "${targets[@]}" | sort | uniq -c | sort -rn | head -10 | while IFS= read -r line; do
    # uniq -c の出力は "   N path" 形式なので分解
    count=$(echo "$line" | awk '{print $1}')
    path=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^ *//')
    [[ -z "$path" ]] && continue
    echo ""
    echo "${count}. ${path}"
    echo "   問題数: ${count}件"

    # 該当ファイルの問題タイプを表示（open ステータスかつ該当pathのissueのみ）
    echo "   問題タイプ:"
    for file in "$FEEDBACK_DIR"/*.yaml; do
      # openステータスかつ該当pathを含むファイルのみ
      if grep -q "status: open" "$file" 2>/dev/null && \
         grep -F "$path" "$file" 2>/dev/null | grep -q "path:"; then
        # 簡易的にissue配下のtypeを抽出（完全な紐付けにはyq等が必要）
        grep "^    type:" "$file" 2>/dev/null | sed 's/.*type: /    - /'
      fi
    done | sort | uniq
  done

  echo ""
  echo "=========================================="
}

# メイン処理
main() {
  local target=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --target) target="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  if [[ ! -d "$FEEDBACK_DIR" ]]; then
    echo "フィードバックディレクトリがありません: $FEEDBACK_DIR" >&2
    exit 1
  fi

  generate "$target"
}

main "$@"
