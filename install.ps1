# Claude Bug Tracker - Installer (Windows PowerShell)
# Merges hooks into existing .claude/settings.json without overwriting

$ErrorActionPreference = "Stop"
$Marker = "# --- Claude Bug Tracker ---"

Write-Host "Installing Claude Bug Tracker..."

# 1. Create BUGS.md if it doesn't exist
if (-not (Test-Path "BUGS.md")) {
    @"
# Bug Tracker

_No active bugs. When a "NEW BUG" marker is found, details will be logged here._
"@ | Set-Content -Path "BUGS.md" -Encoding UTF8
    Write-Host "  Created BUGS.md"
} else {
    Write-Host "  BUGS.md already exists, skipping"
}

# 2. Append bug tracker instructions to CLAUDE.md (skip if already installed)
$claudeMdExists = Test-Path "CLAUDE.md"
$alreadyInstalled = $false
if ($claudeMdExists) {
    $content = Get-Content "CLAUDE.md" -Raw -ErrorAction SilentlyContinue
    if ($content -and $content.Contains($Marker)) {
        $alreadyInstalled = $true
    }
}

if (-not $alreadyInstalled) {
    $instructions = @"

# --- Claude Bug Tracker ---

# Bug Tracking Protocol

## Detection
Whenever you encounter the text ``NEW BUG`` anywhere in code (comments, strings, variable names, etc.), immediately:
1. Read ``BUGS.md`` in the project root
2. Add or **overwrite** the bug entry with the current bug details using this format:

``````
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
``````

## Updating Findings
As you investigate and work on the bug, **keep updating the Findings section** of ``BUGS.md`` with important discoveries. This ensures future Claude sessions (after compaction) have full context. Update after each significant finding or attempted fix.

## Marking Fixed
Once the bug is confirmed fixed:
1. Change ``## Status: ACTIVE`` to ``## Status: FIXED``
2. Add a ``### Resolution`` section explaining what fixed it
3. Remove the ``NEW BUG`` marker from the source code
4. After marking FIXED, **stop** actively working on the bug unless the user gives new instructions

## Post-Compaction
After any compaction, you will receive the contents of ``BUGS.md`` via hook. If the status is ACTIVE, resume investigating/fixing the bug. If FIXED, no action needed.
"@
    Add-Content -Path "CLAUDE.md" -Value $instructions -Encoding UTF8
    Write-Host "  Appended bug tracker instructions to CLAUDE.md"
} else {
    Write-Host "  CLAUDE.md already has bug tracker instructions, skipping"
}

# 3. Merge hooks into .claude/settings.json
if (-not (Test-Path ".claude")) {
    New-Item -ItemType Directory -Path ".claude" | Out-Null
}

$settingsPath = ".claude/settings.json"
if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
} else {
    $settings = [PSCustomObject]@{}
}

# Ensure hooks structure exists
if (-not ($settings.PSObject.Properties.Name -contains "hooks")) {
    $settings | Add-Member -NotePropertyName "hooks" -NotePropertyValue ([PSCustomObject]@{})
}
if (-not ($settings.hooks.PSObject.Properties.Name -contains "Stop")) {
    $settings.hooks | Add-Member -NotePropertyName "Stop" -NotePropertyValue @()
}
if (-not ($settings.hooks.PSObject.Properties.Name -contains "SessionStart")) {
    $settings.hooks | Add-Member -NotePropertyName "SessionStart" -NotePropertyValue @()
}

$stopCmd = 'bash -c "if [ -f BUGS.md ] && grep -q ''Status: ACTIVE'' BUGS.md; then echo ''--- ACTIVE BUG CONTEXT (from BUGS.md) ---''; cat BUGS.md; echo ''--- END BUGS.md ---''; fi"'
$sessionCmd = 'bash -c "if [ -f BUGS.md ] && grep -q ''Status: ACTIVE'' BUGS.md; then echo ''--- ACTIVE BUG (resume investigation) ---''; cat BUGS.md; echo ''--- END BUGS.md ---''; fi"'

# Check if hooks already exist (by command substring)
function Test-HookExists($hookArray, $signature) {
    foreach ($entry in $hookArray) {
        foreach ($h in $entry.hooks) {
            if ($h.command -and $h.command.Contains($signature)) {
                return $true
            }
        }
    }
    return $false
}

if (-not (Test-HookExists $settings.hooks.Stop "ACTIVE BUG CONTEXT")) {
    $stopHook = [PSCustomObject]@{
        matcher = ""
        hooks = @([PSCustomObject]@{ type = "command"; command = $stopCmd })
    }
    $settings.hooks.Stop = @($settings.hooks.Stop) + @($stopHook)
}

if (-not (Test-HookExists $settings.hooks.SessionStart "ACTIVE BUG")) {
    $sessionHook = [PSCustomObject]@{
        matcher = ""
        hooks = @([PSCustomObject]@{ type = "command"; command = $sessionCmd })
    }
    $settings.hooks.SessionStart = @($settings.hooks.SessionStart) + @($sessionHook)
}

$settings | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath -Encoding UTF8
Write-Host "  Merged hooks into .claude/settings.json"

Write-Host ""
Write-Host "Done! Claude Bug Tracker installed."
Write-Host "Add '// NEW BUG: description' anywhere in your code to start tracking."
