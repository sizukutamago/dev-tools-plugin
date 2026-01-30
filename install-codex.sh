#!/bin/bash
# install-codex.sh - Codex 側スキル（claude-collab）をインストール
#
# 使用方法:
#   ./install-codex.sh [オプション]
#
# オプション:
#   -t, --target <dir>    インストール先ディレクトリを指定
#                         (デフォルト: ~/.codex/skills)
#   -h, --help            ヘルプを表示
#
# 動作:
#   - codex-skills/ を ~/.codex/skills/ 以下にコピー
#   - 既存ファイルは上書き
#   - 他のファイル/ディレクトリは保持（マージ動作）
#
# 前提条件:
#   - Codex CLI がインストールされていること
#   - OPENAI_API_KEY が設定されていること

set -euo pipefail

# カラー出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# デフォルト値
TARGET_DIR="$HOME/.codex/skills"

# ヘルプ表示
show_help() {
    cat << 'EOF'
使用方法: ./install-codex.sh [オプション]

Codex 側の claude-collab スキルをインストールします。
このスキルは Claude Code との双方向ペアプログラミングを可能にします。

オプション:
  -t, --target <dir>    インストール先ディレクトリを指定
                        (デフォルト: ~/.codex/skills)
  -h, --help            このヘルプを表示

前提条件:
  1. Codex CLI がインストールされていること
     npm install -g @openai/codex

  2. OPENAI_API_KEY が環境変数に設定されていること
     export OPENAI_API_KEY="sk-..."

例:
  ./install-codex.sh                        # ~/.codex/skills にインストール
  ./install-codex.sh -t ~/my-codex/skills   # カスタムパスにインストール

インストール後:
  Codex CLI でスキルが認識されることを確認:
  codex --ask-for-approval never "List available skills"
EOF
    exit 0
}

# 前提条件チェック
check_prerequisites() {
    local has_error=false

    echo -e "${BLUE}前提条件をチェック中...${NC}"
    echo ""

    # Codex CLI チェック
    if command -v codex &> /dev/null; then
        local codex_version
        codex_version=$(codex --version 2>/dev/null || echo "unknown")
        echo -e "  ${GREEN}✓${NC} Codex CLI: $codex_version"
    else
        echo -e "  ${RED}✗${NC} Codex CLI がインストールされていません"
        echo -e "    ${YELLOW}インストール: npm install -g @openai/codex${NC}"
        has_error=true
    fi

    # OPENAI_API_KEY チェック
    if [[ -n "${OPENAI_API_KEY:-}" ]]; then
        local key_preview="${OPENAI_API_KEY:0:7}..."
        echo -e "  ${GREEN}✓${NC} OPENAI_API_KEY: $key_preview (設定済み)"
    else
        echo -e "  ${RED}✗${NC} OPENAI_API_KEY が設定されていません"
        echo -e "    ${YELLOW}設定: export OPENAI_API_KEY=\"sk-...\"${NC}"
        has_error=true
    fi

    # tmux チェック（推奨）
    if command -v tmux &> /dev/null; then
        local tmux_version
        tmux_version=$(tmux -V 2>/dev/null || echo "unknown")
        echo -e "  ${GREEN}✓${NC} tmux: $tmux_version (推奨)"
    else
        echo -e "  ${YELLOW}△${NC} tmux がインストールされていません（推奨）"
        echo -e "    ${YELLOW}インストール: brew install tmux / apt install tmux${NC}"
    fi

    echo ""

    if [[ "$has_error" == true ]]; then
        echo -e "${RED}前提条件が満たされていません。${NC}"
        echo "上記のエラーを解決してから再実行してください。"
        exit 1
    fi
}

# 引数パース
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--target)
            TARGET_DIR="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo -e "${RED}不明なオプション: $1${NC}"
            echo "ヘルプ: ./install-codex.sh --help"
            exit 1
            ;;
    esac
done

# スクリプトのディレクトリを取得
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_SKILLS_DIR="$SOURCE_DIR/codex-skills"

echo "=========================================="
echo "  Codex スキル インストーラー"
echo "=========================================="
echo ""

# 前提条件チェック
check_prerequisites

echo "ソース: $SOURCE_SKILLS_DIR"
echo "ターゲット: $TARGET_DIR"
echo ""

# ソースディレクトリ確認
if [[ ! -d "$SOURCE_SKILLS_DIR" ]]; then
    echo -e "${RED}エラー: ソースディレクトリが見つかりません: $SOURCE_SKILLS_DIR${NC}"
    exit 1
fi

# ターゲットディレクトリが存在しない場合は作成
if [[ ! -d "$TARGET_DIR" ]]; then
    echo -e "${YELLOW}ターゲットディレクトリを作成: $TARGET_DIR${NC}"
    mkdir -p "$TARGET_DIR"
fi

# スキルをコピー
echo -e "${GREEN}インストール中: claude-collab/${NC}"

# rsync オプション:
# -a: アーカイブモード（再帰的、パーミッション保持）
# -v: 詳細出力
# --progress: 進捗表示
rsync -av --progress "$SOURCE_SKILLS_DIR/" "$TARGET_DIR/"

echo ""
echo "=========================================="
echo -e "${GREEN}インストール完了${NC}"
echo "=========================================="
echo ""

# インストール結果表示
echo "インストールされたスキル:"
for skill_dir in "$TARGET_DIR"/*/; do
    if [[ -d "$skill_dir" ]]; then
        skill_name=$(basename "$skill_dir")
        file_count=$(find "$skill_dir" -type f | wc -l | tr -d ' ')
        echo "  - $skill_name ($file_count ファイル)"
    fi
done

echo ""
echo "=========================================="
echo -e "${BLUE}次のステップ${NC}"
echo "=========================================="
echo ""
echo "1. Claude Code 側のスキルもインストール:"
echo "   ./install.sh"
echo ""
echo "2. Codex でスキルが認識されることを確認:"
echo "   codex --ask-for-approval never \"List available skills\""
echo ""
echo "3. ペアプログラミングを開始:"
echo "   Claude Code で /codex-collab を実行"
echo ""
