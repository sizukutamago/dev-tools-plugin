#!/bin/bash
# notify.sh - Common notification backend for macOS
# Usage: TITLE="title" MESSAGE="message" ./notify.sh [--with-focus]
#
# Environment variables:
#   CLAUDE_NOTIFY=0      Disable notifications
#   CLAUDE_NOTIFY_SOUND  Notification sound (default: "default")

set -euo pipefail

# Check if notifications are disabled
if [[ "${CLAUDE_NOTIFY:-1}" == "0" ]]; then
    exit 0
fi

# Get script directory for focus-terminal.sh path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
TITLE="${TITLE:-Claude Code}"
MESSAGE="${MESSAGE:-}"
SOUND="${CLAUDE_NOTIFY_SOUND:-default}"
WITH_FOCUS="${1:-}"

# Find terminal-notifier (PATH issues in hooks environment)
find_notifier() {
    if command -v terminal-notifier &>/dev/null; then
        echo "terminal-notifier"
    elif [[ -x /opt/homebrew/bin/terminal-notifier ]]; then
        echo "/opt/homebrew/bin/terminal-notifier"
    elif [[ -x /usr/local/bin/terminal-notifier ]]; then
        echo "/usr/local/bin/terminal-notifier"
    else
        echo ""
    fi
}

# Get terminal app bundle ID
get_bundle_id() {
    case "${TERM_PROGRAM:-}" in
        "Apple_Terminal") echo "com.apple.Terminal" ;;
        "iTerm.app") echo "com.googlecode.iterm2" ;;
        "WarpTerminal") echo "dev.warp.Warp-Stable" ;;
        *) echo "com.apple.Terminal" ;;  # fallback
    esac
}

# Capture context for focus-terminal.sh
capture_context() {
    local context=""
    context+="TERM_PROGRAM=${TERM_PROGRAM:-};"
    context+="BUNDLE_ID=$(get_bundle_id);"

    # tmux context if available
    if [[ -n "${TMUX:-}" ]]; then
        context+="TMUX_PANE=${TMUX_PANE:-};"
        context+="TMUX_SESSION=$(tmux display-message -p '#{session_name}' 2>/dev/null || echo '');"
    fi

    echo "$context"
}

# Send notification
send_notification() {
    local notifier
    notifier="$(find_notifier)"

    if [[ -n "$notifier" ]]; then
        local args=(
            -title "$TITLE"
            -message "$MESSAGE"
            -sound "$SOUND"
        )

        # Add click-to-focus if requested
        if [[ "$WITH_FOCUS" == "--with-focus" ]]; then
            local bundle_id
            bundle_id="$(get_bundle_id)"
            local context
            context="$(capture_context)"

            args+=(-activate "$bundle_id")
            args+=(-execute "bash '$SCRIPT_DIR/focus-terminal.sh' '$context'")
        fi

        "$notifier" "${args[@]}"
    else
        # Fallback to osascript (no click-to-focus support)
        osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" sound name \"$SOUND\""
    fi
}

# Main
if [[ -z "$MESSAGE" ]]; then
    echo "Error: MESSAGE is required" >&2
    exit 1
fi

send_notification
