<#
.SYNOPSIS
    Installs Windows Terminal + Oh My Posh + PSReadLine + theme.
    Updates the user's PowerShell profile so the prompt activates automatically.
#>

function Invoke-Terminal {
    Write-Step '6/8' 'Windows Terminal + Oh My Posh'

    Invoke-Winget -Id 'Microsoft.WindowsTerminal'        -DisplayName 'Windows Terminal'
    Invoke-Winget -Id 'JanDeDobbeleer.OhMyPosh'          -DisplayName 'Oh My Posh'

    # PSReadLine is built-in but the latest from the gallery is much better.
    Write-Info "Updating PSReadLine module..."
    try {
        Install-Module -Name PSReadLine -AllowPrerelease -Force -SkipPublisherCheck -Scope CurrentUser -ErrorAction Stop
        Write-Success "PSReadLine updated."
    } catch {
        Write-Warn "Could not update PSReadLine: $_"
    }

    # Copy the theme file to user's local app data.
    $repoRoot   = Get-RepoRoot
    $themeSrc   = Join-Path $repoRoot 'shared\oh-my-posh-theme.omp.json'
    $themeDir   = Join-Path $env:LOCALAPPDATA 'Programs\oh-my-posh\themes'
    if (-not (Test-Path $themeDir)) {
        $themeDir = Join-Path $env:USERPROFILE '.poshthemes'
        New-Item -ItemType Directory -Path $themeDir -Force | Out-Null
    }
    $themeDest = Join-Path $themeDir 'dev-env.omp.json'
    Copy-Item -Path $themeSrc -Destination $themeDest -Force
    Write-Success "Oh My Posh theme installed at $themeDest"

    # Patch PowerShell profiles (5.1 + 7) so the prompt activates on login.
    $profiles = @(
        $PROFILE.CurrentUserAllHosts,                                              # 5.1 + 7 shared
        (Join-Path (Split-Path $PROFILE.CurrentUserCurrentHost -Parent) 'Microsoft.PowerShell_profile.ps1') # current
    ) | Select-Object -Unique

    $marker = '# >>> dev-env-installer (oh-my-posh) >>>'
    $endMarker = '# <<< dev-env-installer (oh-my-posh) <<<'
    $block = @"
$marker
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config '$themeDest' | Invoke-Expression
}
Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView -EditMode Windows
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
$endMarker
"@

    foreach ($profilePath in $profiles) {
        $dir = Split-Path $profilePath -Parent
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $content = if (Test-Path $profilePath) { Get-Content $profilePath -Raw } else { '' }
        if ($content -notmatch [regex]::Escape($marker)) {
            Add-Content -Path $profilePath -Value "`n$block`n"
            Write-Info "Patched profile: $profilePath"
        } else {
            Write-Info "Profile already patched: $profilePath"
        }
    }

    Write-Success "Terminal experience configured. Open a new shell to see the new prompt."
}
