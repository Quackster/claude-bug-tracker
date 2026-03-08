#!/usr/bin/env bash
set -euo pipefail

# Claude Bug Tracker - Installer
# Installs /bug-track slash command + hooks for context survival

COMMAND_FILE="bug-track.md"
COMMAND_CONTENT='Read `BUGS.md` in the project root. Add or **overwrite** the bug entry with the details described below, using this format:

```
# Bug Tracker

## Status: ACTIVE

### Bug Description
<What was reported, including any files, error messages, or behavior mentioned>

### Reproduction
<Steps or conditions to trigger it, if known from the description>

### Findings
<Key discoveries, root cause analysis, what you have tried>

### Files Involved
<List of relevant files>
```

Then begin investigating the bug. As you investigate and work on it, **keep updating the Findings section** of `BUGS.md` with important discoveries. This ensures future Claude sessions (after compaction) have full context. Update after each significant finding or attempted fix.

Once the bug is confirmed fixed:
1. Change `## Status: ACTIVE` to `## Status: FIXED`
2. Add a `### Resolution` section explaining what fixed it
3. After marking FIXED, **stop** actively working on the bug unless the user gives new instructions

The bug description is: $ARGUMENTS'

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

echo "Installing Claude Bug Tracker (/bug-track command)..."
echo ""

# 1. Install the slash command
if [ "$MODE" = "global" ]; then
  CMD_DIR="$HOME/.claude/commands"
  echo "  Mode: GLOBAL (available in all projects)"
else
  CMD_DIR=".claude/commands"
  echo "  Mode: PROJECT (current project only)"
fi

mkdir -p "$CMD_DIR"
echo "$COMMAND_CONTENT" > "$CMD_DIR/$COMMAND_FILE"
echo "  Installed $CMD_DIR/$COMMAND_FILE"

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

# 3. Merge hooks into .claude/settings.json (project-level)
mkdir -p .claude

STOP_HOOK='{"matcher":"","hooks":[{"type":"command","command":"bash -c \"if [ -f BUGS.md ] && grep -q '"'"'Status: ACTIVE'"'"' BUGS.md; then echo '"'"'--- ACTIVE BUG CONTEXT (from BUGS.md) ---'"'"'; cat BUGS.md; echo '"'"'--- END BUGS.md ---'"'"'; fi\""}]}'

if command -v jq &>/dev/null; then
  if [ -f ".claude/settings.json" ]; then
    EXISTING=$(cat .claude/settings.json)
  else
    EXISTING='{}'
  fi

  echo "$EXISTING" | jq \
    --argjson stop "$STOP_HOOK" \
    '
    .hooks //= {} |
    .hooks.Stop //= [] |
    if (.hooks.Stop | map(select(.hooks[]?.command // "" | test("ACTIVE BUG CONTEXT"))) | length) == 0
      then .hooks.Stop += [$stop]
      else .
    end
    ' > .claude/settings.json.tmp && mv .claude/settings.json.tmp .claude/settings.json

  echo "  Merged hooks into .claude/settings.json (via jq)"

elif command -v python3 &>/dev/null || command -v python &>/dev/null; then
  PYTHON_CMD=$(command -v python3 || command -v python)
  "$PYTHON_CMD" << 'PYEOF'
import json, os

settings_path = ".claude/settings.json"
if os.path.exists(settings_path):
    with open(settings_path) as f:
        settings = json.load(f)
else:
    settings = {}

settings.setdefault("hooks", {})
settings["hooks"].setdefault("Stop", [])

stop_hook = {
    "matcher": "",
    "hooks": [{"type": "command", "command": 'bash -c "if [ -f BUGS.md ] && grep -q \'Status: ACTIVE\' BUGS.md; then echo \'--- ACTIVE BUG CONTEXT (from BUGS.md) ---\'; cat BUGS.md; echo \'--- END BUGS.md ---\'; fi"'}]
}

def has_hook(hook_list, signature):
    return any(signature in (h.get("hooks", [{}])[0].get("command", "") if h.get("hooks") else "") for h in hook_list)

if not has_hook(settings["hooks"]["Stop"], "ACTIVE BUG CONTEXT"):
    settings["hooks"]["Stop"].append(stop_hook)

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")
PYEOF
  echo "  Merged hooks into .claude/settings.json (via python)"

else
  echo "  ERROR: jq or python3 required to merge hooks. Install one and re-run."
  exit 1
fi

echo ""
echo "Done! Claude Bug Tracker installed."
echo ""
echo "Usage:  /bug-track \"the login form crashes when email contains a +\""
