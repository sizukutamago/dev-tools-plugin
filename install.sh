#!/bin/bash
# install.sh - ai-skills を ~/.claude/ にインストール
#
# 使用方法:
#   ./install.sh
#
# 動作:
#   - agents/, commands/, skills/ を ~/.claude/ 以下にコピー
#   - 既存ファイルは上書き
#   - 他のファイル/ディレクトリは保持（マージ動作）

set -euo pipefail

# カラー出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# スクリプトのディレクトリを取得
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$HOME/.claude"
DIRS=("agents" "commands" "skills")

echo "=========================================="
echo "  ai-skills インストーラー"
echo "=========================================="
echo ""
echo "ソース: $SOURCE_DIR"
echo "ターゲット: $TARGET_DIR"
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
    # --progress: 進捗表示
    # 末尾の /: ディレクトリ内容をコピー
    rsync -av --progress "$source_path/" "$target_path/"

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
