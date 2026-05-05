# Dev Environment Installer — One-Click

מתקין-בלחיצה-אחת לסביבת פיתוח מודרנית, עבור **Windows** ו-**macOS**, מוכן לעבוד מיד עם **Claude Code**.

מתקין ומגדיר אוטומטית:

| רכיב | תיאור |
|---|---|
| **VS Code** (latest) | + תוסף Claude Code רשמי + הגדרות best-practices |
| **Git** (latest) | + global config, aliases ו-`.gitignore_global` |
| **Node.js** LTS | + `npm` בגרסה האחרונה |
| **Claude Code** | מהמתקין הרשמי של Anthropic, עם fallback ל-npm |
| **Terminal** | Windows Terminal + Oh My Posh / Oh My Posh ל-zsh במאק |
| **GitHub CLI** (`gh`) | אוטומציה מול GitHub |
| **Python 3.12 + uv** | Runtime + package manager מודרני (Astral) |

הסקריפט **idempotent** — בטוח להריץ אותו שוב ושוב; הוא מדלג על מה שכבר מותקן.

---

## התקנה ב-One-Liner

> ⚠️ **לפני שמשתמשים**: עדכן את ה-URLs כאן ל-repo שלך אחרי `git push`.
> מחליפים `ronazvili67-a11y/dev-env-installer` בפרטים שלך.

### Windows (PowerShell)

פתח **PowerShell** (לא chocoshell, לא cmd, לא Terminal עם profile אחר) והדבק:

```powershell
irm https://raw.githubusercontent.com/ronazvili67-a11y/dev-env-installer/main/windows/bootstrap.ps1 | iex
```

הסקריפט יבקש הרשאות מנהל אוטומטית במידת הצורך.

### macOS (zsh / bash)

פתח **Terminal** והדבק:

```bash
curl -fsSL https://raw.githubusercontent.com/ronazvili67-a11y/dev-env-installer/main/mac/bootstrap.sh | bash
```

המערכת תבקש את סיסמת המשתמש פעם אחת (להתקנת Xcode CLT אם אינו מותקן).

---

## הרצה לוקאלית (מבלי לעשות clone דרך bootstrap)

אחרי `git clone` של הריפו:

```bash
# Windows
.\windows\install.ps1

# macOS
chmod +x mac/install.sh mac/modules/*.sh
./mac/install.sh
```

### דילוג על מודולים

```powershell
# Windows: דלג על Python ו-Terminal
.\windows\install.ps1 -SkipModules Python,Terminal
```

```bash
# macOS: זהה
./mac/install.sh --skip python,terminal
```

מודולים זמינים: `prereqs`, `vscode`, `git`, `node`, `claude_code` (ב-Mac) / `ClaudeCode` (ב-Windows), `terminal`, `github_cli` / `GitHubCli`, `python`.

---

## אחרי ההתקנה — מה לעשות

1. **פתח חלון טרמינל חדש** כדי שכל ה-PATH ייטען.
2. הגדר את הזהות שלך ב-Git (פעם אחת):
   ```bash
   git config --global user.name  "Your Name"
   git config --global user.email "you@example.com"
   ```
3. אמת מול GitHub:
   ```bash
   gh auth login
   ```
4. הפעל את Claude Code בפרויקט:
   ```bash
   cd ~/path/to/project
   claude
   ```

---

## מה בדיוק ייקבע במחשב שלי?

### VS Code (`shared/vscode-settings.json`)
- Format-on-save פעיל
- Auto-save on focus change
- Trailing whitespace + final newline
- Telemetry **כבוי**
- Font: JetBrains Mono / Cascadia Code (אם מותקנים)
- Default formatters לכל שפה (Prettier ל-JS/TS/JSON/HTML/CSS/MD, Black ל-Python)
- Bracket pair colorization, sticky scroll, word wrap

### Git (`shared/gitconfig.template`)
- `init.defaultBranch=main`
- `pull.rebase=true` + `pull.ff=only`
- `push.autoSetupRemote=true` + `push.followTags=true`
- `fetch.prune=true` + `fetch.pruneTags=true`
- `merge.conflictStyle=zdiff3`
- `diff.algorithm=histogram`
- `core.autocrlf=true` ב-Windows / `input` ב-Mac
- Aliases שימושיים: `s`, `co`, `lg`, `amend`, `undo`, `sync`, `pushf`
- `~/.gitignore_global` מאוכלס מראש

### Terminal
- **Windows**: Windows Terminal + Oh My Posh + PSReadLine עם history-based predictions
- **Mac**: Oh My Posh ב-`~/.zshrc` עם aliases (`gs`, `gp`, `gst`, `ll`)

> ⚠️ אם כבר יש לך `settings.json` או `.gitconfig` משלך, הסקריפט יבצע backup לקובץ עם סיומת `.bak.<timestamp>` לפני החלפה. הגדרות Git קיימות אינן נדרסות — רק מפתחות חסרים נוספים.

---

## מה אני מקבל בסוף?

```
$ claude --version          # 1.x.x
$ code --version            # 1.95.x  (+ Claude Code extension פעיל)
$ git --version             # 2.47.x
$ node --version            # v22.x.x
$ npm --version             # 10.x.x
$ gh --version              # 2.x.x
$ python --version          # 3.12.x
$ uv --version              # 0.x.x
$ oh-my-posh --version      # 24.x.x
```

---

## פתרון בעיות

ראה [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) להחלפות נפוצות:
- `winget` לא מותקן ב-Windows ישן
- macOS: Apple Silicon vs Intel paths
- Claude Code לא נמצא אחרי ההתקנה
- VS Code extension לא נטען

לוג מלא של ההרצה נשמר ב:
- **Windows**: `%TEMP%\dev-env-installer.log`
- **macOS**: `/tmp/dev-env-installer.log`

---

## אבטחה ושקיפות

- **קוד פתוח** — כל סקריפט שאתה מריץ נמצא כאן ב-Git, ניתן לקריאה ולאודיט.
- **HTTPS בלבד** לכל הורדה.
- **TLS 1.2+** נכפה ב-PowerShell.
- **לא מתבצעת** העברה של סיסמאות / טוקנים בסקריפט. אימות מול GitHub נעשה אינטראקטיבית בנפרד דרך `gh auth login`.
- כל ההורדות הן ממקור אחד אמין לכל רכיב: **winget**, **Homebrew**, או ה-installers הרשמיים של ספקי הכלים.

לפני שאתה מריץ סקריפט אקראי מהאינטרנט, **תמיד**:
```powershell
# Windows: צפה בקובץ לפני הרצה
irm https://raw.githubusercontent.com/ronazvili67-a11y/dev-env-installer/main/windows/bootstrap.ps1 | more
```
```bash
# macOS: זהה
curl -fsSL https://raw.githubusercontent.com/ronazvili67-a11y/dev-env-installer/main/mac/bootstrap.sh | less
```

---

## תרומה (Contributing)

ראה [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md). בקצרה:
1. fork + branch
2. ערוך
3. CI ירוץ אוטומטית (PSScriptAnalyzer + shellcheck + smoke-test)
4. PR

---

## רישיון

[MIT](LICENSE)
