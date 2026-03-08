# Claude Code Bug Tracker Plugin

A slash command plugin for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that gives Claude persistent bug tracking across compactions.

## How it works

1. Run `/bug-track "description"` in your Claude Code prompt
2. Claude logs the bug in `BUGS.md` with `Status: ACTIVE` and starts investigating
3. As Claude works, it keeps `BUGS.md` updated with findings
4. If context compacts, hooks re-inject `BUGS.md` so Claude picks up where it left off
5. Once fixed, Claude marks it `FIXED` and stops

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
3. Merges a `Stop` hook into `.claude/settings.json` for context survival across compactions

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
2. Create an empty `BUGS.md` in your project root
3. Optionally add the hooks from `.claude/settings.json` to your project for compaction survival

## Uninstall

1. Delete `~/.claude/commands/bug-track.md` (or `.claude/commands/bug-track.md` for project install)
2. Remove the bug tracker hooks from `.claude/settings.json` (the ones with `ACTIVE BUG` in the command)
3. Delete `BUGS.md` if desired
