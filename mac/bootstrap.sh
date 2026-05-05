#!/usr/bin/env bash
# =============================================================================
# One-liner bootstrap for macOS.
#
# Downloads the repo as a tarball, extracts it to /tmp, and runs
# mac/install.sh from the extracted folder.
#
# Usage (the one-liner the user runs):
#     curl -fsSL https://raw.githubusercontent.com/<USER>/<REPO>/main/mac/bootstrap.sh | bash
#
# Optional environment overrides:
#     REPO=user/repo BRANCH=main bash bootstrap.sh
# =============================================================================

set -euo pipefail

REPO="${REPO:-ronazvili67-a11y/dev-env-installer}"
BRANCH="${BRANCH:-main}"

TMP_ROOT="$(mktemp -d -t dev-env-installer.XXXXXX)"
TARBALL="$TMP_ROOT/repo.tar.gz"
URL="https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz"

printf '\033[36mDownloading %s ...\033[0m\n' "$URL"
curl -fsSL "$URL" -o "$TARBALL"

printf '\033[36mExtracting ...\033[0m\n'
tar -xzf "$TARBALL" -C "$TMP_ROOT"

# Find the extracted folder (named "<repo>-<branch>")
EXTRACTED=$(find "$TMP_ROOT" -mindepth 1 -maxdepth 1 -type d | head -n1)
if [ -z "$EXTRACTED" ]; then
    echo "Could not find extracted repo in $TMP_ROOT" >&2
    exit 1
fi

INSTALLER="$EXTRACTED/mac/install.sh"
if [ ! -f "$INSTALLER" ]; then
    echo "install.sh not found at $INSTALLER" >&2
    exit 1
fi

chmod +x "$INSTALLER"
printf '\033[36mRunning installer at %s ...\033[0m\n' "$INSTALLER"
"$INSTALLER" "$@"

printf '\033[90mTemp folder kept for inspection: %s\033[0m\n' "$TMP_ROOT"
