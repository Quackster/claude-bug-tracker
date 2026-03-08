Read `BUGS.md` in the project root. Add or **overwrite** the bug entry with the details described below, using this format:

```
# Bug Tracker

## Status: ACTIVE

### Bug Description
<What was reported, including any files, error messages, or behavior mentioned>

### Reproduction
<Steps or conditions to trigger it, if known from the description>

### Findings
<Key discoveries, root cause analysis, what you've tried>

### Files Involved
<List of relevant files>
```

Then begin investigating the bug. As you investigate and work on it, **keep updating the Findings section** of `BUGS.md` with important discoveries. This ensures future Claude sessions (after compaction) have full context. Update after each significant finding or attempted fix.

Once the bug is confirmed fixed:
1. Change `## Status: ACTIVE` to `## Status: FIXED`
2. Add a `### Resolution` section explaining what fixed it
3. After marking FIXED, **stop** actively working on the bug unless the user gives new instructions

**Important:** NEVER include `BUGS.md` in git commits unless the user explicitly asks you to. When committing, staging, or handling git operations, always exclude `BUGS.md`. It is a local working file, not part of the codebase.

The bug description is: $ARGUMENTS
