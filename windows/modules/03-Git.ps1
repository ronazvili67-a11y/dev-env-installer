<#
.SYNOPSIS
    Installs Git for Windows and applies sensible global config defaults.
#>

function Invoke-Git {
    Write-Step '3/8' 'Git'

    Invoke-Winget -Id 'Git.Git' -DisplayName 'Git for Windows'
    Update-EnvPath

    if (-not (Test-Command 'git')) {
        Write-Err "git not on PATH. Reboot terminal and re-run."
        return
    }

    Write-Info "Configuring global git defaults (only missing keys)..."

    # Apply each setting only if not already set, so we never overwrite the
    # user's existing identity or preferences.
    $settings = @{
        'init.defaultBranch'    = 'main'
        'pull.rebase'           = 'true'
        'pull.ff'               = 'only'
        'push.autoSetupRemote'  = 'true'
        'push.default'          = 'simple'
        'push.followTags'       = 'true'
        'fetch.prune'           = 'true'
        'fetch.pruneTags'       = 'true'
        'rebase.autoStash'      = 'true'
        'rebase.autoSquash'     = 'true'
        'merge.conflictStyle'   = 'zdiff3'
        'diff.algorithm'        = 'histogram'
        'diff.colorMoved'       = 'default'
        'rerere.enabled'        = 'true'
        'core.autocrlf'         = 'true'           # Windows convention
        'core.editor'           = 'code --wait'
        'commit.verbose'        = 'true'
        'help.autocorrect'      = 'prompt'
    }

    foreach ($key in $settings.Keys) {
        $current = & git config --global --get $key 2>$null
        if ([string]::IsNullOrWhiteSpace($current)) {
            & git config --global $key $settings[$key]
            Write-Info "Set $key = $($settings[$key])"
        } else {
            Write-Info "Kept existing $key = $current"
        }
    }

    # Aliases
    $aliases = @{
        's'       = 'status -sb'
        'co'      = 'checkout'
        'br'      = 'branch'
        'lg'      = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
        'amend'   = 'commit --amend --no-edit'
        'undo'    = 'reset --soft HEAD~1'
        'sync'    = '!git pull --rebase && git push'
        'pushf'   = 'push --force-with-lease'
    }
    foreach ($alias in $aliases.Keys) {
        $current = & git config --global --get "alias.$alias" 2>$null
        if ([string]::IsNullOrWhiteSpace($current)) {
            & git config --global "alias.$alias" $aliases[$alias]
        }
    }

    # Global gitignore
    $repoRoot = Get-RepoRoot
    $gitignoreSrc = Join-Path $repoRoot 'shared\gitignore_global'
    $gitignoreDest = Join-Path $env:USERPROFILE '.gitignore_global'
    if (Test-Path $gitignoreSrc) {
        Copy-Item -Path $gitignoreSrc -Destination $gitignoreDest -Force
        & git config --global core.excludesfile $gitignoreDest
        Write-Success "Global .gitignore_global installed at $gitignoreDest"
    }

    # Identity prompt -- non-blocking, only if missing.
    $userName  = & git config --global --get user.name  2>$null
    $userEmail = & git config --global --get user.email 2>$null
    if ([string]::IsNullOrWhiteSpace($userName) -or [string]::IsNullOrWhiteSpace($userEmail)) {
        Write-Warn "git user.name/user.email not set. Run these later:"
        Write-Warn '  git config --global user.name  "Your Name"'
        Write-Warn '  git config --global user.email "you@example.com"'
    }

    Write-Success "Git configured."
}
