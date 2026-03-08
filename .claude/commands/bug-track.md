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

### Files Involved
<List of relevant files>

### Watchlist
<Files modified as part of the fix — auto-maintained, see below>
```

Omit the `### Watchlist` section if `--no-watchlist` was passed.
Add `### Branch` with the branch name if `--branch` was passed.

## Step 3: Reproduce

Before diving into code, **try to reproduce the bug first**. Actually run the relevant code, trigger the described behavior, and confirm the bug exists. Document what you did and what happened in the `### Reproduction` section. This is critical — don't skip it.

## Step 4: Investigate and fix

Begin investigating. As you work, **keep updating `BUGS.md`**:
- Update `### Findings` after each significant discovery or attempted fix
- Update `### Files Involved` as you identify relevant files
- If watchlist is enabled: every time you **edit a file** as part of the fix, add its path to `### Watchlist` (no duplicates). This helps future sessions detect potential regressions.

This ensures future Claude sessions (after compaction) have full context.

## Step 5: Mark fixed

Once the bug is confirmed fixed:
1. Change `## Status: ACTIVE` to `## Status: FIXED`
2. Add a `### Resolution` section explaining what fixed it
3. After marking FIXED, **stop** actively working on the bug unless the user gives new instructions

## Git rules

**NEVER** include `BUGS.md` in git commits unless the user explicitly asks you to. When committing, staging, or handling git operations, always exclude `BUGS.md`. It is a local working file, not part of the codebase.

---

The user's input is: $ARGUMENTS
