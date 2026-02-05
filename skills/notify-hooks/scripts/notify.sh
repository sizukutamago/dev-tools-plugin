#!/bin/bash
# notify.sh - Common notification backend for macOS
# Usage: TITLE="title" MESSAGE="message" ./notify.sh [--with-focus]
#
# Environment variables:
#   CLAUDE_NOTIFY=0      Disable notifications
#   CLAUDE_NOTIFY_SOUND  Notification sound (default: system default)

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
SOUND="${CLAUDE_NOTIFY_SOUND:-}"
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

# Capture context for focus-terminal.sh (sanitized for shell safety)
capture_context() {
    local context=""

    # Sanitize values: remove dangerous characters (;'"`$\)
    sanitize() {
        echo "$1" | tr -d ";\'\"\`\$\\\\"
    }

    local term_prog
    term_prog="$(sanitize "${TERM_PROGRAM:-}")"
    local bundle_id
    bundle_id="$(sanitize "$(get_bundle_id)")"
    local tmux_pane
    tmux_pane="$(sanitize "${TMUX_PANE:-}")"

    context="TERM_PROGRAM=${term_prog};BUNDLE_ID=${bundle_id};"

    # tmux context if available
    if [[ -n "${TMUX:-}" ]]; then
        local tmux_session
        tmux_session="$(sanitize "$(tmux display-message -p '#{session_name}' 2>/dev/null || echo '')")"
        context+="TMUX_PANE=${tmux_pane};TMUX_SESSION=${tmux_session};"
    fi

    echo "$context"
}

# Send notification via terminal-notifier
send_with_terminal_notifier() {
    local notifier="$1"
    local args=(
        -title "$TITLE"
        -message "$MESSAGE"
    )

    # Add sound if specified
    if [[ -n "$SOUND" ]]; then
        args+=(-sound "$SOUND")
    fi

    # Add click-to-focus if requested
    if [[ "$WITH_FOCUS" == "--with-focus" ]]; then
        local bundle_id
        bundle_id="$(get_bundle_id)"
        local context
        context="$(capture_context)"

        # Base64 encode context to prevent injection
        local encoded_context
        encoded_context="$(echo -n "$context" | base64)"

        args+=(-activate "$bundle_id")
        # Use a wrapper that decodes base64 safely
        # - Pass both context and script path as positional args (avoids path injection)
        # - Use printf instead of echo for portability
        # - base64 -D for macOS, -d for Linux (try -D first as this is macOS-focused)
        args+=(-execute "bash -c 'ctx=\$(printf %s \"\$1\" | base64 -D 2>/dev/null || printf %s \"\$1\" | base64 -d); exec bash \"\$2\" \"\$ctx\"' -- '$encoded_context' '$SCRIPT_DIR/focus-terminal.sh'")
    fi

    "$notifier" "${args[@]}" 2>/dev/null || true
}

# Send notification via osascript (fallback)
send_with_osascript() {
    # Use heredoc with argv to safely pass variables (prevents injection)
    if [[ -n "$SOUND" ]]; then
        osascript - "$TITLE" "$MESSAGE" "$SOUND" <<'APPLESCRIPT'
on run argv
    set theTitle to item 1 of argv
    set theMessage to item 2 of argv
    set theSound to item 3 of argv
    display notification theMessage with title theTitle sound name theSound
end run
APPLESCRIPT
    else
        osascript - "$TITLE" "$MESSAGE" <<'APPLESCRIPT'
on run argv
    set theTitle to item 1 of argv
    set theMessage to item 2 of argv
    display notification theMessage with title theTitle
end run
APPLESCRIPT
    fi
}

# Send notification
send_notification() {
    local notifier
    notifier="$(find_notifier)"

    if [[ -n "$notifier" ]]; then
        send_with_terminal_notifier "$notifier"
    else
        send_with_osascript
    fi
}

# Main
if [[ -z "$MESSAGE" ]]; then
    echo "Error: MESSAGE is required" >&2
    exit 1
fi

send_notification
