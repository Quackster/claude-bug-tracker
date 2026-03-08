# Claude Code Bug Tracker Plugin

A slash command plugin for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that gives Claude persistent bug tracking across compactions.

## How it works

1. Run `/bug-track "description"` in your Claude Code prompt
2. Claude logs the bug in `BUGS.md` with `Status: ACTIVE` and starts investigating
3. As Claude works, it keeps `BUGS.md` updated with findings
4. If context compacts, hooks re-inject `BUGS.md` so Claude picks up where it left off
5. Once fixed, Claude marks it `FIXED` and stops

## Prerequisites

- [jq](https://jqlang.github.io/jq/) — `brew install jq` / `apt install jq` / `winget install jqlang.jq`
- Git Bash (Windows only — included with [Git for Windows](https://gitforwindows.org/))

## Install

### Global install (recommended — works in all projects)

**macOS / Linux / WSL:**

```bash
bash <(curl -s https://raw.githubusercontent.com/Quackster/claude-bug-tracker/master/install.sh)
```

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/Quackster/claude-bug-tracker/master/install.ps1 | iex
```

### Project-only install

If you only want it in a single project:

**macOS / Linux / WSL:**

```bash
bash <(curl -s https://raw.githubusercontent.com/Quackster/claude-bug-tracker/master/install.sh) --project
```

**Windows (PowerShell):**

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Quackster/claude-bug-tracker/master/install.ps1))) -Project
```

## What the installer does

1. Copies the `/bug-track` slash command to `~/.claude/commands/` (global) or `.claude/commands/` (project)
2. Creates `BUGS.md` in your project root (skips if exists)
3. Installs `.claude/hooks/stop-hook.sh` (+ `.cmd` wrapper for Windows)
4. Merges a `Stop` hook into `.claude/settings.json` for context survival across compactions

The installer is idempotent — running it twice won't duplicate anything.

## Usage

```
/bug-track "the login form crashes when email contains a +"
```

Claude will automatically:
- Log the bug in `BUGS.md` with status `ACTIVE`
- Begin investigating immediately
- Keep updating findings as it works
- Survive compactions via hooks
- Mark `FIXED` when resolved

## Manual install

If you prefer not to use the install script:

1. Copy `.claude/commands/bug-track.md` to `~/.claude/commands/bug-track.md` (global) or your project's `.claude/commands/` (project-only)
2. Copy `.claude/hooks/` directory into your project's `.claude/hooks/`
3. Create an empty `BUGS.md` in your project root
4. Add the Stop hook from `.claude/settings.json` to your project's settings

## Uninstall

1. Delete `~/.claude/commands/bug-track.md` (or `.claude/commands/bug-track.md` for project install)
2. Delete `.claude/hooks/stop-hook.sh` and `.claude/hooks/stop-hook.cmd`
3. Remove the bug tracker hook from `.claude/settings.json` (the one referencing `stop-hook`)
4. Delete `BUGS.md` if desired
