#!/usr/bin/env bash
# shellcheck shell=bash
# Installs Git via Homebrew (newer than macOS bundled) and applies global config.

invoke_git() {
    log_step "3/8" "Git"

    brew_install formula 'git' 'Git'
    load_brew_env

    if ! have git; then
        log_err "git not available after install."
        return 1
    fi

    log_info "Configuring global git defaults (only missing keys)..."

    # Helper that sets a key only if it isn't already set.
    set_if_missing() {
        local key="$1"; local value="$2"
        local current; current="$(git config --global --get "$key" 2>/dev/null || true)"
        if [ -z "$current" ]; then
            git config --global "$key" "$value"
            log_info "Set $key = $value"
        else
            log_info "Kept existing $key = $current"
        fi
    }

    set_if_missing init.defaultBranch    main
    set_if_missing pull.rebase           true
    set_if_missing pull.ff               only
    set_if_missing push.autoSetupRemote  true
    set_if_missing push.default          simple
    set_if_missing push.followTags       true
    set_if_missing fetch.prune           true
    set_if_missing fetch.pruneTags       true
    set_if_missing rebase.autoStash      true
    set_if_missing rebase.autoSquash     true
    set_if_missing merge.conflictStyle   zdiff3
    set_if_missing diff.algorithm        histogram
    set_if_missing diff.colorMoved       default
    set_if_missing rerere.enabled        true
    set_if_missing core.autocrlf         input        # macOS convention
    set_if_missing core.editor           "code --wait"
    set_if_missing commit.verbose        true
    set_if_missing help.autocorrect      prompt

    # Aliases
    git config --global alias.s     "status -sb"
    git config --global alias.co    "checkout"
    git config --global alias.br    "branch"
    git config --global alias.lg    "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
    git config --global alias.amend "commit --amend --no-edit"
    git config --global alias.undo  "reset --soft HEAD~1"
    git config --global alias.sync  '!git pull --rebase && git push'
    git config --global alias.pushf "push --force-with-lease"

    # Global gitignore
    local repo; repo="$(repo_root)"
    local src="$repo/shared/gitignore_global"
    local dest="$HOME/.gitignore_global"
    if [ -f "$src" ]; then
        cp "$src" "$dest"
        git config --global core.excludesfile "$dest"
        log_success "Global .gitignore_global installed at $dest"
    fi

    # Identity prompt — only warn if missing.
    local user_name; user_name="$(git config --global --get user.name 2>/dev/null || true)"
    local user_email; user_email="$(git config --global --get user.email 2>/dev/null || true)"
    if [ -z "$user_name" ] || [ -z "$user_email" ]; then
        log_warn "git user.name/user.email not set. Run these later:"
        log_warn '  git config --global user.name  "Your Name"'
        log_warn '  git config --global user.email "you@example.com"'
    fi

    log_success "Git configured."
}
