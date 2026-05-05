#!/usr/bin/env bash
# shellcheck shell=bash
# Installs Oh My Posh and wires it into the user's zsh profile.

invoke_terminal() {
    log_step "6/8" "Terminal experience (Oh My Posh)"

    brew_install formula 'oh-my-posh' 'Oh My Posh'
    load_brew_env

    if ! have oh-my-posh; then
        log_warn "oh-my-posh not on PATH after install — skipping config."
        return 0
    fi

    local repo; repo="$(repo_root)"
    local theme_src="$repo/shared/oh-my-posh-theme.omp.json"
    local theme_dir="$HOME/.poshthemes"
    local theme_dest="$theme_dir/dev-env.omp.json"
    mkdir -p "$theme_dir"
    cp "$theme_src" "$theme_dest"
    log_success "Theme installed at $theme_dest"

    # Patch ~/.zshrc once.
    local marker="# >>> dev-env-installer (oh-my-posh) >>>"
    local end_marker="# <<< dev-env-installer (oh-my-posh) <<<"
    local block
    block="$(cat <<EOF
$marker
if command -v oh-my-posh >/dev/null 2>&1; then
    eval "\$(oh-my-posh init zsh --config '$theme_dest')"
fi
# Useful aliases
alias gs='git status -sb'
alias gp='git pull --rebase'
alias gst='git stash'
alias ll='ls -lah'
$end_marker
EOF
    )"

    ensure_block_in_file "$HOME/.zshrc" "$marker" "$block"

    log_success "Terminal configured. Open a new shell to see the new prompt."
}
