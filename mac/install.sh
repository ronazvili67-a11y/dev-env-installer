#!/usr/bin/env bash
# =============================================================================
# Dev Environment One-Click Installer for macOS
#
#   - VS Code (latest) + official Claude Code extension + opinionated settings
#   - Git (latest) + sensible global config + global .gitignore
#   - Node.js LTS + latest npm
#   - Claude Code (native installer with npm fallback)
#   - Oh My Posh prompt
#   - GitHub CLI
#   - Python 3.12 + uv
#
# Usage:
#     ./install.sh                              # all modules
#     ./install.sh --skip terminal,python       # skip specific modules
#     ./install.sh --help
#
# Idempotent: re-running skips anything already up-to-date.
# =============================================================================

set -euo pipefail

# ----------------------------------------------------------------------------
# Paths and module loading
# ----------------------------------------------------------------------------
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEV_ENV_REPO_ROOT="$(cd "$HERE/.." && pwd)"
export DEV_ENV_REPO_ROOT

# shellcheck source=modules/00-common.sh
. "$HERE/modules/00-common.sh"
# shellcheck source=modules/01-prereqs.sh
. "$HERE/modules/01-prereqs.sh"
# shellcheck source=modules/02-vscode.sh
. "$HERE/modules/02-vscode.sh"
# shellcheck source=modules/03-git.sh
. "$HERE/modules/03-git.sh"
# shellcheck source=modules/04-node.sh
. "$HERE/modules/04-node.sh"
# shellcheck source=modules/05-claude-code.sh
. "$HERE/modules/05-claude-code.sh"
# shellcheck source=modules/06-terminal.sh
. "$HERE/modules/06-terminal.sh"
# shellcheck source=modules/07-github-cli.sh
. "$HERE/modules/07-github-cli.sh"
# shellcheck source=modules/08-python.sh
. "$HERE/modules/08-python.sh"

# ----------------------------------------------------------------------------
# CLI args
# ----------------------------------------------------------------------------
SKIP_LIST=""

show_help() {
    cat <<'EOF'
Usage: install.sh [options]

Options:
    --skip <list>    Comma-separated module names to skip
                     (prereqs, vscode, git, node, claude_code, terminal, github_cli, python)
    --help           Show this help

Examples:
    ./install.sh
    ./install.sh --skip python,terminal
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --skip)
            SKIP_LIST="$2"; shift 2
            ;;
        --help|-h)
            show_help; exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            show_help
            exit 2
            ;;
    esac
done

is_skipped() {
    case ",$SKIP_LIST," in
        *",$1,"*) return 0 ;;
        *)        return 1 ;;
    esac
}

# ----------------------------------------------------------------------------
# Banner + log header
# ----------------------------------------------------------------------------
: > "$DEV_ENV_LOG"
{
    printf '=================================================================\n'
    printf '  Dev Environment Installer for macOS\n'
    printf '  - VS Code, Git, Node.js, Claude Code, Terminal, gh, Python+uv -\n'
    printf '=================================================================\n'
} | tee -a "$DEV_ENV_LOG"
printf '%sLogging to: %s%s\n\n' "$C_GRAY" "$DEV_ENV_LOG" "$C_RESET"

START_TS=$(date +%s)

# ----------------------------------------------------------------------------
# Run modules
# ----------------------------------------------------------------------------
RESULTS=()

run_module() {
    local name="$1"; local fn="$2"
    if is_skipped "$name"; then
        printf '\n%s[skip] %s (requested via --skip)%s\n' "$C_YELLOW" "$name" "$C_RESET"
        RESULTS+=("$name|Skipped")
        return 0
    fi
    if "$fn"; then
        RESULTS+=("$name|OK")
    else
        RESULTS+=("$name|FAIL")
        if [ "$name" = "prereqs" ]; then
            log_err "Prereqs failed — aborting. See $DEV_ENV_LOG"
            exit 1
        fi
    fi
}

run_module prereqs      invoke_prereqs
run_module vscode       invoke_vscode
run_module git          invoke_git
run_module node         invoke_node
run_module claude_code  invoke_claude_code
run_module terminal     invoke_terminal
run_module github_cli   invoke_github_cli
run_module python       invoke_python

# ----------------------------------------------------------------------------
# Summary
# ----------------------------------------------------------------------------
END_TS=$(date +%s)
ELAPSED=$((END_TS - START_TS))
printf '\n=================================================================\n'
printf '  Installation complete in %dm %ds\n' $((ELAPSED / 60)) $((ELAPSED % 60))
printf '=================================================================\n\n'

printf '%-14s %s\n' "Module" "Status"
printf '%-14s %s\n' "------" "------"
for entry in "${RESULTS[@]}"; do
    name="${entry%%|*}"; status="${entry##*|}"
    printf '%-14s %s\n' "$name" "$status"
done

printf '\nVersions:\n'
for cmd in code git node npm claude gh python3 uv oh-my-posh; do
    if have "$cmd"; then
        v=$("$cmd" --version 2>/dev/null | head -n1 || true)
        printf '  %-12s %s\n' "$cmd" "$v"
    else
        printf '  %-12s %s<not on PATH>%s\n' "$cmd" "$C_YELLOW" "$C_RESET"
    fi
done

cat <<EOF

Next steps:
  1. Open a NEW terminal window (so PATH and profile changes take effect).
  2. Set your git identity:
       git config --global user.name  "Your Name"
       git config --global user.email "you@example.com"
  3. Authenticate with GitHub:
       gh auth login
  4. Start Claude Code in your project:
       claude

Full log: $DEV_ENV_LOG
EOF

# Exit non-zero if any module failed.
for entry in "${RESULTS[@]}"; do
    [ "${entry##*|}" = "FAIL" ] && exit 1
done
exit 0
