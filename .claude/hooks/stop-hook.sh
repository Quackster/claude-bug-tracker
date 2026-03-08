#!/usr/bin/env bash
# Claude Bug Tracker - Stop hook
# Re-injects BUGS.md context after compaction if a bug is active

if [ -f BUGS.md ] && grep -q 'Status: ACTIVE' BUGS.md; then
  echo '--- ACTIVE BUG ---'
  echo 'Resume investigating the bug below. Keep updating BUGS.md with findings as you work.'
  echo 'IMPORTANT: NEVER include BUGS.md in git commits unless explicitly asked.'
  echo ''
  cat BUGS.md
  echo '--- END BUGS.md ---'
fi