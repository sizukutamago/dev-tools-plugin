#!/bin/bash
# ワンコマンドでClaude Code × Codex ペアプログラミング環境をセットアップ
# 参考: https://note.com/astropomeai/n/n387c8e719846

set -euo pipefail

SESSION_NAME="${1:-pair-prog}"
WORK_DIR="${2:-$(pwd)}"

# 色定義
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# ヘルプ
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    cat << 'EOF'
Usage: setup_pair_env.sh [session_name] [work_dir]

ワンコマンドでtmux内にClaude Code × Codex環境を構築します。

┌─────────────────┬─────────────────┐
│   Pane 0 (左)   │   Pane 1 (右)   │
│  🤖 Claude Code │  🤖 Codex CLI   │
│   (自動起動)    │   (自動起動)    │
└─────────────────┴─────────────────┘

Arguments:
  session_name    tmuxセッション名（デフォルト: pair-prog）
  work_dir        作業ディレクトリ（デフォルト: カレントディレクトリ）

Examples:
  ./setup_pair_env.sh
  ./setup_pair_env.sh my-feature ~/projects/app

EOF
    exit 0
fi

# 1. 既存セッション確認
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo -e "${GREEN}既存セッション '$SESSION_NAME' にアタッチします${NC}"
    exec tmux attach-session -t "$SESSION_NAME"
fi

echo -e "${GREEN}━━━ Claude Code × Codex ペアプログラミング環境 ━━━${NC}"
echo ""
echo "セッション: $SESSION_NAME"
echo "作業ディレクトリ: $WORK_DIR"
echo ""

# 2. 新規セッション作成（左ペインでclaude起動）
# Note: Claude Code は対話モードで起動（特別なフラグ不要）
tmux new-session -d -s "$SESSION_NAME" -n "pair" -c "$WORK_DIR" "claude"

# 3. 右ペイン作成（Codex自動起動）
# Note: Codex は --full-auto で自動承認モード、--sandbox で安全な実行環境
tmux split-window -h -t "$SESSION_NAME" -c "$WORK_DIR" "codex --full-auto"

# 3.5 Codex ペインに Claude 送信用エイリアスを設定
# エイリアス定義（Codex から Claude へ送信）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEND_SCRIPT="${SCRIPT_DIR}/send_to_claude.sh"

if [[ -f "$SEND_SCRIPT" ]]; then
    # エイリアス設定を Codex ペインに送信（シェル起動後に反映）
    sleep 1  # Codex 起動待ち
    tmux send-keys -t "${SESSION_NAME}:0.1" "# Claude 送信エイリアス設定中..." Enter
    tmux send-keys -t "${SESSION_NAME}:0.1" "alias ask-claude='${SEND_SCRIPT} --type QUESTION'" Enter
    tmux send-keys -t "${SESSION_NAME}:0.1" "alias suggest-claude='${SEND_SCRIPT} --type SUGGESTION'" Enter
    tmux send-keys -t "${SESSION_NAME}:0.1" "alias alert-claude='${SEND_SCRIPT} --type ALERT'" Enter
    tmux send-keys -t "${SESSION_NAME}:0.1" "alias chat-claude='${SEND_SCRIPT}'" Enter
    tmux send-keys -t "${SESSION_NAME}:0.1" "echo 'Claude 送信エイリアス設定完了: ask-claude, suggest-claude, alert-claude, chat-claude'" Enter
fi

# 4. 左ペイン（Claude）を選択
tmux select-pane -t "$SESSION_NAME:0.0"

echo -e "${CYAN}tmuxセッションにアタッチします...${NC}"
echo ""

# 5. アタッチ（execでプロセス置換）
exec tmux attach-session -t "$SESSION_NAME"
