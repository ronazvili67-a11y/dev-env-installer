<#
.SYNOPSIS
    Installs Node.js LTS and updates npm to latest.
#>

function Invoke-Node {
    Write-Step '4/8' 'Node.js (LTS) + npm'

    Invoke-Winget -Id 'OpenJS.NodeJS.LTS' -DisplayName 'Node.js LTS'
    Update-EnvPath

    if (-not (Test-Command 'node')) {
        Write-Err "node not on PATH. Reboot terminal and re-run."
        return
    }
    if (-not (Test-Command 'npm')) {
        Write-Err "npm not on PATH."
        return
    }

    $nodeVer = & node --version
    $npmVer  = & npm  --version
    Write-Info "node $nodeVer / npm $npmVer"

    # Update npm to latest
    Write-Info "Updating npm to latest..."
    try {
        & npm install -g npm@latest 2>&1 | Out-Null
        Write-Success "npm upgraded to $((& npm --version))."
    } catch {
        Write-Warn "Could not upgrade npm: $_"
    }

    # Set sensible npm defaults
    & npm config set fund false
    & npm config set audit-level moderate
    & npm config set save-exact false
}
