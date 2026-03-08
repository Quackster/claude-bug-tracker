# Claude Bug Tracker - Installer (Windows PowerShell)
# Installs /bug-track slash command + hooks for context survival

param(
    [switch]$Global,
    [switch]$Project
)

$ErrorActionPreference = "Stop"

$CommandFileName = "bug-track.md"
$CommandContent = @'
Read `BUGS.md` in the project root. Add or **overwrite** the bug entry with the details described below, using this format:

```
# Bug Tracker

## Status: ACTIVE

### Bug Description
<What was reported, including any files, error messages, or behavior mentioned>

### Reproduction
<Steps or conditions to trigger it, if known from the description>

### Findings
<Key discoveries, root cause analysis, what you have tried>

### Files Involved
<List of relevant files>
```

Then begin investigating the bug. As you investigate and work on it, **keep updating the Findings section** of `BUGS.md` with important discoveries. This ensures future Claude sessions (after compaction) have full context. Update after each significant finding or attempted fix.

Once the bug is confirmed fixed:
1. Change `## Status: ACTIVE` to `## Status: FIXED`
2. Add a `### Resolution` section explaining what fixed it
3. After marking FIXED, **stop** actively working on the bug unless the user gives new instructions

The bug description is: $ARGUMENTS
'@

Write-Host "Installing Claude Bug Tracker (/bug-track command)..."
Write-Host ""

# 1. Install the slash command
if ($Project) {
    $cmdDir = ".claude\commands"
    Write-Host "  Mode: PROJECT (current project only)"
} else {
    $cmdDir = Join-Path $env:USERPROFILE ".claude\commands"
    Write-Host "  Mode: GLOBAL (available in all projects) [default]"
}

if (-not (Test-Path $cmdDir)) {
    New-Item -ItemType Directory -Path $cmdDir -Force | Out-Null
}

$CommandContent | Set-Content -Path (Join-Path $cmdDir $CommandFileName) -Encoding UTF8
Write-Host "  Installed $(Join-Path $cmdDir $CommandFileName)"

# 2. Create BUGS.md if it doesn't exist
if (-not (Test-Path "BUGS.md")) {
    @"
# Bug Tracker

_No active bugs. Use ``/bug-track "description"`` to start tracking._
"@ | Set-Content -Path "BUGS.md" -Encoding UTF8
    Write-Host "  Created BUGS.md"
} else {
    Write-Host "  BUGS.md already exists, skipping"
}

# 3. Merge hooks into .claude/settings.json (project-level)
if (-not (Test-Path ".claude")) {
    New-Item -ItemType Directory -Path ".claude" | Out-Null
}

$settingsPath = ".claude\settings.json"
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

$stopCmd = 'powershell -NoProfile -Command "if (Test-Path BUGS.md) { $c = Get-Content BUGS.md -Raw; if ($c -match ''Status: ACTIVE'') { Write-Output ''--- ACTIVE BUG CONTEXT (from BUGS.md) ---''; Write-Output $c; Write-Output ''--- END BUGS.md ---'' } }"'

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

$settings | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath -Encoding UTF8
Write-Host "  Merged hooks into .claude/settings.json"

Write-Host ""
Write-Host "Done! Claude Bug Tracker installed."
Write-Host ""
Write-Host 'Usage:  /bug-track "the login form crashes when email contains a +"'
