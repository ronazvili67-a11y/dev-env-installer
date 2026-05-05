# Contributing

Thanks for taking the time to improve this installer. This project's promise is *one click, zero hand-holding*, so PRs that move it closer to that bar are very welcome.

## Local development

```bash
git clone https://github.com/<USER>/dev-env-installer.git
cd dev-env-installer
```

### Folder layout
- `windows/` — PowerShell modules. Entry point: `windows/install.ps1`.
- `mac/` — Bash modules. Entry point: `mac/install.sh`.
- `shared/` — files shared between platforms (VS Code settings, gitconfig template, oh-my-posh theme).
- `.github/workflows/` — lint + smoke test.

## Linting

```bash
# Bash
brew install shellcheck
shellcheck mac/install.sh mac/bootstrap.sh mac/modules/*.sh

# PowerShell
pwsh -c "Install-Module PSScriptAnalyzer -Scope CurrentUser -Force"
pwsh -c "Invoke-ScriptAnalyzer -Path windows -Recurse -Severity Warning,Error"
```

## Adding a new module

Follow the existing convention — one module = one tool, files numbered.

### Windows
1. Create `windows/modules/0X-<Name>.ps1` defining a single `Invoke-<Name>` function.
2. Use `Write-Step "X/Y" "Title"`, `Write-Info`, `Write-Success`, `Write-Warn` from `00-Common.ps1`.
3. Use `Invoke-Winget -Id '<id>' -DisplayName '<name>'` so idempotency is guaranteed.
4. Register the module in the `$moduleMap` ordered hash inside `windows/install.ps1`.

### Mac
1. Create `mac/modules/0X-<name>.sh` defining a single `invoke_<name>` function.
2. Use `log_step`, `log_info`, `log_success`, `log_warn`, `log_err` from `00-common.sh`.
3. Use `brew_install <type> <name> [display]` for installs (idempotent already).
4. Register the module in `mac/install.sh` next to the existing `run_module …` calls.

## Style

- **PowerShell**: PascalCase functions, no Aliases (`Get-ChildItem` not `gci`), `$ErrorActionPreference = 'Stop'` at the top of every module that doesn't already inherit it.
- **Bash**: snake_case functions, `set -euo pipefail` already enabled in the orchestrator, target `/bin/bash 3.2+` (default macOS bash).
- **Idempotency** is non-negotiable. Every install must be safe to re-run.
- **Error handling**: a non-critical module's failure must not abort the whole install. Only `prereqs` is allowed to be fatal.

## Submitting a PR

1. Branch off `main`.
2. Make your change.
3. Push and open a PR — CI runs automatically.
4. Smoke test (real runners) runs only on PRs and manual dispatch (it's slow).

PR descriptions ideally include before/after output of the relevant module.
