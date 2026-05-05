<#
.SYNOPSIS
    One-liner bootstrap. Downloads the repo, then runs windows/install.ps1.

.DESCRIPTION
    This is the file that the user pipes into iex:

        irm https://raw.githubusercontent.com/<USER>/<REPO>/main/windows/bootstrap.ps1 | iex

    It downloads the repo as a zip into %TEMP%, extracts it, and invokes
    install.ps1 from the extracted folder so all module/config files are
    available locally.
#>

[CmdletBinding()]
param(
    [string] $Repo   = 'ronazvili67-a11y/dev-env-installer',  # set by maintainer
    [string] $Branch = 'main',
    [string[]] $SkipModules = @()
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

$tmpRoot = Join-Path $env:TEMP "dev-env-installer-$(Get-Date -Format 'yyyyMMddHHmmss')"
New-Item -ItemType Directory -Path $tmpRoot -Force | Out-Null

$zipUrl  = "https://github.com/$Repo/archive/refs/heads/$Branch.zip"
$zipFile = Join-Path $tmpRoot 'repo.zip'

Write-Host "Downloading $zipUrl ..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $zipUrl -OutFile $zipFile -UseBasicParsing

Write-Host "Extracting ..." -ForegroundColor Cyan
Expand-Archive -Path $zipFile -DestinationPath $tmpRoot -Force

# Find the extracted folder (named "<repo>-<branch>")
$extracted = Get-ChildItem -Path $tmpRoot -Directory | Select-Object -First 1
if (-not $extracted) {
    throw "Could not find extracted repo in $tmpRoot"
}

$installer = Join-Path $extracted.FullName 'windows\install.ps1'
if (-not (Test-Path $installer)) {
    throw "install.ps1 not found at $installer"
}

Write-Host "Running installer at $installer ..." -ForegroundColor Cyan
$argList = @{ }
if ($SkipModules) { $argList['SkipModules'] = $SkipModules }
& $installer @argList

# Cleanup is intentionally skipped so the user can inspect the log.
Write-Host "`nTemp folder kept for inspection: $tmpRoot" -ForegroundColor DarkGray
