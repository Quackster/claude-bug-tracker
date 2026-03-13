#!/usr/bin/env bash
set -euo pipefail

# Claude Bug Tracker - Installer
# Fetches latest /bug-track slash command + Stop hook from GitHub

REPO_RAW="https://raw.githubusercontent.com/Quackster/claude-bug-tracker/master"

usage() {
  echo "Usage: install.sh [--global | --project]"
  echo ""
  echo "  --global   Install to ~/.claude/commands (available in all projects) [DEFAULT]"
  echo "  --project  Install to .claude/commands (current project only)"
  echo ""
}

MODE="global"
for arg in "$@"; do
  case "$arg" in
    --global)  MODE="global" ;;
    --project) MODE="project" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg"; usage; exit 1 ;;
  esac
done

# Check for curl
if ! command -v curl &> /dev/null; then
  echo "Error: curl is required but not found. Please install curl and try again."
  exit 1
fi

echo "Installing Claude Bug Tracker (/bug-track command)..."
echo ""

# 1. Install the slash command (fetched from GitHub)
if [ "$MODE" = "global" ]; then
  CMD_DIR="$HOME/.claude/commands"
  echo "  Mode: GLOBAL (available in all projects)"
else
  CMD_DIR=".claude/commands"
  echo "  Mode: PROJECT (current project only)"
fi

mkdir -p "$CMD_DIR"
curl -fsSL "$REPO_RAW/.claude/commands/bug-track.md" -o "$CMD_DIR/bug-track.md"
echo "  Installed $CMD_DIR/bug-track.md"

# 2. Create BUGS.md if it doesn't exist (project-level always)
if [ ! -f "BUGS.md" ]; then
  cat > BUGS.md << 'BUGSEOF'
# Bug Tracker

_No active bugs. Use `/bug-track "description"` to start tracking._
BUGSEOF
  echo "  Created BUGS.md"
else
  echo "  BUGS.md already exists, skipping"
fi

# 3. Install stop hook scripts (fetched from GitHub)
mkdir -p .claude/hooks

curl -fsSL "$REPO_RAW/.claude/hooks/stop-hook.sh" -o .claude/hooks/stop-hook.sh
chmod +x .claude/hooks/stop-hook.sh

curl -fsSL "$REPO_RAW/.claude/hooks/stop-hook.cmd" -o .claude/hooks/stop-hook.cmd

echo "  Installed .claude/hooks/stop-hook.sh"

# 4. Write .claude/settings.json with Stop hook
cat > .claude/settings.json << 'SETTINGSEOF'
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/stop-hook.sh"
          }
        ]
      }
    ]
  }
}
SETTINGSEOF

echo "  Wrote .claude/settings.json"

echo ""
echo "Done! Claude Bug Tracker installed."
echo ""
echo "Usage:  /bug-track \"the login form crashes when email contains a +\""
