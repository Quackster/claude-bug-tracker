#!/usr/bin/env bash
set -euo pipefail

# Claude Bug Tracker - Installer
# Merges hooks into existing .claude/settings.json without overwriting

REPO_URL="https://raw.githubusercontent.com/YOUR_USER/claude-bug-tracker/main"
MARKER="# --- Claude Bug Tracker ---"

echo "Installing Claude Bug Tracker..."

# 1. Create BUGS.md if it doesn't exist
if [ ! -f "BUGS.md" ]; then
  cat > BUGS.md << 'BUGSEOF'
# Bug Tracker

_No active bugs. When a "NEW BUG" marker is found, details will be logged here._
BUGSEOF
  echo "  Created BUGS.md"
else
  echo "  BUGS.md already exists, skipping"
fi

# 2. Append bug tracker instructions to CLAUDE.md (skip if already installed)
if [ -f "CLAUDE.md" ] && grep -qF "$MARKER" "CLAUDE.md" 2>/dev/null; then
  echo "  CLAUDE.md already has bug tracker instructions, skipping"
else
  cat >> CLAUDE.md << 'CLAUDEEOF'

# --- Claude Bug Tracker ---

# Bug Tracking Protocol

## Detection
Whenever you encounter the text `NEW BUG` anywhere in code (comments, strings, variable names, etc.), immediately:
1. Read `BUGS.md` in the project root
2. Add or **overwrite** the bug entry with the current bug details using this format:

```
# Bug Tracker

## Status: ACTIVE

### Bug Description
<What the bug is, where "NEW BUG" was found, file and line number>

### Reproduction
<Steps or conditions to trigger it, if known>

### Findings
<Key discoveries, root cause analysis, what you've tried>

### Files Involved
<List of relevant files>
```

## Updating Findings
As you investigate and work on the bug, **keep updating the Findings section** of `BUGS.md` with important discoveries. This ensures future Claude sessions (after compaction) have full context. Update after each significant finding or attempted fix.

## Marking Fixed
Once the bug is confirmed fixed:
1. Change `## Status: ACTIVE` to `## Status: FIXED`
2. Add a `### Resolution` section explaining what fixed it
3. Remove the `NEW BUG` marker from the source code
4. After marking FIXED, **stop** actively working on the bug unless the user gives new instructions

## Post-Compaction
After any compaction, you will receive the contents of `BUGS.md` via hook. If the status is ACTIVE, resume investigating/fixing the bug. If FIXED, no action needed.
CLAUDEEOF
  echo "  Appended bug tracker instructions to CLAUDE.md"
fi

# 3. Merge hooks into .claude/settings.json
mkdir -p .claude

STOP_HOOK='{"matcher":"","hooks":[{"type":"command","command":"bash -c \"if [ -f BUGS.md ] && grep -q '"'"'Status: ACTIVE'"'"' BUGS.md; then echo '"'"'--- ACTIVE BUG CONTEXT (from BUGS.md) ---'"'"'; cat BUGS.md; echo '"'"'--- END BUGS.md ---'"'"'; fi\""}]}'
SESSION_HOOK='{"matcher":"","hooks":[{"type":"command","command":"bash -c \"if [ -f BUGS.md ] && grep -q '"'"'Status: ACTIVE'"'"' BUGS.md; then echo '"'"'--- ACTIVE BUG (resume investigation) ---'"'"'; cat BUGS.md; echo '"'"'--- END BUGS.md ---'"'"'; fi\""}]}'

