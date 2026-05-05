#!/usr/bin/env bash
# shellcheck shell=bash
# Shared helpers used by all dev-env-installer modules.
# Sourced (`. 00-common.sh`) — never executed directly.

# Color helpers (only when stdout is a TTY)
if [ -t 1 ]; then
    C_RESET=$'\033[0m'
    C_CYAN=$'\033[36m'
    C_GREEN=$'\033[32m'
    C_YELLOW=$'\033[33m'
    C_RED=$'\033[31m'
    C_GRAY=$'\033[90m'
else
    C_RESET=''; C_CYAN=''; C_GREEN=''; C_YELLOW=''; C_RED=''; C_GRAY=''
fi
# Exported so install.sh and modules sourced from it can use them.
export C_RESET C_CYAN C_GREEN C_YELLOW C_RED C_GRAY

DEV_ENV_LOG="${TMPDIR:-/tmp}/dev-env-installer.log"
export DEV_ENV_LOG

log_step() {
    # log_step "1/8" "Prerequisites"
    local n="$1"; local msg="$2"
    printf '\n%s[%s] %s%s\n' "$C_CYAN" "$n" "$msg" "$C_RESET"
    printf '%s [%s] %s\n' "$(date -Iseconds 2>/dev/null || date)" "$n" "$msg" >> "$DEV_ENV_LOG"
}

log_info()    { printf '      %s\n' "$1"; printf '%s   %s\n' "$(date -Iseconds 2>/dev/null || date)" "$1" >> "$DEV_ENV_LOG"; }
log_success() { printf '      %s[OK] %s%s\n' "$C_GREEN" "$1" "$C_RESET"; printf '%s   OK %s\n' "$(date -Iseconds 2>/dev/null || date)" "$1" >> "$DEV_ENV_LOG"; }
log_warn()    { printf '      %s[!] %s%s\n' "$C_YELLOW" "$1" "$C_RESET"; printf '%s   WARN %s\n' "$(date -Iseconds 2>/dev/null || date)" "$1" >> "$DEV_ENV_LOG"; }
log_err()     { printf '      %s[X] %s%s\n' "$C_RED" "$1" "$C_RESET"; printf '%s   ERR %s\n' "$(date -Iseconds 2>/dev/null || date)" "$1" >> "$DEV_ENV_LOG"; }

# Returns 0 if a command is available on PATH.
have() { command -v "$1" >/dev/null 2>&1; }

# Detect architecture and Homebrew prefix.
detect_brew_prefix() {
    if [ "$(uname -m)" = "arm64" ]; then
        echo "/opt/homebrew"
    else
        echo "/usr/local"
    fi
}

# Make brew available in the current shell after install.
load_brew_env() {
    local prefix
    prefix="$(detect_brew_prefix)"
    if [ -x "$prefix/bin/brew" ]; then
        eval "$("$prefix/bin/brew" shellenv)"
    fi
}

# Install a Homebrew formula or cask if it isn't already installed.
brew_install() {
    # brew_install <type> <name> [display]
    # type: formula | cask
    local type="$1"; local name="$2"; local display="${3:-$name}"

    if ! have brew; then
        log_err "brew not available — prereqs failed."
        return 1
    fi

    local rc=0
    case "$type" in
        formula)
            if brew list --formula --versions "$name" >/dev/null 2>&1; then
                log_success "$display already installed (skipped)."
                return 0
            fi
            log_info "Installing $display (formula)..."
            brew install "$name" >>"$DEV_ENV_LOG" 2>&1
            rc=$?
            ;;
        cask)
            if brew list --cask --versions "$name" >/dev/null 2>&1; then
                log_success "$display already installed (skipped)."
                return 0
            fi
            log_info "Installing $display (cask)..."
            brew install --cask "$name" >>"$DEV_ENV_LOG" 2>&1
            rc=$?
            ;;
        *)
            log_err "Unknown brew type '$type'"
            return 1
            ;;
    esac

    if [ "$rc" -eq 0 ]; then
        log_success "$display installed."
    else
        log_err "Failed to install $display. See $DEV_ENV_LOG"
        return 1
    fi
}

# Append a block to a file iff a marker isn't already present.
ensure_block_in_file() {
    # ensure_block_in_file <file> <marker> <block-content>
    local file="$1"; local marker="$2"; local block="$3"
    [ -f "$file" ] || touch "$file"
    if ! grep -Fq "$marker" "$file"; then
        printf '\n%s\n' "$block" >> "$file"
        log_info "Patched $file"
    else
        log_info "Already patched: $file"
    fi
}

# Path to the repo root (two levels up from this 