# PLAN.md — Dev Environment One-Click Installer

> פתרון פרודקשן להתקנה אוטומטית מלאה של סביבת פיתוח מודרנית עבור Windows ו-Mac.
> מטרה: לחיצה אחת = סביבה מלאה ומוכנה לעבודה עם Claude Code.

---

## 1. יעדים (Goals)

1. **התקנה ב-One-Liner אחד** מהטרמינל — אפס שלבים ידניים.
2. **Idempotent** — בטוח להריץ שוב ושוב, מדלג על מה שכבר מותקן.
3. **Cross-architecture** — Windows x64/ARM64, Mac Intel/Apple Silicon.
4. **Zero-trust friendly** — קוד פתוח, ניתן לאודיט, חתום ב-Git.
5. **Auto-recovery** — התקנה כושלת לא משאירה את המערכת במצב שבור.

## 2. רכיבים שיותקנו (Stack)

| # | רכיב | Windows | Mac | למה |
|---|---|---|---|---|
| 1 | **VS Code** (latest stable) | winget: `Microsoft.VisualStudioCode` | brew cask: `visual-studio-code` | IDE ראשי |
| 2 | **VS Code Extension: Claude Code** | `code --install-extension anthropic.claude-code` | זהה | אינטגרציה מלאה של Claude Code ב-IDE |
| 3 | **Git** (latest) | winget: `Git.Git` | brew: `git` | Version control |
| 4 | **Node.js** LTS + npm | winget: `OpenJS.NodeJS.LTS` | brew: `node` | Runtime + package manager |
| 5 | **Claude Code** | `irm https://claude.ai/install.ps1 \| iex` (native) | `curl -fsSL https://claude.ai/install.sh \| bash` (native) | ה-CLI הראשי |
| 6 | **GitHub CLI** (gh) | winget: `GitHub.cli` | brew: `gh` | אוטומציה מול GitHub |
| 7 | **Windows Terminal + Oh My Posh** / **Oh My Posh** | winget: `Microsoft.WindowsTerminal`, `JanDeDobbeleer.OhMyPosh` | brew: `oh-my-posh` | טרמינל מודרני |
| 8 | **Python 3 + uv** | winget: `Python.Python.3.12`, `astral-sh.uv` | brew: `python@3.12 uv` | סקריפטים + MCP servers |

## 3. אדריכלות

```
dev-env-installer/
├── README.md                          # הוראות למשתמש קצה (one-liner)
├── PLAN.md                            # מסמך זה
├── LICENSE                            # MIT
├── .gitignore
├── .editorconfig
│
├── windows/
│   ├── install.ps1                    # entry point — מנהל orchestration
│   ├── modules/
│   │   ├── 00-Common.ps1              # פונקציות עזר (Test-Command, Write-Step, ...)
│   │   ├── 01-Prereqs.ps1             # winget, ExecutionPolicy, TLS 1.2
│   │   ├── 02-VSCode.ps1
│   │   ├── 03-Git.ps1
│   │   ├── 04-Node.ps1
│   │   ├── 05-ClaudeCode.ps1
│   │   ├── 06-Terminal.ps1            # Windows Terminal + Oh My Posh + PSReadLine
│   │   ├── 07-GitHubCli.ps1
│   │   └── 08-Python.ps1              # Python + uv
│   └── configs/
│       └── (מועתק מ-shared/ ב-runtime)
│
├── mac/
│   ├── install.sh                     # entry point
│   ├── modules/
│   │   ├── 00-common.sh               # logging, error handling, Test functions
│   │   ├── 01-prereqs.sh              # Xcode CLT + Homebrew
│   │   ├── 02-vscode.sh
│   │   ├── 03-git.sh
│   │   ├── 04-node.sh
│   │   ├── 05-claude-code.sh
│   │   ├── 06-terminal.sh             # Oh My Posh ל-zsh
│   │   ├── 07-github-cli.sh
│   │   └── 08-python.sh               # python@3.12 + uv
│   └── configs/
│       └── (מועתק מ-shared/ ב-runtime)
│
├── shared/                            # הגדרות מתואמות בין הפלטפורמות
│   ├── vscode-settings.json           # User settings ל-VS Code
│   ├── vscode-extensions.json         # רשימת extensions מומלצים
│   ├── gitconfig.template             # ~/.gitconfig — defaults מודרניים
│   ├── gitignore_global               # ~/.gitignore_global
│   └── oh-my-posh-theme.omp.json      # ערכת נושא לטרמינל
│
├── .github/
│   └── workflows/
│       ├── lint.yml                   # PSScriptAnalyzer + shellcheck
│       └── smoke-test.yml             # dry-run על runners
│
└── docs/
    ├── ARCHITECTURE.md
    ├── TROUBLESHOOTING.md
    └── CONTRIBUTING.md
```

