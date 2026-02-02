#!/bin/bash
# install.sh - ai-skills を ~/.claude/ にインストール
#
# 使用方法:
#   ./install.sh [オプション]
#
# オプション:
#   --skip-design-docs    design-doc系のスキル/エージェントをスキップ
#   -h, --help            ヘルプを表示
#
# 動作:
#   - agents/, commands/, skills/ を ~/.claude/ 以下にコピー
#   - 既存ファイルは上書き
#   - ソースで削除されたファイルはターゲットからも削除（--delete）

set -euo pipefail

# カラー出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# デフォルト値
SKIP_DESIGN_DOCS=false
DRY_RUN=false
TARGET_DIR="$HOME/.claude"

# ユーティリティ
log_info() { echo -e "${GREEN}$*${NC}"; }
log_warn() { echo -e "${YELLOW}$*${NC}"; }
log_err() { echo -e "${RED}$*${NC}"; }

backup_file() {
    local path="$1"
    [[ -e "$path" ]] || return 0

    local bak="${path}.bak"
    if [[ -e "$bak" ]]; then
        bak="${path}.bak.$(date +%Y%m%d%H%M%S)"
    fi

    if [[ "$DRY_RUN" == true ]]; then
        echo "  - would backup: $path -> $bak"
        return 0
    fi

    mv "$path" "$bak"
}

# ヘルプ表示
show_help() {
    cat << EOF
使用方法: ./install.sh [オプション]

オプション:
  -t, --target <dir>    インストール先ディレクトリを指定
                        (デフォルト: ~/.claude)
  --skip-design-docs    design-docワークフロー関連をスキップ
                        (hearing, requirements, architecture, design*,
                         database, api, implementation, shared)
  -n, --dry-run         ドライランモード（変更を適用せずプレビュー）
  -h, --help            このヘルプを表示

例:
  ./install.sh                          # ~/.claude にインストール
  ./install.sh -t ~/my-claude           # ~/my-claude にインストール
  ./install.sh --skip-design-docs       # design-doc関連を除外
  ./install.sh -t /tmp/test --skip-design-docs
EOF
    exit 0
}

# 引数パース
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--target)
            TARGET_DIR="$2"
            shift 2
            ;;
        --skip-design-docs)
            SKIP_DESIGN_DOCS=true
            shift
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo -e "${RED}不明なオプション: $1${NC}"
            echo "ヘルプ: ./install.sh --help"
            exit 1
            ;;
    esac
done

# スクリプトのディレクトリを取得
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
DIRS=("agents" "commands" "skills")

# rsync除外オプションを構築
EXCLUDE_OPTS=()
DESIGN_DOC_EXCLUDES=(
    "hearing*"
    "requirements*"
    "architecture*"
    "design*"
    "database*"
    "api*"
    "implementation*"
    "shared*"
)

if [[ "$SKIP_DESIGN_DOCS" == true ]]; then
    for pattern in "${DESIGN_DOC_EXCLUDES[@]}"; do
        EXCLUDE_OPTS+=("--exclude=$pattern")
    done
fi

echo "=========================================="
echo "  ai-skills インストーラー"
echo "=========================================="
echo ""
echo "ソース: $SOURCE_DIR"
echo "ターゲット: $TARGET_DIR"
if [[ "$SKIP_DESIGN_DOCS" == true ]]; then
    echo -e "${YELLOW}除外: design-docワークフロー関連${NC}"
    echo "  (hearing, requirements, architecture, design*, database, api, implementation, shared)"
fi
if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}モード: ドライラン（変更は適用されません）${NC}"
fi
echo ""

# ターゲットディレクトリが存在しない場合は作成
if [[ ! -d "$TARGET_DIR" ]]; then
    log_warn "ターゲットディレクトリを作成: $TARGET_DIR"
    mkdir -p "$TARGET_DIR"
fi

# 各ディレクトリをrsyncでコピー
for dir in "${DIRS[@]}"; do
    source_path="$SOURCE_DIR/$dir"
    target_path="$TARGET_DIR/$dir"

    if [[ ! -d "$source_path" ]]; then
        echo -e "${YELLOW}スキップ: $dir (ソースディレクトリが存在しません)${NC}"
        continue
    fi

    log_info "インストール中: $dir/"

    # rsync オプション:
    # -a: アーカイブモード（再帰的、パーミッション保持）
    # -v: 詳細出力
    # -i: 変更内容を詳細表示（itemize-changes）
    # --delete: ソースにないファイルをターゲットから削除
    # --delete-after: 転送完了後に削除（安全）
    # --progress: 進捗表示
    # 末尾の /: ディレクトリ内容をコピー
    if [[ "$DRY_RUN" == true ]]; then
        rsync -avn --delete --delete-after -i ${EXCLUDE_OPTS[@]+"${EXCLUDE_OPTS[@]}"} "$source_path/" "$target_path/"
    else
        rsync -av --delete --delete-after -i --progress ${EXCLUDE_OPTS[@]+"${EXCLUDE_OPTS[@]}"} "$source_path/" "$target_path/"
    fi

    echo ""