if command -v jq &>/dev/null; then
  # jq available — proper JSON merge
  if [ -f ".claude/settings.json" ]; then
    EXISTING=$(cat .claude/settings.json)
  else
    EXISTING='{}'
  fi

  echo "$EXISTING" | jq \
    --argjson stop "$STOP_HOOK" \
    --argjson session "$SESSION_HOOK" \
    '
    .hooks //= {} |
    .hooks.Stop //= [] |
    .hooks.SessionStart //= [] |
    # Only add if not already present (check by command substring)
    if (.hooks.Stop | map(select(.hooks[]?.command // "" | test("ACTIVE BUG CONTEXT"))) | length) == 0
      then .hooks.Stop += [$stop]
      else .
    end |
    if (.hooks.SessionStart | map(select(.hooks[]?.command // "" | test("ACTIVE BUG.*resume"))) | length) == 0
      then .hooks.SessionStart += [$session]
      else .
    end
    ' > .claude/settings.json.tmp && mv .claude/settings.json.tmp .claude/settings.json

  echo "  Merged hooks into .claude/settings.json (via jq)"

elif command -v python3 &>/dev/null; then
  # Fallback to python3
  python3 << 'PYEOF'
import json, os, sys

settings_path = ".claude/settings.json"
if os.path.exists(settings_path):
    with open(settings_path) as f:
        settings = json.load(f)
else:
    settings = {}

settings.setdefault("hooks", {})
settings["hooks"].setdefault("Stop", [])
settings["hooks"].setdefault("SessionStart", [])

stop_hook = {
    "matcher": "",
    "hooks": [{"type": "command", "command": 'bash -c "if [ -f BUGS.md ] && grep -q \'Status: ACTIVE\' BUGS.md; then echo \'--- ACTIVE BUG CONTEXT (from BUGS.md) ---\'; cat BUGS.md; echo \'--- END BUGS.md ---\'; fi"'}]
}
session_hook = {
    "matcher": "",
    "hooks": [{"type": "command", "command": 'bash -c "if [ -f BUGS.md ] && grep -q \'Status: ACTIVE\' BUGS.md; then echo \'--- ACTIVE BUG (resume investigation) ---\'; cat BUGS.md; echo \'--- END BUGS.md ---\'; fi"'}]
}

def has_hook(hook_list, signature):
    return any(signature in (h.get("hooks", [{}])[0].get("command", "") if h.get("hooks") else "") for h in hook_list)

if not has_hook(settings["hooks"]["Stop"], "ACTIVE BUG CONTEXT"):
    settings["hooks"]["Stop"].append(stop_hook)
if not has_hook(settings["hooks"]["SessionStart"], "ACTIVE BUG"):
    settings["hooks"]["SessionStart"].append(session_hook)

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")
PYEOF
  echo "  Merged hooks into .claude/settings.json (via python3)"

elif command -v python &>/dev/null; then
  # Try python (might be python 2 or 3)
  python << 'PYEOF'
import json, os

settings_path = ".claude/settings.json"
if os.path.exists(settings_path):
    with open(settings_path) as f:
        settings = json.load(f)
else:
    settings = {}

settings.setdefault("hooks", {})
settings["hooks"].setdefault("Stop", [])
settings["hooks"].setdefault("SessionStart", [])

stop_hook = {
    "matcher": "",
    "hooks": [{"type": "command", "command": 'bash -c "if [ -f BUGS.md ] && grep -q \'Status: ACTIVE\' BUGS.md; then echo \'--- ACTIVE BUG CONTEXT (from BUGS.md) ---\'; cat BUGS.md; echo \'--- END BUGS.md ---\'; fi"'}]
}
session_hook = {
    "matcher": "",
    "hooks": [{"type": "command", "command": 'bash -c "if [ -f BUGS.md ] && grep -q \'Status: ACTIVE\' BUGS.md; then echo \'--- ACTIVE BUG (resume investigation) ---\'; cat BUGS.md; echo \'--- END BUGS.md ---\'; fi"'}]
}

def has_hook(hook_list, signature):
    return any(signature in (h.get("hooks", [{}])[0].get("command", "") if h.get("hooks") else "") for h in hook_list)

if not has_hook(settings["hooks"]["Stop"], "ACTIVE BUG CONTEXT"):
    settings["hooks"]["Stop"].append(stop_hook)
if not has_hook(settings["hooks"]["SessionStart"], "ACTIVE BUG"):
    settings["hooks"]["SessionStart"].append(session_hook)

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")
PYEOF
  echo "  Merged hooks into .claude/settings.json (via python)"

else
  echo "  ERROR: jq or python3 required to merge hooks. Install one and re-run."
  echo "         brew install jq  (macOS)  |  apt install jq  (Linux)"
  exit 1
fi

echo ""
echo "Done! Claude Bug Tracker installed."
echo "Add '// NEW BUG: description' anywhere in your code to start tracking."
