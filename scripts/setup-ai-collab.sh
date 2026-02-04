#!/usr/bin/env bash
# setup-ai-collab.sh - Codex/Gemini CLI 用の設定ファイルをセットアップ
#
# 使用法:
#   ./scripts/setup-ai-collab.sh [--force]
#
# オプション:
#   --force    既存ファイルを上書き

set -euo pipefail

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"

# テンプレートファイル
AGENTS_TEMPLATE="$PLUGIN_DIR/AGENTS.md"
GEMINI_TEMPLATE="$PLUGIN_DIR/GEMINI.md"

# インストール先
CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
GEMINI_DIR="$HOME/.gemini"

CODEX_TARGET="$CODEX_DIR/AGENTS.md"
GEMINI_TARGET="$GEMINI_DIR/GEMINI.md"

# オプション
FORCE=0

usage() {
    cat <<EOF
使用法: $(basename "$0") [OPTIONS]

Codex CLI と Gemini CLI 用の設定ファイルをセットアップします。

オプション:
    --force, -f    既存ファイルを上書き
    --help, -h     このヘルプを表示

インストール先:
    Codex:  $CODEX_TARGET
    Gemini: $GEMINI_TARGET
EOF
}

log_info() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

# テンプレートファイルの存在確認
check_templates() {
    local missing=0

    if [[ ! -f "$AGENTS_TEMPLATE" ]]; then
        log_error "AGENTS.md テンプレートが見つかりません: $AGENTS_TEMPLATE"
        missing=1
    fi

    if [[ ! -f "$GEMINI_TEMPLATE" ]]; then
        log_error "GEMINI.md テンプレートが見つかりません: $GEMINI_TEMPLATE"
        missing=1
    fi

    return $missing
}

# ファイルをインストール
install_file() {
    local src="$1"
    local dst="$2"
    local name="$3"
    local dir
    dir="$(dirname "$dst")"

    # ディレクトリ作成
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        log_info "$dir ディレクトリを作成しました"
    fi

    # 既存ファイルチェック
    if [[ -f "$dst" ]]; then
        if (( FORCE )); then
            # バックアップ作成
            local backup="${dst}.backup.$(date +%Y%m%d%H%M%S)"
            cp "$dst" "$backup"
            log_warn "既存ファイルをバックアップ: $backup"
        else
            log_warn "$name: 既存ファイルをスキップ (--force で上書き)"
            return 0
        fi
    fi

    # コピー
    cp "$src" "$dst"
    log_info "$name をインストールしました: $dst"
}

main() {
    # 引数解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force|-f)
                FORCE=1
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                log_error "不明なオプション: $1"
                usage
                exit 1
                ;;
        esac
    done

    echo "=== AI Collaboration セットアップ ==="
    echo ""

    # テンプレート確認
    if ! check_templates; then
        exit 1
    fi

    # Codex 設定インストール
    echo "--- Codex CLI ---"
    install_file "$AGENTS_TEMPLATE" "$CODEX_TARGET" "AGENTS.md"

    echo ""

    # Gemini 設定インストール
    echo "--- Gemini CLI ---"
    install_file "$GEMINI_TEMPLATE" "$GEMINI_TARGET" "GEMINI.md"

    echo ""
    echo "=== セットアップ完了 ==="
    echo ""
    echo "確認コマンド:"
    echo "  Codex:  cat $CODEX_TARGET"
    echo "  Gemini: cat $GEMINI_TARGET"
}

main "$@"
