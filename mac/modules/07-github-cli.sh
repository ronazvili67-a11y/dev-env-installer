#!/usr/bin/env bash
# shellcheck shell=bash
# Installs GitHub CLI.

invoke_github_cli() {
    log_step "7/8" "GitHub CLI"

    brew_install formula 'gh' 'GitHub CLI'
    load_brew_env

    if have gh; then
        log_success "gh installed: $(gh --version | head -n1)"
        log_info "To authenticate later run:  gh auth login"
    else
        log_warn "gh not on PATH after install."
    fi
}