## 4. עקרונות תכנון מרכזיים

### 4.1 Idempotency
לפני התקנת כל רכיב — בדיקה אם כבר מותקן (`Get-Command`, `command -v`). אם כן: דלג, אם לא: התקן. כל מודול חייב להיות נטל-ולהריץ שוב בלי תופעות לוואי.

### 4.2 Error Handling
- **Windows**: `$ErrorActionPreference = 'Stop'` + `try/catch` לכל מודול. לוג שגיאות ל-`%TEMP%\dev-env-installer.log`.
- **Mac**: `set -euo pipefail` + `trap` להודעת שגיאה ידידותית. לוג ל-`/tmp/dev-env-installer.log`.
- כשל ברכיב לא-קריטי (למשל Oh My Posh) לא יעצור את כלל ההתקנה — ימשיך הלאה עם warning.

### 4.3 Privilege Escalation
- **Windows**: הסקריפט מזהה אם רץ ב-Admin. אם לא: מריץ `Start-Process -Verb RunAs` עם re-launch אוטומטי. winget לא דורש admin לרוב, אבל חלק מההתקנות כן.
- **Mac**: לא דורש sudo ל-Homebrew (Homebrew מנהל את עצמו). דורש sudo רק עבור Xcode CLT (פעם אחת).

### 4.4 Network & Security
- כל ההורדות דרך **HTTPS בלבד**.
- TLS 1.2+ נכפה ב-PowerShell.
- לא מעבירים סודות בסקריפט. אם צריך GitHub auth — `gh auth login` (interactive) בסוף.
- מקור אחד אמין לכל רכיב (winget / Homebrew / official native installer).
- **Bootstrap script** קצר ב-root הריפו שמוריד את הריפו המלא, מאמת hash, ומריץ.

### 4.5 Logging
פלט אנושי וצבעוני (`Write-Host -ForegroundColor`, `tput setaf`):
```
[1/8] Prerequisites ........... ✓ Done
[2/8] VS Code ................. ✓ Already installed
[3/8] Git ..................... ✓ Done (configured)
...
```
לוג מלא לקובץ עם timestamps לכל שלב.

### 4.6 Configuration
ההגדרות עצמן (VS Code settings, .gitconfig) נמצאות תחת `shared/` ומועתקות לפלטפורמה היעד דרך `Copy-Item` / `cp`. אם המשתמש כבר הגדיר משהו — נכבד, נציג diff, ונשאל בהמשך (default: skip, override רק עם flag `-Force`).

## 5. התנהגות ה-One-Liner

### Windows (PowerShell)
```powershell
irm https://raw.githubusercontent.com/<USER>/dev-env-installer/main/windows/bootstrap.ps1 | iex
```
`bootstrap.ps1` הוא קובץ זעיר שמוריד zip של הריפו, פורס ל-`$env:TEMP`, ומריץ את `install.ps1`.

### Mac (bash/zsh)
```bash
curl -fsSL https://raw.githubusercontent.com/<USER>/dev-env-installer/main/mac/bootstrap.sh | bash
```
זהה ב-Bash.

## 6. בדיקות (Verification)

