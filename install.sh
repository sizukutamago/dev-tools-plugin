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
    echo -e "${YELLOW}ターゲットディレクトリを作成: $TARGET_DIR${NC}"
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

    echo -e "${GREEN}インストール中: $dir/${NC}"

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
