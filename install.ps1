# Claude Bug Tracker - Installer (Windows PowerShell)
# Fetches latest /bug-track slash command + Stop hook from GitHub

param(
    [switch]$Global,
    [switch]$Project
)

$ErrorActionPreference = "Stop"

$RepoRaw = "https://raw.githubusercontent.com/Quackster/claude-bug-tracker/master"

Write-Host "Installing Claude Bug Tracker (/bug-track command)..."
Write-Host ""

# 1. Install the slash command (fetched from GitHub)
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

$cmdPath = Join-Path $cmdDir "bug-track.md"
Invoke-WebRequest -Uri "$RepoRaw/.claude/commands/bug-track.md" -OutFile $cmdPath -UseBasicParsing
Write-Host "  Installed $cmdPath"

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

# 3. Install stop hook scripts (fetched from GitHub)
$hooksDir = ".claude\hooks"
if (-not (Test-Path $hooksDir)) {
    New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
}

Invoke-WebRequest -Uri "$RepoRaw/.claude/hooks/stop-hook.sh" -OutFile (Join-Path $hooksDir "stop-hook.sh") -UseBasicParsing
Invoke-WebRequest -Uri "$RepoRaw/.claude/hooks/stop-hook.cmd" -OutFile (Join-Path $hooksDir "stop-hook.cmd") -UseBasicParsing

Write-Host "  Installed .claude\hooks\stop-hook.sh"

# 4. Write .claude/settings.json with Stop hook
$settingsPath = ".claude\settings.json"

@'
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
'@ | Set-Content -Path $settingsPath -Encoding UTF8
Write-Host "  Wrote .claude/settings.json"

Write-Host ""
Write-Host "Done! Claude Bug Tracker installed."
Write-Host ""
Write-Host 'Usage:  /bug-track "the login form crashes when email contains a +"'
