#!/bin/bash
# focus-terminal.sh - Bring terminal window to front on notification click
# Usage: ./focus-terminal.sh "TERM_PROGRAM=iTerm.app;BUNDLE_ID=com.googlecode.iterm2;TMUX_PANE=%1;"
#
# Called by terminal-notifier via -execute option

set -euo pipefail

# Parse context from argument
CONTEXT="${1:-}"

# Extract values from context string
extract_value() {
    local key="$1"
    echo "$CONTEXT" | grep -oP "${key}=\K[^;]*" 2>/dev/null || echo ""
}

TERM_PROGRAM="$(extract_value 'TERM_PROGRAM')"
BUNDLE_ID="$(extract_value 'BUNDLE_ID')"
TMUX_PANE="$(extract_value 'TMUX_PANE')"
TMUX_SESSION="$(extract_value 'TMUX_SESSION')"

# Default bundle ID
BUNDLE_ID="${BUNDLE_ID:-com.apple.Terminal}"

# Activate terminal application
activate_terminal() {
    case "$TERM_PROGRAM" in
        "Apple_Terminal")
            osascript -e 'tell application "Terminal" to activate' 2>/dev/null || true
            ;;
        "iTerm.app")
            osascript -e 'tell application "iTerm2" to activate' 2>/dev/null || true
            ;;
        *)
            # Generic activation via bundle ID
            open -b "$BUNDLE_ID" 2>/dev/null || true
            ;;
    esac
}

# Focus tmux pane if applicable
focus_tmux_pane() {
    if [[ -z "$TMUX_PANE" ]]; then
        return 0
    fi

    # Try to select the pane
    # Note: This works best when there's a single tmux client
    if command -v tmux &>/dev/null; then
        # Select the window containing the pane
        tmux select-pane -t "$TMUX_PANE" 2>/dev/null || true
    fi
}

# Main
activate_terminal
focus_tmux_pane

exit 0
