# Claude Code Bug Tracker Plugin

A plugin for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that gives Claude persistent bug tracking across compactions.

## How it works

1. Add `NEW BUG` anywhere in your code (comment, string, etc.)
2. Claude detects it and creates a `BUGS.md` entry with `Status: ACTIVE`
3. As Claude investigates, it updates `BUGS.md` with findings
4. If context compacts, hooks re-inject `BUGS.md` so Claude picks up where it left off
5. Once fixed, Claude marks it `FIXED` and removes the `NEW BUG` marker

## Install

Run one line from your project root. The installer automatically merges hooks into your existing `.claude/settings.json` without overwriting anything.

### macOS / Linux

```bash
bash <(curl -s https://raw.githubusercontent.com/YOUR_USER/claude-bug-tracker/main/install.sh)
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/YOUR_USER/claude-bug-tracker/main/install.ps1 | iex
```

### Windows (Git Bash / WSL)

```bash
bash <(curl -s https://raw.githubusercontent.com/YOUR_USER/claude-bug-tracker/main/install.sh)
```

## What the installer does

1. Creates `BUGS.md` in your project root (skips if exists)
2. Appends bug tracker instructions to your `CLAUDE.md` (skips if already present)
3. Merges `Stop` and `SessionStart` hooks into `.claude/settings.json` (uses `jq`, falls back to `python3`/`python`)

The installer is idempotent — running it twice won't duplicate anything.

## Files

| File | Committed | Purpose |
|------|-----------|---------|
| `CLAUDE.md` | Yes | Instructions telling Claude how to track bugs |
| `BUGS.md` | Yes | Persistent bug state file (updated by Claude) |
| `.claude/settings.json` | Yes | Hooks for post-compaction context restoration |
| `install.sh` | Yes | One-line installer for macOS/Linux/WSL |
| `install.ps1` | Yes | One-line installer for Windows PowerShell |

## Usage

Just add a comment like this anywhere in your code:

```python
# NEW BUG: the login form crashes when email contains a +
```

Claude will automatically:
- Log the bug in `BUGS.md` with status `ACTIVE`
- Keep updating findings as it investigates
- Survive compactions via the `Stop` and `SessionStart` hooks
- Mark `FIXED` when resolved and remove the `NEW BUG` marker

## Uninstall

1. Remove the `# --- Claude Bug Tracker ---` section from your `CLAUDE.md`
2. Remove the bug tracker hooks from `.claude/settings.json` (the ones with `ACTIVE BUG` in the command)
3. Delete `BUGS.md`
