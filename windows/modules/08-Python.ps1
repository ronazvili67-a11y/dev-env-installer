<#
.SYNOPSIS
    Installs Python 3.12 and uv (modern Python package manager from Astral).
#>

function Invoke-Python {
    Write-Step '8/8' 'Python + uv'

    Invoke-Winget -Id 'Python.Python.3.12' -DisplayName 'Python 3.12'
    Invoke-Winget -Id 'astral-sh.uv'        -DisplayName 'uv (Python package manager)'
    Update-EnvPath

    if (Test-Command 'python') {
        Write-Success "python: $(& python --version)"
    } else {
        Write-Warn "python not on PATH yet -- open a fresh terminal."
    }

    if (Test-Command 'uv') {
        Write-Success "uv: $(& uv --version)"
    } else {
        Write-Warn "uv not on PATH yet -- open a fresh terminal."
    }
}
