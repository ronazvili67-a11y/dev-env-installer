<#
.SYNOPSIS
    Installs VS Code, applies user settings, and installs recommended extensions
    (including the official Claude Code extension).
#>

function Invoke-VSCode {
    Write-Step '2/8' 'VS Code + Claude Code extension'

    Invoke-Winget -Id 'Microsoft.VisualStudioCode' -DisplayName 'Visual Studio Code'

    # winget puts code on PATH, but the current process needs a refresh.
    Update-EnvPath
    if (-not (Test-Command 'code')) {
        Write-Warn "'code' not on PATH yet. Trying default install location..."
        $candidate = Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\bin\code.cmd'
        if (Test-Path $candidate) {
            $env:PATH = "$($env:PATH);$(Split-Path $candidate -Parent)"
        }
    }

    if (-not (Test-Command 'code')) {
        Write-Err "VS Code 'code' command still not available. Open VS Code once manually, then re-run this script."
        return
    }

    # Apply user settings
    $repoRoot   = Get-RepoRoot
    $sharedDir  = Join-Path $repoRoot 'shared'
    $settingsSrc = Join-Path $sharedDir 'vscode-settings.json'
    $extensionsSrc = Join-Path $sharedDir 'vscode-extensions.json'

    $settingsDir  = Join-Path $env:APPDATA 'Code\User'
    $settingsDest = Join-Path $settingsDir 'settings.json'
    if (-not (Test-Path $settingsDir)) {
        New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
    }

    if (Test-Path $settingsDest) {
        $backup = "$settingsDest.bak.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item -Path $settingsDest -Destination $backup -Force
        Write-Info "Existing settings.json backed up to $backup"
    }
    Copy-Item -Path $settingsSrc -Destination $settingsDest -Force
    Write-Success "VS Code settings.json applied."

    # Install extensions
    if (-not (Test-Path $extensionsSrc)) {
        Write-Warn "vscode-extensions.json not found, skipping extensions."
        return
    }
    $extConfig = Get-Content $extensionsSrc -Raw | ConvertFrom-Json
    $installed = & code --list-extensions 2>$null
    foreach ($ext in $extConfig.extensions) {
        if ($installed -contains $ext) {
            Write-Info "Extension already installed: $ext"
            continue
        }
        Write-Info "Installing extension: $ext"
        & code --install-extension $ext --force 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Installed $ext"
        } else {
            Write-Warn "Could not install $ext (continuing)."
        }
    }
}
