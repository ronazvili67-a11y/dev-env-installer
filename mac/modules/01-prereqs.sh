#!/usr/bin/env bash
# shellcheck shell=bash
# Prereqs: macOS check, Xcode CLT, Homebrew.

invoke_prereqs() {
    log_step "1/8" "Prerequisites"

    # 1. macOS check
    if [ "$(uname -s)" != "Darwin" ]; then
        log_err "This script is for macOS only. Use the Windows installer or run on macOS."
        return 1
    fi
    local macver; macver="$(sw_vers -productVersion 2>/dev/null || echo 'unknown')"
    log_info "macOS $macver / $(uname -m)"

    # 2. Xcode Command Line Tools
    if ! xcode-select -p >/dev/null 2>&1; then
        log_info "Installing Xcode Command Line Tools (this may pop a GUI prompt)..."
        # Trigger a non-interactive install — works on most macOS releases.
        local placeholder=/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
        touch "$placeholder"
        local label
        label="$(softwareupdate -l 2>/dev/null \
                  | grep -E 'Command Line Tools' \
                  | grep -E "$(sw_vers -productVersion | cut -d. -f1-2 || true)" \
                  | head -n1 \
                  | sed -E 's/^[* ] +Label: //; s/[[:space:]]*$//' || true)"
        if [ -n "$label" ]; then
            # `sudo` doesn't carry the redirect to the parent shell's file, so
            # we pipe the output through `tee -a` (which runs as the user).
            sudo softwareupdate -i "$label" --verbose 2>&1 \
                | tee -a "$DEV_ENV_LOG" >/dev/null || true
        fi
        rm -f "$placeholder"

        if ! xcode-select -p >/dev/null 2>&1; then
            log_warn "Falling back to interactive Xcode CLT install. A dialog should appear."
            xcode-select --install || true
            log_warn "Re-run this script after the Xcode CLT install finishes."
            return 1
        fi
    fi
    log_success "Xcode CLT: $(xcode-select -p)"

    # 3. Homebrew
    if ! have brew; then
        log_info "Installing Homebrew (you may be prompted for your password)..."
        NONINTERACTIVE=1 /bin/bash -c \
            "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
            >>"$DEV_ENV_LOG" 2>&1
    fi
    load_brew_env
    if ! have brew; then
        log_err "Homebrew install failed. See $DEV_ENV_LOG"
        return 1
    fi
    log_success "Homebrew: $(brew --version | head -n1)"

    # Ensure brew shellenv lines are persisted in the user's profile so future
    # shells find brew automatically.
    local prefix; prefix="$(detect_brew_prefix)"
    local brew_block; brew_block="eval \"\$($prefix/bin/brew shellenv)\""
    local marker="# >>> dev-env-installer (homebrew) >>>"
    local block; block="$(printf '%s\n%s\n%s' "$marker" "$brew_block" "# <<< dev-env-installer (homebrew) <<<")"

    for profile in "$HOME/.zprofile" "$HOME/.bash_profile"; do
        ensure_block_in_file "$profile" "$marker" "$block"
    done

    # Update brew metadata so subsequent installs use fresh formulae.
    log_info "Updating Homebrew metadata..."
    brew update >>"$DEV_ENV_LOG" 2>&1 || log_warn "brew update returned non-zero (continuing)."
    log_success "Prereqs ready."
}
