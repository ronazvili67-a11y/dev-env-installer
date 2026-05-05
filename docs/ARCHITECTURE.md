# Architecture

## Decision log

### Why winget on Windows?
Built into Windows 10 1809+ and Windows 11. No third-party dependency. Microsoft-curated catalog with cryptographically signed installers. Alternatives considered: Chocolatey (third-party trust + `Set-ExecutionPolicy` baggage), Scoop (per-user, not all packages available).

### Why Homebrew on Mac?
De-facto standard. Auto-detects Apple Silicon vs Intel. Cask system gives us a uniform interface for GUI apps (VS Code) and CLI tools (`gh`, `node`).

### Why `https://claude.ai/install.{ps1,sh}` for Claude Code?
Anthropic's officially-recommended method since Oct 2025. Bundles its own runtime — no dependency on a specific Node.js. Auto-updates in the background. We keep `npm install -g @anthropic-ai/claude-code` as a fallback in case the native installer URL is temporarily unreachable.

### Why a separate `bootstrap.{ps1,sh}` instead of running `install.{ps1,sh}` directly via the one-liner?
The orchestrator needs sibling modules + shared configs from the repo. Piping just `install.ps1` through `iex` has no way to access `modules/` or `shared/`. The bootstrap downloads the whole repo as a zip/tarball, extracts it, and then runs the orchestrator from the extracted location.

### Why module-per-tool instead of one big script?
- Each module is small and reviewable.
- A user can skip modules with `-SkipModules` / `--skip`.
- Easier to add/remove tools without touching the orchestrator.
- Failure isolation: one failing module doesn't kill the rest.

### Why split `windows/` and `mac/` instead of cross-platform tooling?
Native PowerShell on Windows and native Bash on Mac give us the smoothest install for *everyone* — no need to install bash on Windows or PowerShell on Mac before the script even starts. Shared configuration (VS Code settings, `.gitconfig` template, theme JSON) lives in `shared/` and is consumed by both.

## Lifecycle of a run

```
   user runs one-liner
            │
            ▼
   bootstrap.{ps1,sh}            ← downloads repo zip/tar.gz, extracts, invokes
            │
            ▼
   install.{ps1,sh}              ← orchestrator
            │
   ┌────────┴────────┐
   ▼                 ▼
   modules/00-*    shared helpers (logging, idempotency, brew/winget wrappers)
   modules/01-*    prereqs        ← FATAL on failure
   modules/02-*    vscode
   modules/03-*    git
   modules/04-*    node
   modules/05-*    claude-code
   modules/06-*    terminal       ← non-fatal
   modules/07-*    github-cli     ← non-fatal
   modules/08-*    python         ← non-fatal
            │
            ▼
       summary table
```

## Idempotency contract

Every module must, *before* installing:
1. Check whether the tool is already present (`Test-Command` / `have`).
2. Check whether the package manager (winget / brew) already lists it as installed.
3. Compare configuration before overwriting; back up existing user files (e.g. VS Code `settings.json`) with a timestamped `.bak`.
4. Use the package manager's own idempotency (`winget install` is a no-op when the package matches; `brew list` short-circuits).

## Privilege model

| Platform | Action | Privilege |
|---|---|---|
| Windows | `winget` package install | Per-package (most don't need admin, some do) |
| Windows | `code --install-extension` | User |
| Windows | Profile patch | User |
| macOS | Homebrew install | None (manages itself) |
| macOS | Xcode CLT install | `sudo` (one prompt, only first run) |
| macOS | Profile patch | User |

Windows orchestrator self-elevates when not Admin, unless `-NoElevate`. Mac orchestrator never self-elevates — `brew` refuses to run as root on purpose.

## Failure model

- `Prereqs` failure: **fatal**, abort.
- Any other module failure: warned, logged, continued. The summary table shows `FAIL` and the run exits non-zero so CI catches it.
- Each module wraps its own work; the orchestrator catches exceptions per-module.

## Logs

Single append-only log per run:
- Windows: `%TEMP%\dev-env-installer.log`
- macOS: `/tmp/dev-env-installer.log`

Format: `<ISO timestamp>   <level> <message>`. Both stdout and the log get the same content; stdout is colored, the log isn't.
