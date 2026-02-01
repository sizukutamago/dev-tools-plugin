#!/bin/bash
# トリアージ更新
# 使用法: update_triage.sh <feedback_id> --status <status> [--fix-ref <ref>]

set -euo pipefail

FEEDBACK_DIR="${HOME}/.claude/feedback"

usage() {
  cat << EOF
使用法: $0 <feedback_id> --status <status> [--fix-ref <ref>]

オプション:
  --status   ステータス (open|triaged|in_progress|fixed|verified|wont_fix)
  --fix-ref  修正参照 (commit hash, PR番号など)

例:
  $0 fb-20260201-001 --status fixed --fix-ref "commit:abc123"
  $0 fb-20260201-001 --status verified
EOF
  exit 1
}

# メイン処理
main() {
  if [[ $# -lt 3 ]]; then
    usage
  fi

  local feedback_id="$1"
  shift

  local status=""
  local fix_ref=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --status) status="$2"; shift 2 ;;
      --fix-ref) fix_ref="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  if [[ -z "$status" ]]; then
    echo "Error: --status は必須です" >&2
    usage
  fi

  # ステータス検証
  case "$status" in
    open|triaged|in_progress|fixed|verified|wont_fix) ;;
    *) echo "Error: 無効なステータス: $status" >&2; usage ;;
  esac

  local filepath="${FEEDBACK_DIR}/${feedback_id}.yaml"

  if [[ ! -f "$filepath" ]]; then
    echo "Error: フィードバックが見つかりません: $filepath" >&2
    exit 1
  fi

  # triage: セクションと status: 行の存在確認
  if ! grep -q "^triage:" "$filepath"; then
    echo "Error: triage: セクションが見つかりません: $filepath" >&2
    exit 1
  fi
  if ! grep -q "^  status:" "$filepath"; then
    echo "Error: triage.status が見つかりません: $filepath" >&2
    exit 1
  fi

  # 一時ファイルで原子的更新
  local temp_file="${filepath}.tmp.$$"
  local temp_file2="${filepath}.tmp2.$$"
  local updated_at
  updated_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  # ステータス更新
  sed "s/^  status: .*/  status: $status/" "$filepath" > "$temp_file"

  # updated_at追加（なければ追加）- ポータブル版
  if grep -q "^updated_at:" "$temp_file"; then
    sed "s/^updated_at: .*/updated_at: $updated_at/" "$temp_file" > "$temp_file2"
    mv "$temp_file2" "$temp_file"
  else
    { head -1 "$temp_file"; echo "updated_at: $updated_at"; tail -n +2 "$temp_file"; } > "$temp_file2"
    mv "$temp_file2" "$temp_file"
  fi

  # resolution追加（fixed/verifiedの場合）
  if [[ "$status" == "fixed" || "$status" == "verified" ]]; then
    if ! grep -q "^resolution:" "$temp_file"; then
      cat >> "$temp_file" << EOF
resolution:
  fix_ref: "${fix_ref:-}"
  verified_at: ""
EOF
    fi

    if [[ "$status" == "verified" ]]; then
      sed "s/^  verified_at: .*/  verified_at: $updated_at/" "$temp_file" > "$temp_file2"
      mv "$temp_file2" "$temp_file"
    fi

    if [[ -n "$fix_ref" ]]; then
      sed "s|^  fix_ref: .*|  fix_ref: \"$fix_ref\"|" "$temp_file" > "$temp_file2"
      mv "$temp_file2" "$temp_file"
    fi
  fi

  # 原子的置換
  mv "$temp_file" "$filepath"

  echo "更新完了: $filepath"
  echo "  status: $status"
  [[ -n "$fix_ref" ]] && echo "  fix_ref: $fix_ref"
}

main "$@"
