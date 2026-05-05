<#
.SYNOPSIS
    Installs Claude Code via the official native installer
    (https://claude.ai/install.ps1). Falls back to npm if the native installer
    is unreachable.
#>

function Invoke-ClaudeCode {
    Write-Step '5/8' 'Claude Code'

    if (Test-Command 'claude') {
        $existing = & claude --version 2>$null
        Write-Success "Claude Code already installed: $existing"
        Write-Info "Skipping (re-run with -Force to upgrade)."
        return
    }

    Write-Info "Installing Claude Code via the official native installer..."
    try {
        # Anthropic's bootstrap returns a self-contained installer script.
        $installerUrl = 'https://claude.ai/install.ps1'
        $script = Invoke-RestMethod -Uri $installerUrl -UseBasicParsing
        $tmp = Join-Path $env:TEMP 'claude-install.ps1'
        Set-Content -Path $tmp -Value $script -Encoding UTF8
        & powershell -NoProfile -ExecutionPolicy Bypass -File $tmp
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue

        Update-EnvPath
        if (Test-Command 'claude') {
            Write-Success "Claude Code installed: $(& claude --version)"
            return
        }
        throw "claude command still not found after native install."
    } catch {
        Write-Warn "Native installer failed ($_). Falling back to npm..."
        if (-not (Test-Command 'npm')) {
            Write-Err "npm is not available. Cannot fall back."
            return
        }
        & npm install -g '@anthropic-ai/claude-code'
        Update-EnvPath
        if (Test-Command 'claude') {
            Write-Success "Claude Code installed via npm: $(& claude --version)"
        } else {
            Write-Err "Claude Code install failed via both methods. See log: $Global:DevEnvLogFile"
        }
    }
}
