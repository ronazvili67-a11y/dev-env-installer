<#
.SYNOPSIS
    Installs GitHub CLI (gh).
#>

function Invoke-GitHubCli {
    Write-Step '7/8' 'GitHub CLI'

    Invoke-Winget -Id 'GitHub.cli' -DisplayName 'GitHub CLI'
    Update-EnvPath

    if (Test-Command 'gh') {
        Write-Success "gh installed: $(& gh --version | Select-Object -First 1)"
        Write-Info "To authenticate later run:  gh auth login"
    } else {
        Write-Warn "gh not on PATH yet — open a fresh terminal."
    }
}
