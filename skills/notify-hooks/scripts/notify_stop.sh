#!/bin/bash
# notify_stop.sh - Task completion notification
# Called by Stop hook when Claude Code finishes a task

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get project name from current directory
PROJECT_NAME="$(basename "$(pwd)")"

# Set notification content
export TITLE="Claude Code"
export MESSAGE="Task completed in $PROJECT_NAME"

# Send notification with focus support
exec "$SCRIPT_DIR/notify.sh" --with-focus
