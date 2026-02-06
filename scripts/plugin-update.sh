#!/usr/bin/env bash
# plugin-update.sh - dev-tools-plugin の確実なアップデート
#
# 使用法:
#   ./scripts/plugin-update.sh              # キャッシュクリア + 再インストール
#   ./scripts/plugin-update.sh --bump       # パッチバージョンバンプ + commit + push + 再インストール
#   ./scripts/plugin-update.sh --dev        # 開発モード案内（--plugin-dir）
#
# 背景:
#   claude plugin update にはキャッシュ無効化のバグがあり（#14061, #19197）、
#   バージョンを変えてもファイルが更新されないことがある。
#   このスクリプトはキャッシュを手動クリアして確実に最新版を反映する。

set -euo pipefail

PLUGIN_NAME="dev-tools-plugin"
MARKETPLACE_NAME="dev-tools-plugin"
FULL_NAME="${PLUGIN_NAME}@${MARKETPLACE_NAME}"
CACHE_DIR="$HOME/.claude/plugins/cache/${MARKETPLACE_NAME}/${PLUGIN_NAME}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_JSON="$PLUGIN_ROOT/.claude-plugin/plugin.json"
MARKETPLACE_JSON="$PLUGIN_ROOT/.claude-plugin/marketplace.json"

# 色付き出力
info()  { echo -e "\033[34m[INFO]\033[0m  $*"; }
ok()    { echo -e "\033[32m[OK]\033[0m    $*"; }
warn()  { echo -e "\033[33m[WARN]\033[0m  $*"; }
error() { echo -e "\033[31m[ERROR]\033[0m $*" >&2; }

# 現在のバージョンを取得
get_version() {
    python3 -c "import json; print(json.load(open('$PLUGIN_JSON'))['version'])"
}

# パッチバージョンをバンプ
bump_patch() {
    local current
    current="$(get_version)"
    local major minor patch
    IFS='.' read -r major minor patch <<< "$current"
    local new_version="${major}.${minor}.$((patch + 1))"

    # plugin.json を更新
    python3 -c "
import json
for f in ['$PLUGIN_JSON', '$MARKETPLACE_JSON']:
    with open(f) as fh:
        data = json.load(fh)
    if 'version' in data:
        data['version'] = '$new_version'
    elif 'plugins' in data:
        for p in data['plugins']:
            if p.get('name') == '$PLUGIN_NAME':
                p['version'] = '$new_version'
    with open(f, 'w') as fh:
        json.dump(data, fh, indent=2, ensure_ascii=False)
        fh.write('\n')
"
    echo "$new_version"
}

# キャッシュクリア + 再インストール
reinstall() {
    info "キャッシュをクリア中..."
    if [[ -d "$CACHE_DIR" ]]; then
        rm -rf "$CACHE_DIR"
        ok "キャッシュ削除: $CACHE_DIR"
    else
        warn "キャッシュが見つかりません（初回インストール？）"
    fi

    info "プラグインを再インストール中..."
    if claude plugin install "$FULL_NAME" --scope user 2>&1; then
        ok "インストール完了"
    else
        error "インストール失敗。手動で確認してください:"
        error "  claude plugin install $FULL_NAME --scope user"
        exit 1
    fi

    # インストール結果を確認
    local installed_version
    installed_version=$(python3 -c "
import json
data = json.load(open('$HOME/.claude/plugins/installed_plugins.json'))
entries = data['plugins'].get('$FULL_NAME', [])
print(entries[0]['version'] if entries else 'NOT FOUND')
" 2>/dev/null || echo "UNKNOWN")

    ok "インストール済みバージョン: $installed_version"
}

# メイン処理
case "${1:-}" in
    --bump)
        info "パッチバージョンをバンプ中..."
        old_version="$(get_version)"
        new_version="$(bump_patch)"
        ok "バージョン: $old_version → $new_version"

        info "コミット & プッシュ中..."
        cd "$PLUGIN_ROOT"
        git add .claude-plugin/plugin.json .claude-plugin/marketplace.json
        git commit -m "chore: bump version to $new_version"
        git push origin main
        ok "プッシュ完了"

        reinstall
        echo ""
        ok "完了！Claude Code を再起動して反映してください。"
        ;;

    --dev)
        echo ""
        info "開発モードでは --plugin-dir を使うとキャッシュをバイパスできます:"
        echo ""
        echo "  claude --plugin-dir $PLUGIN_ROOT"
        echo ""
        info "この方法なら、コード変更が即座に反映されます（バージョンバンプ不要）。"
        echo ""
        ;;

    --help|-h)
        echo "使用法: $0 [--bump|--dev|--help]"
        echo ""
        echo "  (引数なし)  キャッシュクリア + 再インストール"
        echo "  --bump      バージョンバンプ + commit + push + 再インストール"
        echo "  --dev       開発モードの案内（--plugin-dir）"
        echo "  --help      このヘルプを表示"
        ;;

    "")
        info "現在のバージョン: $(get_version)"
        reinstall
        echo ""
        ok "完了！Claude Code を再起動して反映してください。"
        ;;

    *)
        error "不明なオプション: $1"
        echo "  $0 --help でヘルプを表示"
        exit 1
        ;;
esac
