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
