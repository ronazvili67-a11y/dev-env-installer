<#
.SYNOPSIS
    One-click installer for the modern dev environment on Windows.

.DESCRIPTION
    Installs and configures:
      - VS Code (latest) + the official Claude Code extension + opinionated settings
      - Git (latest) + sensible global config + global .gitignore
      - Node.js LTS + latest npm
      - Claude Code (native installer with npm fallback)
      - Windows Terminal + Oh My Posh + PSReadLine
      - GitHub CLI
      - Python 3.12 + uv

    Idempotent: re-running skips anything already up-to-date.

.PARAMETER SkipModules
    Optional: comma-separated list of module names to skip (e.g. "Python,Terminal").

.PARAMETER NoElevate
    Don't auto-relaunch as Administrator. Some installs may fail without it.

.EXAMPLE
    PS> .\install.ps1
    Run all modules with self-elevation if needed.

.EXAMPLE
    PS> .\install.ps1 -SkipModules "Python,Terminal"
    Run all modules except Python and Terminal.
#>
[CmdletBinding()]
param(
    [string[]] $SkipModules = @(),
    [switch]   $NoElevate
)

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'   # silence Invoke-WebRequest progress bar

# ---- Self-elevate to Administrator if needed ----------------------------------
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $here 'modules\00-Common.ps1')

if (-not (Test-Admin) -and -not $NoElevate) {
    Write-Host "[!] This script needs Administrator privileges for some installs." -ForegroundColor Yellow
    Write-Host "    Re-launching elevated..." -ForegroundColor Yellow
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$($MyInvocation.MyCommand.Path)`"")
    if ($SkipModules) { $argList += '-SkipModules'; $argList += ($SkipModules -join ',') }
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $argList -Wait
    exit
}

# ---- Banner -------------------------------------------------------------------
"" | Out-Host
@"
=================================================================
  Dev Environment Installer for Windows
  - VS Code, Git, Node.js, Claude Code, Terminal, gh, Python+uv -
=================================================================
"@ | Write-Host -ForegroundColor Cyan

# Initialize log file
"=== Run started: $(Get-Date -Format 'o') ===" | Set-Content -Path $Global:DevEnvLogFile
Write-Host "Logging to: $Global:DevEnvLogFile`n" -ForegroundColor DarkGray

# ---- Load modules -------------------------------------------------------------
$modulesDir = Join-Path $here 'modules'
$moduleMap = [ordered]@{
    'Prereqs'    = '01-Prereqs.ps1'
    'VSCode'     = '02-VSCode.ps1'
    'Git'        = '03-Git.ps1'
    'Node'       = '04-Node.ps1'
    'ClaudeCode' = '05-ClaudeCode.ps1'
    'Terminal'   = '06-Terminal.ps1'
    'GitHubCli'  = '07-GitHubCli.ps1'
    'Python'     = '08-Python.ps1'
}

foreach ($file in $moduleMap.Values) {
    . (Join-Path $modulesDir $file)
}

$results = [System.Collections.Generic.List[object]]::new()
$started = Get-Date

foreach ($name in $moduleMap.Keys) {
    if ($SkipModules -contains $name) {
        Write-Host "`n[skip] $name (requested via -SkipModules)" -ForegroundColor DarkYellow
        $results.Add([pscustomobject]@{ Module = $name; Status = 'Skipped' })
        continue
    }
    try {
        & "Invoke-$name"
        $results.Add([pscustomobject]@{ Module = $name; Status = 'OK' })
    } catch {
        Write-Err $_.Exception.Message
        $results.Add([pscustomobject]@{ Module = $name; Status = 'FAIL'; Error = $_.Exception.Message })
        # Prereqs failure is fatal; everything else continues.
        if ($name -eq 'Prereqs') {
            Write-Host "`nPrereqs failed -- aborting. See log: $Global:DevEnvLogFile" -ForegroundColor Red
            exit 1
        }
    }
}

# ---- Summary ------------------------------------------------------------------
$elapsed = (Get-Date) - $started
"" | Out-Host
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "  Installation complete in $('{0:mm\:ss}' -f $elapsed)" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
$results | Format-Table -AutoSize

Write-Host "`nVersions:" -ForegroundColor Cyan
foreach ($cmd in 'code', 'git', 'node', 'npm', 'claude', 'gh', 'python', 'uv', 'oh-my-posh') {
    if (Test-Command $cmd) {
        try {
            $v = (& $cmd --version 2>$null | Select-Object -First 1)
            Write-Host ("  {0,-12}{1}" -f $cmd, $v)
        } catch { }
    } else {
        Write-Host ("  {0,-12}[not on PATH]" -f $cmd) -ForegroundColor DarkYellow
    }
}

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "  1. Open a NEW terminal window (so PATH changes take effect)."
Write-Host "  2. Run:  git config --global user.name  ""Your Name"""
Write-Host "          git config --global user.email ""you@example.com"""
Write-Host "  3. Run:  gh auth login    (one-time GitHub authentication)"
Write-Host "  4. Run:  claude           (start Claude Code in your project)"
Write-Host "`nFull log: $Global:DevEnvLogFile" -ForegroundColor DarkGray

if ($results | Where-Object Status -EQ 'FAIL') {
    exit 1
}
exit 0
