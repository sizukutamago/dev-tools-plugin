#!/bin/bash
# フィードバックアーカイブ
# 使用法: archive_feedback.sh [--status <status>] [--older-than <days>] [--dry-run]

set -euo pipefail

FEEDBACK_DIR="${FEEDBACK_DIR:-${HOME}/.claude/feedback}"
ARCHIVE_DIR="${FEEDBACK_DIR}/archive"

usage() {
  local exit_code="${1:-0}"
  cat << EOF
使用法: $0 [オプション]

改善済み/古いフィードバックをアーカイブディレクトリに移動します。

オプション:
  --status <status>      指定ステータスのログをアーカイブ (fixed|verified|wont_fix)
  --older-than <days>    指定日数より古いログをアーカイブ
  --all-fixed            fixed, verified, wont_fix すべてをアーカイブ
  --dry-run              実際には移動せず、対象ファイルを表示
  -h, --help             このヘルプを表示

例:
  $0 --status verified              # verified のみアーカイブ
  $0 --all-fixed                    # 改善済み全てをアーカイブ
  $0 --older-than 30                # 30日以上古いログをアーカイブ
  $0 --all-fixed --dry-run          # ドライラン
EOF
  exit "$exit_code"
}

die() {
  echo "Error: $*" >&2
  exit 1
}

get_triage_status() {
  local filepath="$1"
  awk '
    BEGIN { in_triage=0 }
    /^triage:[[:space:]]*$/ { in_triage=1; next }
    in_triage && /^  status:[[:space:]]*/ {
      sub(/^  status:[[:space:]]*/, "", $0)
      print $0
      exit 0
    }
    in_triage && /^[^[:space:]]/ { exit 0 }
  ' "$filepath" 2>/dev/null || true
}

get_mtime_epoch() {
  local filepath="$1"
  # macOS / BSD
  stat -f "%m" "$filepath" 2>/dev/null || \
  # Linux / GNU
  stat -c "%Y" "$filepath" 2>/dev/null || \
  echo ""
}

# メイン処理
main() {
  local target_status=""
  local all_fixed=false
  local older_than=""
  local dry_run=false
  local archived_count=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --status)
        [[ $# -ge 2 ]] || die "--status の値がありません"
        target_status="$2"
        shift 2
        ;;
      --all-fixed) all_fixed=true; shift ;;
      --older-than)
        [[ $# -ge 2 ]] || die "--older-than の値がありません"
        older_than="$2"
        shift 2
        ;;
      --dry-run) dry_run=true; shift ;;
      -h|--help) usage 0 ;;
      *) die "不明なオプション: $1" ;;
    esac
  done

  # オプション検証
  if [[ -z "$target_status" && "$all_fixed" == false && -z "$older_than" ]]; then
    echo "Error: --status, --all-fixed, または --older-than を指定してください" >&2
    usage 1
  fi

  if [[ -n "$target_status" ]]; then
    case "$target_status" in
      fixed|verified|wont_fix) ;;
      *) die "無効なステータス: $target_status" ;;
    esac
  fi

  if [[ -n "$older_than" ]]; then
    [[ "$older_than" =~ ^[0-9]+$ ]] || die "--older-than は数値を指定してください: $older_than"
  fi

  # アーカイブディレクトリ作成
  if [[ "$dry_run" == false ]]; then
    mkdir -p "$ARCHIVE_DIR"
  fi

  echo "=========================================="
  echo "  フィードバック アーカイブ"
  echo "=========================================="
  [[ "$dry_run" == true ]] && echo "  (ドライランモード)"
  echo ""

  # 対象ファイルを検索
  for filepath in "${FEEDBACK_DIR}"/fb-*.yaml; do
    [[ ! -f "$filepath" ]] && continue

    local should_archive=false
    local filename
    filename=$(basename "$filepath")
    local triage_status
    triage_status="$(get_triage_status "$filepath")"

    # ステータスでフィルタ
    if [[ -n "$target_status" ]]; then
      if [[ "$triage_status" == "$target_status" ]]; then
        should_archive=true
      fi
    fi

    # all-fixed フィルタ
    if [[ "$all_fixed" == true ]]; then
      if [[ "$triage_status" == "fixed" || "$triage_status" == "verified" || "$triage_status" == "wont_fix" ]]; then
        should_archive=true
      fi
    fi

    # 日数フィルタ
    if [[ -n "$older_than" ]]; then
      local file_date
      file_date="$(get_mtime_epoch "$filepath")"
      if [[ -z "$file_date" ]]; then
        echo "Warning: mtime取得に失敗したためスキップ: $filename" >&2
        continue
      fi
      local current_date
      current_date=$(date +%s)
      local days_old=$(( (current_date - file_date) / 86400 ))

      if [[ $days_old -ge $older_than ]]; then
        should_archive=true
      fi
    fi

    # アーカイブ実行
    if [[ "$should_archive" == true ]]; then
      if [[ "$dry_run" == true ]]; then
        echo "  [対象] $filename"
      else
        mv "$filepath" "$ARCHIVE_DIR/"
        echo "  [移動] $filename → archive/"
      fi
      ((archived_count++)) || true
    fi
  done

  echo ""
  echo "=========================================="
  if [[ "$dry_run" == true ]]; then
    echo "  対象ファイル: ${archived_count}件"
    echo "  (ドライランのため移動していません)"
  else
    echo "  アーカイブ完了: ${archived_count}件"
    echo "  保存先: $ARCHIVE_DIR"
  fi
  echo "=========================================="
}

main "$@"
