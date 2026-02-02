#!/bin/bash
# トリアージ更新
# 使用法: update_triage.sh <feedback_id> --status <status> [--fix-ref <ref>]

set -euo pipefail

FEEDBACK_DIR="${FEEDBACK_DIR:-${HOME}/.claude/feedback}"

usage() {
  local exit_code="${1:-1}"
  cat << EOF
使用法: $0 <feedback_id> --status <status> [--fix-ref <ref>]

オプション:
  --status   ステータス (open|triaged|in_progress|fixed|verified|wont_fix)
  --fix-ref  修正参照 (commit hash, PR番号など)
  -h, --help このヘルプを表示

例:
  $0 fb-20260201-001 --status fixed --fix-ref "commit:abc123"
  $0 fb-20260201-001 --status verified
EOF
  exit "$exit_code"
}

die() {
  echo "Error: $*" >&2
  exit 1
}

# YAMLのダブルクォート文字列用エスケープ（"と\）
escape_yaml_dq() {
  local str="$1"
  str="${str//\\/\\\\}"
  str="${str//\"/\\\"}"
  printf '%s' "$str"
}

# メイン処理
main() {
  local feedback_id="$1"
  shift

  local status=""
  local fix_ref=""
  local set_fix_ref=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --status)
        [[ $# -ge 2 ]] || die "--status の値がありません"
        status="$2"
        shift 2
        ;;
      --fix-ref)
        [[ $# -ge 2 ]] || die "--fix-ref の値がありません"
        fix_ref="$2"
        set_fix_ref=true
        shift 2
        ;;
      -h|--help)
        usage 0
        ;;
      *)
        die "不明なオプション: $1"
        ;;
    esac
  done

  if [[ -z "$status" ]]; then
    die "--status は必須です"
  fi

  # ステータス検証
  case "$status" in
    open|triaged|in_progress|fixed|verified|wont_fix) ;;
    *) die "無効なステータス: $status" ;;
  esac

  local filepath="${FEEDBACK_DIR}/${feedback_id}.yaml"

  if [[ ! -f "$filepath" ]]; then
    die "フィードバックが見つかりません: $filepath"
  fi

  local temp1 temp2 temp3
  temp1="$(mktemp "${filepath}.tmp.XXXXXX")" || die "一時ファイル作成に失敗しました"
  temp2="$(mktemp "${filepath}.tmp.XXXXXX")" || die "一時ファイル作成に失敗しました"
  temp3="$(mktemp "${filepath}.tmp.XXXXXX")" || die "一時ファイル作成に失敗しました"
  # shellcheck disable=SC2064
  trap "rm -f '$temp1' '$temp2' '$temp3'" EXIT

  local updated_at
  updated_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  # triage.status を triage ブロック内だけ更新（なければ追加）
  awk -v new_status="$status" '
    BEGIN { triage_seen=0; in_triage=0; status_written=0 }
    /^triage:[[:space:]]*$/ {
      triage_seen=1
      in_triage=1
      print
      next
    }
    {
      if (in_triage) {
        if ($0 ~ /^[^[:space:]]/) {
          if (!status_written) {
            print "  status: " new_status
            status_written=1
          }
          in_triage=0
        } else if ($0 ~ /^  status:[[:space:]]*/) {
          print "  status: " new_status
          status_written=1
          next
        }
      }
      print
    }
    END {
      if (triage_seen && in_triage && !status_written) {
        print "  status: " new_status
      }
      if (!triage_seen) {
        print ""
        print "triage:"
        print "  status: " new_status
        print "  priority: medium"
      }
    }
  ' "$filepath" > "$temp1"

  # updated_at を更新（なければ id の直後に追加）
  awk -v ts="$updated_at" '
    BEGIN { done=0 }
    /^updated_at:[[:space:]]*/ {
      print "updated_at: " ts
      done=1
      next
    }
    {
      print
      if (!done && $0 ~ /^id:[[:space:]]*/) {
        print "updated_at: " ts
        done=1
      }
    }
    END {
      if (!done) print "updated_at: " ts
    }
  ' "$temp1" > "$temp2"

  # resolution 追加/更新（fixed/verified の場合のみ）
  if [[ "$status" == "fixed" || "$status" == "verified" ]]; then
    local fix_ref_yaml=""
    if [[ "$set_fix_ref" == true ]]; then
      fix_ref_yaml="$(escape_yaml_dq "$fix_ref")"
    fi

    awk \
      -v set_fix_ref="$set_fix_ref" \
      -v fix_ref="$fix_ref_yaml" \
      -v set_verified_at="$([[ "$status" == "verified" ]] && echo true || echo false)" \
      -v ts="$updated_at" '
        BEGIN { in_res=0; res_seen=0; fix_seen=0; ver_seen=0 }
        function emit_missing() {
          if (!fix_seen) {
            if (set_fix_ref == "true") print "  fix_ref: \"" fix_ref "\""
            else print "  fix_ref: \"\""
          }
          if (!ver_seen) {
            if (set_verified_at == "true") print "  verified_at: " ts
            else print "  verified_at: \"\""
          }
        }
        /^resolution:[[:space:]]*$/ {
          res_seen=1
          in_res=1
          fix_seen=0
          ver_seen=0
          print
          next
        }
        {
          if (in_res) {
            if ($0 ~ /^[^[:space:]]/) {
              emit_missing()
              in_res=0
            } else if ($0 ~ /^  fix_ref:[[:space:]]*/) {
              if (set_fix_ref == "true") print "  fix_ref: \"" fix_ref "\""
              else print
              fix_seen=1
              next
            } else if ($0 ~ /^  verified_at:[[:space:]]*/) {
              if (set_verified_at == "true") print "  verified_at: " ts
              else print
              ver_seen=1
              next
            }
          }
          print
        }
        END {
          if (in_res) emit_missing()
          if (!res_seen) {
            print ""
            print "resolution:"
            if (set_fix_ref == "true") print "  fix_ref: \"" fix_ref "\""
            else print "  fix_ref: \"\""
            if (set_verified_at == "true") print "  verified_at: " ts
            else print "  verified_at: \"\""
          }
        }
      ' "$temp2" > "$temp3"
  else
    cp "$temp2" "$temp3"
  fi

  # 原子的置換
  mv "$temp3" "$filepath"

  echo "更新完了: $filepath"
  echo "  status: $status"
  [[ "$set_fix_ref" == true ]] && echo "  fix_ref: $fix_ref" || true
}

if [[ $# -lt 1 ]]; then
  usage 1
fi

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage 0
fi

main "$@"
