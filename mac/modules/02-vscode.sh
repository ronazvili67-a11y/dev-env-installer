#!/usr/bin/env bash
# shellcheck shell=bash
# Installs VS Code, applies user settings, installs the Claude Code extension and friends.

invoke_vscode() {
    log_step "2/8" "VS Code + Claude Code extension"

    brew_install cask 'visual-studio-code' 'Visual Studio Code'

    if ! have code; then
        # First-time installs sometimes don't put `code` on PATH until the app
        # is launched once. Try the standard cask path.
        local cli="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
        local cli_dir
        cli_dir="$(dirname "$cli")"
        if [ -x "$cli" ]; then
            PATH="${cli_dir}:${PATH}"
            export PATH
        fi
    fi
    if ! have code; then
        log_warn "'code' command not on PATH yet. Open VS Code once and run:"
        log_warn '  Cmd+Shift+P > "Shell Command: Install code command in PATH"'
        return 0
    fi

    # Apply user settings (with backup of any existing one)
    local repo
    repo="$(repo_root)"
    local settings_src="$repo/shared/vscode-settings.json"
    local extensions_src="$repo/shared/vscode-extensions.json"
    local settings_dir="$HOME/Library/Application Support/Code/User"
    local settings_dest="$settings_dir/settings.json"

    mkdir -p "$settings_dir"
    if [ -f "$settings_dest" ]; then
        local backup
        backup="$settings_dest.bak.$(date +%Y%m%d-%H%M%S)"
        cp "$settings_dest" "$backup"
        log_info "Existing settings.json backed up to $backup"
    fi
    cp "$settings_src" "$settings_dest"
    log_success "VS Code settings.json applied."

    # Install extensions listed in shared/vscode-extensions.json
    if [ ! -f "$extensions_src" ]; then
        log_warn "vscode-extensions.json not found, skipping extensions."
        return 0
    fi
    # Pull the array out without requiring jq — fall back to grep if jq is absent.
    local extensions
    if have jq; then
        extensions="$(jq -r '.extensions[]' "$extensions_src")"
    else
        extensions="$(grep -oE '"[a-zA-Z0-9._-]+\.[a-zA-Z0-9._-]+"' "$extensions_src" \
                      | tr -d '"' \
                      | grep -v -E '^extensions$|^_comment$' || true)"
    fi

    local installed
    installed="$(code --list-extensions 2>/dev/null || true)"
    while IFS= read -r ext; do
        [ -z "$ext" ] && continue
        if printf '%s\n' "$installed" | grep -Fxq "$ext"; then
            log_info "Extension already installed: $ext"
            continue
        fi
        log_info "Installing extension: $ext"
        if code --install-extension "$ext" --force >>"$DEV_ENV_LOG" 2>&1; then
            log_success "Installed $ext"
        else
            log_warn "Could not install $ext (continuing)."
        fi
    done <<< "$extensions"
}
