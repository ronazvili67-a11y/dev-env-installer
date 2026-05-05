<#
.SYNOPSIS
    Shared helper functions used by all dev-env-installer modules.
#>

$Global:DevEnvLogFile = Join-Path $env:TEMP "dev-env-installer.log"

function Write-Step {
    param(
        [Parameter(Mandatory)] [string] $Number,
        [Parameter(Mandatory)] [string] $Title
    )
    $msg = "`n[$Number] $Title"
    Write-Host $msg -ForegroundColor Cyan
    Add-Content -Path $Global:DevEnvLogFile -Value "$(Get-Date -Format 'o') $msg"
}

function Write-Info {
    param([Parameter(Mandatory)] [string] $Message)
    Write-Host "      $Message" -ForegroundColor Gray
    Add-Content -Path $Global:DevEnvLogFile -Value "$(Get-Date -Format 'o')   $Message"
}

function Write-Success {
    param([Parameter(Mandatory)] [string] $Message)
    Write-Host "      [OK] $Message" -ForegroundColor Green
    Add-Content -Path $Global:DevEnvLogFile -Value "$(Get-Date -Format 'o')   OK $Message"
}

function Write-Warn {
    param([Parameter(Mandatory)] [string] $Message)
    Write-Host "      [!] $Message" -ForegroundColor Yellow
    Add-Content -Path $Global:DevEnvLogFile -Value "$(Get-Date -Format 'o')   WARN $Message"
}

function Write-Err {
    param([Parameter(Mandatory)] [string] $Message)
    Write-Host "      [X] $Message" -ForegroundColor Red
    Add-Content -Path $Global:DevEnvLogFile -Value "$(Get-Date -Format 'o')   ERR $Message"
}

function Test-Command {
    <#
    .SYNOPSIS
        Returns $true if a command (executable or alias) is available.
    #>
    param([Parameter(Mandatory)] [string] $Name)
    $null = Get-Command $Name -ErrorAction SilentlyContinue
    return $?
}

function Test-Admin {
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [System.Security.Principal.WindowsPrincipal]::new($id)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Update-EnvPath {
    <#
    .SYNOPSIS
        Refreshes $env:PATH from the registry without restarting the shell.
        Needed because winget installs put new exes on PATH only after a relaunch.
    #>
    $machine = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user    = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $env:PATH = ($machine, $user -join ';').Trim(';')
}

function Invoke-Winget {
    <#
    .SYNOPSIS
        Installs a package via winget if not already installed. Idempotent.
    .PARAMETER Id
        The winget package ID (e.g. Microsoft.VisualStudioCode).
    #>
    param(
        [Parameter(Mandatory)] [string] $Id,
        [string] $DisplayName = $Id
    )

    if (-not (Test-Command 'winget')) {
        throw "winget is not installed. Open Microsoft Store, install 'App Installer', then re-run."
    }

    Write-Info "Checking $DisplayName ..."
    $listed = winget list --id $Id --exact --accept-source-agreements 2>$null
    if ($LASTEXITCODE -eq 0 -and ($listed | Select-String -Pattern $Id -Quiet)) {
        Write-Success "$DisplayName already installed (skipped)."
        return
    }

    Write-Info "Installing $DisplayName via winget ..."
    $args = @(
        'install', '--id', $Id, '--exact',
        '--silent',
        '--accept-package-agreements',
        '--accept-source-agreements',
        '--disable-interactivity'
    )
    & winget @args | Tee-Object -FilePath $Global:DevEnvLogFile -Append | Out-Null

    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne -1978335189) {
        # -1978335189 = APPINSTALLER_CLI_ERROR_NO_APPLICABLE_UPGRADE (already up-to-date)
        throw "winget install failed for $Id (exit $LASTEXITCODE)."
    }
    Update-EnvPath
    Write-Success "$DisplayName installed."
}

function Get-RepoRoot {
    <#
    .SYNOPSIS
        Returns the absolute path to the repo root, regardless of where the
        script was launched from. Two parents up from this file = repo root.
    #>
    return (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
}