### בכל מודול
פונקציה `Test-Installation` מוודאת שהפקודה זמינה אחרי ההתקנה (`code --version`, `git --version`, `node --version`, `claude --version` וכו').

### בסוף הריצה
טבלת סיכום:
```
Component       Version       Status
VS Code         1.95.x        ✓ Installed
Git             2.47.x        ✓ Installed (configured)
Node.js         22.11.x       ✓ Installed
Claude Code     1.x.x         ✓ Installed
...
```

### CI
- **PSScriptAnalyzer** ל-PowerShell (lint + best practices)
- **shellcheck** ל-Bash
- **smoke test** עם `windows-latest` ו-`macos-latest` runners — מריץ את הסקריפטים במצב `--dry-run` כדי לוודא שאין שגיאות סינטקס/לוגיקה.

## 7. שלבי פיתוח (Roadmap)

1. ✅ הקמת מבנה תיקיות
2. 🔄 כתיבת `PLAN.md` (מסמך זה)
3. ⏳ הגדרות משותפות ב-`shared/`
4. ⏳ Windows installer מלא
5. ⏳ Mac installer מלא
6. ⏳ CI workflows
7. ⏳ README למשתמש קצה
8. ⏳ אימות סינטקטי
9. ⏳ git init + הוראות push ל-GitHub

## 8. סיכונים וסיכוני־מפתח

| סיכון | השפעה | מיטיגציה |
|---|---|---|
| winget לא קיים על Windows ישן | התקנה כושלת | בדיקה + הוראה להתקין App Installer מ-MS Store |
| Apple Silicon ↔ Intel paths שונים ב-Homebrew (`/opt/homebrew` vs `/usr/local`) | PATH לא נכון | זיהוי ארכיטקטורה + עדכון `~/.zprofile` בהתאם |
| Anthropic ישנה את ה-URL של ה-native installer | כשל בהתקנת Claude Code | fallback ל-`npm install -g @anthropic-ai/claude-code` |
| המשתמש לא Admin ב-Windows | חלק מההתקנות נכשלות | self-elevation אוטומטית |
| ExecutionPolicy חוסם PowerShell scripts | הסקריפט לא רץ | One-liner משתמש ב-`iex` ב-process scope (לא דורש שינוי גלובלי) |
| הסקריפט נחשד כ-malware ע"י Defender | בלוק | חתימת קוד עתידית + תיעוד hash ב-README |

## 9. תקנים (Standards)

- **PowerShell**: PowerShell 5.1 (default ב-Win10/11) ו-PowerShell 7+ — שני הזמנים נתמכים.
- **Bash**: `bash 3.2+` (default ב-Mac) — לא תלוי ב-bash 4 features.
- **Encoding**: UTF-8 with BOM ל-`.ps1` (כדי שתווי עברית בהודעות יוצגו נכון), UTF-8 ללא BOM ל-`.sh`.
- **Line endings**: LF לכל הקבצים, LF גם ל-`.ps1` (PowerShell 5.1+ תומך).
- **Naming**: kebab-case לקבצי bash, PascalCase לפונקציות PowerShell.

## 10. לאחר ההתקנה — מה המשתמש מקבל

```bash
$ claude --version          # 1.x.x
$ code --version            # 1.95.x (יוצא + extension Claude Code פעיל)
$ git --version             # 2.47.x
$ node --version            # v22.x.x
$ npm --version             # 10.x.x
$ gh --version              # 2.x.x
$ python --version          # 3.12.x
$ uv --version              # 0.x.x
$ oh-my-posh --version      # 24.x.x
```

ב-VS Code:
- Claude Code extension מותקן ופעיל
- settings.json עם best practices (auto-save, format-on-save, telemetry off, וכו')
- extensions מומלצים מותקנים (ESLint, Prettier, EditorConfig, GitLens)

ב-Terminal:
- prompt עם Oh My Posh + git status בכל פקודה
- aliases שימושיים (`gs`, `gp`, `gst` וכו') ב-`.zshrc`/`PROFILE.ps1`

ב-Git:
- `~/.gitconfig` עם defaults מודרניים: `init.defaultBranch=main`, `pull.rebase=true`, `push.autoSetupRemote=true`, `core.autocrlf` נכון לפלטפורמה.
- `~/.gitignore_global` כולל `node_modules/`, `.DS_Store`, `.vscode/settings.json` וכו'.
