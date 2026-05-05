<#
.SYNOPSIS
    Verifies prerequisites: TLS 1.2+, winget, ExecutionPolicy.
#>

function Invoke-Prereqs {
    Write-Step '1/8' 'Prerequisites'

    # 1. Force TLS 1.2+ for any web request done by this session.
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
    Write-Info "TLS 1.2/1.3 enforced for this session."

    # 2. Verify Windows 10 / 11.
    $os = (Get-CimInstance Win32_OperatingSystem).Caption
    if ($os -notmatch 'Windows 1[01]') {
        Write-Warn "Detected '$os'. Officially tested on Windows 10/11 only."
    } else {
        Write-Success "Detected $os."
    }

    # 3. winget. On Windows 11 it is preinstalled. On older Win10 it lives in
    # the App Installer (Microsoft Store).
    if (-not (Test-Command 'winget')) {
        Write-Warn "winget not found. Attempting to install App Installer from Microsoft Store..."
        try {
            $url = 'https://aka.ms/getwinget'
            $tmp = Join-Path $env:TEMP 'AppInstaller.msixbundle'
            Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing
            Add-AppxPackage -Path $tmp
            Remove-Item $tmp -Force -ErrorAction SilentlyContinue
            Update-EnvPath
            if (-not (Test-Command 'winget')) {
                throw "winget still not available after install."
            }
            Write-Success "winget installed."
        } catch {
            throw "Could not install winget automatically. Open Microsoft Store, search 'App Installer', install it, then re-run this script. Error: $_"
        }
    } else {
        Write-Success "winget detected: $(winget --version)"
    }

    # 4. PowerShell version notice (5.1 ok, 7+ better).
    Write-Info "PowerShell $($PSVersionTable.PSVersion)"
}
