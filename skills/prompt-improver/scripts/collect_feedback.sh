#!/bin/bash
# フィードバック収集・保存
# 使用法: collect_feedback.sh <task_summary> <success:true|false> <rationale>

set -euo pipefail

FEEDBACK_DIR="${HOME}/.claude/feedback"

# ディレクトリ作成
mkdir -p "$FEEDBACK_DIR"

# 原子的ID生成
generate_id() {
  local today
  today=$(date -u +%Y%m%d)
  local seq=1

  while [[ $seq -le 999 ]]; do
    local id
    id=$(printf "fb-%s-%03d" "$today" "$seq")
    local file="${FEEDBACK_DIR}/${id}.yaml"

    # 原子的作成（noclobber）
    if (set -o noclobber; : > "$file") 2>/dev/null; then
      echo "$id"
      return 0
    fi
    ((seq++))
  done

  echo "Error: ID生成失敗" >&2
  return 1
}

# YAMLエスケープ（"と\をエスケープ、改行を\nに）
escape_yaml() {
  local str="$1"
  str="${str//\\/\\\\}"    # \ → \\
  str="${str//\"/\\\"}"    # " → \"
  str="${str//$'\n'/\\n}"  # 改行 → \n
  printf '%s\n' "$str"
}

# メイン処理
main() {
  if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <task_summary> <success:true|false> <rationale>" >&2
    exit 1
  fi

  local task_summary="$1"
  local success="$2"
  local rationale="$3"

  # successのバリデーション
  if [[ "$success" != "true" && "$success" != "false" ]]; then
    echo "Error: success は true または false を指定してください" >&2
    exit 1
  fi

  # YAMLエスケープ
  task_summary=$(escape_yaml "$task_summary")
  rationale=$(escape_yaml "$rationale")

  local created_at
  created_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  local id
  id=$(generate_id) || exit 1
  local filepath="${FEEDBACK_DIR}/${id}.yaml"

  # YAML生成
  cat > "$filepath" << EOF
id: ${id}
created_at: ${created_at}
task_summary: "${task_summary}"
outcome:
  success: ${success}
  rationale: "${rationale}"
issues: []
source: self
triage:
  status: open
  priority: low
EOF

  echo "保存完了: $filepath"
}

main "$@"