done

install_managed_scripts() {
    local managed_root="$TARGET_DIR/scripts/ai-skills"
    local src_base="$SOURCE_DIR/skills"

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${GREEN}インストール中: scripts/ (managed: $managed_root)${NC}"
    else
        log_info "インストール中: scripts/ (managed: $managed_root)"
        mkdir -p "$managed_root"
    fi

    # 現状は prompt-improver のみだが、今後の拡張に備えてスキャン
    local skill_dir
    for skill_dir in "$src_base"/*; do
        [[ -d "$skill_dir" ]] || continue
        local skill_name
        skill_name="$(basename "$skill_dir")"

        local script_src="$skill_dir/assets/scripts"
        [[ -d "$script_src" ]] || continue

        local script_dst="$managed_root/$skill_name"
        if [[ "$DRY_RUN" == true ]]; then
            echo "  - would sync: $script_src/ -> $script_dst/"
            rsync -avn --delete --delete-after -i \
                --exclude="__pycache__/" --exclude="*.pyc" \
                "$script_src/" "$script_dst/"
        else
            mkdir -p "$script_dst"
            rsync -av --delete --delete-after -i --progress \
                --exclude="__pycache__/" --exclude="*.pyc" \
                "$script_src/" "$script_dst/"
        fi
    done

    # Stop hook の互換ラッパーを生成（既存があれば .bak 退避）
    if [[ "$DRY_RUN" == true ]]; then
        echo "  - would ensure wrappers: $TARGET_DIR/scripts/collect_feedback.sh, $TARGET_DIR/scripts/extract_transcript.py"
        return 0
    fi

    mkdir -p "$TARGET_DIR/scripts"

    local wrapper_cf="$TARGET_DIR/scripts/collect_feedback.sh"
    local tmp_cf
    tmp_cf="$(mktemp "${wrapper_cf}.tmp.XXXXXX")"
    cat > "$tmp_cf" << 'EOF'
#!/bin/bash
# Auto-generated by ai-skills install.sh
# Backward-compatible wrapper for Stop hook: ~/.claude/scripts/collect_feedback.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${ROOT}/ai-skills/prompt-improver/collect_feedback.sh"

if [[ ! -f "$TARGET" ]]; then
  echo "Error: managed script not found: $TARGET" >&2
  echo "Hint: re-run ai-skills/install.sh" >&2
  exit 1
fi

exec "$TARGET" "$@"
EOF
    chmod +x "$tmp_cf"
    backup_file "$wrapper_cf"
    mv -f "$tmp_cf" "$wrapper_cf"

    local wrapper_py="$TARGET_DIR/scripts/extract_transcript.py"
    local tmp_py
    tmp_py="$(mktemp "${wrapper_py}.tmp.XXXXXX")"
    cat > "$tmp_py" << 'EOF'
#!/usr/bin/env python3
# Auto-generated by ai-skills install.sh
# Backward-compatible wrapper: ~/.claude/scripts/extract_transcript.py

import os
import sys

root = os.path.dirname(os.path.abspath(__file__))
target = os.path.join(root, "ai-skills", "prompt-improver", "extract_transcript.py")

if not os.path.isfile(target):
    sys.stderr.write(f"Error: managed script not found: {target}\n")
    sys.stderr.write("Hint: re-run ai-skills/install.sh\n")
    raise SystemExit(1)

os.execv(sys.executable, [sys.executable, target, *sys.argv[1:]])
EOF
    chmod +x "$tmp_py"
    backup_file "$wrapper_py"
    mv -f "$tmp_py" "$wrapper_py"

    # 実体側の実行権限も保証
    chmod +x "$managed_root/prompt-improver/collect_feedback.sh" 2>/dev/null || true
    chmod +x "$managed_root/prompt-improver/extract_transcript.py" 2>/dev/null || true
}

install_managed_scripts

echo "=========================================="
echo -e "${GREEN}インストール完了${NC}"
echo "=========================================="
echo ""
echo "インストールされたディレクトリ:"
for dir in "${DIRS[@]}"; do
    target_path="$TARGET_DIR/$dir"
    if [[ -d "$target_path" ]]; then
        count=$(find "$target_path" -type f | wc -l | tr -d ' ')
        echo "  - $target_path ($count ファイル)"
    fi
done

if [[ -d "$TARGET_DIR/scripts/ai-skills" ]]; then
    scripts_count=$(find "$TARGET_DIR/scripts/ai-skills" -type f 2>/dev/null | wc -l | tr -d ' ')
    echo "  - $TARGET_DIR/scripts/ai-skills ($scripts_count ファイル, managed --delete)"
fi
