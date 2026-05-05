#!/usr/bin/env bash
# shellcheck shell=bash
# Installs Node.js (current LTS via Homebrew) + updates npm.

invoke_node() {
    log_step "4/8" "Node.js (LTS) + npm"

    # `brew install node` ships the latest stable. Most macOS users want this.
    brew_install formula 'node' 'Node.js'
    load_brew_env

    if ! have node; then
        log_err "node not available after install."
        return 1
    fi
    if ! have npm; then
        log_err "npm not available after install."
        return 1
    fi

    log_info "node $(node --version) / npm $(npm --version)"

    log_info "Updating npm to latest..."
    if npm install -g npm@latest >>"$DEV_ENV_LOG" 2>&1; then
        log_success "npm upgraded to $(npm --version)."
    else
        log_warn "Could not upgrade npm (continuing)."
    fi

    npm config set fund false
    npm config set audit-level moderate
    npm config set save-exact false
}
