## Arguments

Parse `$ARGUMENTS` for the following flags. Flags can appear anywhere in the arguments — everything that isn't a flag is the bug description.

| Flag | Default | Effect |
|------|---------|--------|
| `--no-watchlist` | watchlist ON | Disable the file watchlist |
| `--branch` | OFF | Create a `bugfix/<short-description>` git branch before investigating |

Examples:
- `/bug-track "login crashes on empty email"` — watchlist on, no branch
- `/bug-track --branch "login crashes on empty email"` — watchlist on, branch created
- `/bug-track --no-watchlist --branch "login crashes"` — no watchlist, branch created

---

## Step 0: Project setup

Before doing anything else, ensure the current project has the bug tracker infrastructure. Check for and create the following if they don't already exist:

1. **`.claude/` directory** — create it if missing
2. **`.claude/hooks/` directory** — create it if missing
3. **`.claude/hooks/stop-hook.sh`** — create with this content:
   ```bash
   #!/usr/bin/env bash
   # Claude Bug Tracker - Stop hook
   # Re-injects BUGS.md context after compaction if a bug is active

   if [ -f BUGS.md ] && grep -q 'Status: ACTIVE' BUGS.md; then
     echo '--- ACTIVE BUG ---'
     echo 'Resume investigating the bug below. Read BUGS.md first to pick up where you left off.'
     echo 'If the user provided new information in their last message, update BUGS.md with it IMMEDIATELY before doing anything else.'
     echo 'Keep updating BUGS.md with findings as you work.'
     echo 'IMPORTANT: NEVER include BUGS.md in git commits unless explicitly asked.'
     echo ''
     cat BUGS.md
     echo '--- END BUGS.md ---'
   fi
   ```
4. **`.claude/hooks/stop-hook.cmd`** — create with this content (Windows wrapper):
   ```cmd
   @echo off
   REM Wrapper to run bash script on Windows
   "C:\Program Files\Git\bin\bash.exe" "%~dp0stop-hook.sh"
   ```
