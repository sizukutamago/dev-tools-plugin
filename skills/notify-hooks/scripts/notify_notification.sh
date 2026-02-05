#!/bin/bash
# notify_notification.sh - Permission request notification
# Called by Notification hook when Claude Code needs user approval

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get project name from current directory
PROJECT_NAME="$(basename "$(pwd)")"

# Set notification content
export TITLE="Claude Code - Action Required"
export MESSAGE="Permission needed in $PROJECT_NAME"

# Use a different sound to distinguish from completion
export CLAUDE_NOTIFY_SOUND="${CLAUDE_NOTIFY_SOUND:-Ping}"

# Send notification with focus support
exec "$SCRIPT_DIR/notify.sh" --with-focus
