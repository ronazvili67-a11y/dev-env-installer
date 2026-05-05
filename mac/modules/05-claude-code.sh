#!/usr/bin/env bash
# shellcheck shell=bash
# Installs Claude Code via the official native installer with npm fallback.

invoke_claude_code() {
    log_step "5/8" "Claude Code"

    if have claude; then
        log_success "Claude Code already installed: $(claude --version 2>/dev/null || echo unknown)"
        log_info "Skipping (re-run with --force later to upgrade)."
        return 0
    fi

    log_info "Installing Claude Code via the official native installer..."
    if curl -fsSL https://claude.ai/install.sh | bash >>"$DEV_ENV_LOG" 2>&1; then
        # The installer drops the binary into ~/.local/bin or /usr/local/bin —
        # make sure both are on PATH for the rest of this run.
        export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
        if have claude; then
            log_success "Claude Code installed: $(claude --version 2>/dev/null || echo unknown)"
            return 0
        fi
    fi

    log_warn "Native installer failed or did not put 'claude' on PATH."
    log_info "Falling back to npm install..."
    if ! have npm; then
        log_err "npm not available — cannot fall back. See $DEV_ENV_LOG"
        return 1
    fi
    if npm install -g '@anthropic-ai/claude-code' >>"$DEV_ENV_LOG" 2>&1; then
        if have claude; then
            log_success "Claude Code installed via npm: $(claude --version 2>/dev/null || echo unknown)"
            return 0
        fi
    fi
    log_err "Claude Code install failed via both methods. See $DEV_ENV_LOG"
    return 1
}