5. **`.claude/settings.json`** — if missing, create it with the Stop hook configured. If it already exists, read it and **merge** the Stop hook entry into the existing hooks (don't overwrite other settings):
   ```json
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
   ```

Skip any files that already exist with the correct content. After setup, briefly note what was created (if anything) before continuing.

---

## Step 1: Branch (only if `--branch`)

If the `--branch` flag is present:
1. Create and checkout a new branch: `bugfix/<short-kebab-description>` (e.g. `bugfix/login-crash-empty-email`)
2. Note the branch name in BUGS.md under `### Branch`

If `--branch` is NOT present, skip this step entirely.

## Step 2: Log the bug

Read `BUGS.md` in the project root. Add or **overwrite** the bug entry using this format:

```
# Bug Tracker

## Status: ACTIVE

### Bug Description
<What was reported, including any files, error messages, or behavior mentioned>

### Reproduction
<Steps or conditions to reproduce — try to actually reproduce the bug before investigating. Run the app, trigger the error, confirm the behavior. Document exact steps, commands, inputs, and observed vs expected output. If you cannot reproduce it, note that and explain what you tried.>

### Findings
<Key discoveries, root cause analysis, what you've tried>

### Hypotheses
| # | Hypothesis | Status | Result |
|---|-----------|--------|--------|
| 1 | <what you think might be causing the bug> | TESTING / CONFIRMED / REJECTED | <what you found> |

### Files Involved
<List of relevant files>

### Watchlist
<Files modified as part of the fix — auto-maintained, see below>
```

Omit the `### Watchlist` section if `--no-watchlist` was passed.
Add `### Branch` with the branch name if `--branch` was passed.

**Context enrichment:** After reading BUGS.md, check if you already have useful context from the current conversation that isn't captured there yet — e.g., error messages the user shared, files you've already explored, environment details, hypotheses discussed, or anything else that would help a future session (or yourself after compaction) pick up where you left off. Add any such information to the relevant sections of BUGS.md before moving on.

## Step 3: Reproduce

Before diving into code, **try to reproduce the bug first**. Actually run the relevant code, trigger the described behavior, and confirm the bug exists. Document what you did and what happened in the `### Reproduction` section. This is critical — don't skip it.

## Step 4: Investigate and fix

Begin investigating. As you work, **keep updating `BUGS.md`**:
- Update `### Findings` after each significant discovery or attempted fix
- Update `### Files Involved` as you identify relevant files
- If watchlist is enabled: every time you **edit a file** as part of the fix, add its path to `### Watchlist` (no duplicates). This helps future sessions detect potential regressions.

This ensures future Claude sessions (after compaction) have full context.

**Hypothesis rule:** Before testing any theory about the bug's cause, write it down in the `### Hypotheses` table first with status `TESTING`. After testing, update the status to `CONFIRMED` or `REJECTED` and fill in the result. Never test a hypothesis without logging it. Never move on without updating the status. This prevents you from going in circles — after compaction, you won't remember what you already tried, but the table will tell you. If you find yourself forming a hypothesis that's already in the table, you're going in circles — stop and reassess.

**Repeated rediscovery rule:** If you find yourself looking up, re-deriving, or re-confirming the same piece of information more than once during investigation (e.g., a config value, an API behavior, a file's role, a non-obvious code path), write it into `### Findings` in BUGS.md immediately. Information that had to be discovered twice will have to be discovered again after compaction — BUGS.md survives compaction, your memory does not. When in doubt, write it down.

**Workarounds rule:** If you discover alternative ways to test, verify, or reproduce something (e.g., a manual CLI command that triggers the same code path, a way to mock a dependency, a debug flag that exposes state, a curl request that simulates a UI action), document it in `### Findings` immediately. Include the exact command or steps so they can be reused. These testing workarounds are hard-won knowledge that is easily lost to compaction. Future sessions must not waste time re-figuring out how to test the same thing.

## Interruption rule

If the user interrupts you at any point with new information about the bug — additional context, error messages, reproduction details, corrections, environment info, or anything else relevant — you MUST update BUGS.md with that information **immediately, before doing anything else**. Write it into the appropriate section (`### Bug Description`, `### Reproduction`, `### Findings`, etc.). Do not continue investigating, do not respond with analysis, do not run commands — update BUGS.md first.

Why: BUGS.md is the single source of truth that survives compaction. If the user gives you a critical clue and you act on it without writing it down, that clue is lost forever when context compacts. The user should never have to repeat themselves.

After updating BUGS.md, briefly confirm what you recorded, then resume your work.

## Step 5: Verify and mark fixed

**DO NOT mark the bug as FIXED until you have rigorously verified the fix.** Being meticulous here is critical — a sloppy "it looks fixed" is worse than leaving it ACTIVE.

Before changing the status to FIXED, you MUST complete ALL of the following:

1. **Re-run the exact reproduction steps** from `### Reproduction` and confirm the bug no longer occurs. Document the output/result.
2. **Run the project's relevant tests** (unit tests, integration tests, etc.) to confirm nothing is broken. If no automated tests exist for this area, manually test related functionality.
3. **Check for regressions** — verify that the fix doesn't break adjacent behavior. Think about edge cases and related code paths.
4. **Document your verification** — add a `### Verification` section to BUGS.md with:
   - Exact commands/steps you ran to verify
   - The output or observed behavior proving the fix works
   - Any tests that passed/failed
5. Only THEN change `## Status: ACTIVE` to `## Status: FIXED`
6. Add a `### Resolution` section explaining what the root cause was and what fixed it
7. After marking FIXED, **stop** actively working on the bug unless the user gives new instructions

**If you cannot reproduce the original bug to begin with**, do NOT mark it as FIXED. Leave it ACTIVE and note what you tried in `### Findings`. Ask the user for guidance.

**If verification fails**, do NOT mark it as FIXED. Update `### Findings` with what went wrong and continue investigating.

## Git rules

**NEVER** include `BUGS.md` in git commits unless the user explicitly asks you to. When committing, staging, or handling git operations, always exclude `BUGS.md`. It is a local working file, not part of the codebase.

---

The user's input is: $ARGUMENTS
