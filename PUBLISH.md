# PUBLISH.md — איך לדחוף ל-GitHub

> מסמך זה מסביר איך הופכים את הפרויקט ל-repo ציבורי ב-GitHub כך שה-One-Liner יעבוד למשתמשים שלך.

## שלב 1 — פתחי repo חדש ב-GitHub

באתר https://github.com/new:
- **Repository name**: `dev-env-installer` (אפשר אחר)
- **Visibility**: Public (כדי שה-One-Liner יוכל למשוך את הקבצים בלי auth)
- **Initialize**: ✗ אל תסמני שום אפשרות (לא README, לא license — כבר יש לנו)

לאחר היצירה, GitHub יציג URL בצורה:
```
https://github.com/<USER>/dev-env-installer.git
```

## שלב 2 — אם יש לך `gh` מותקן (הכי קל)

```bash
cd ~/path/to/dev-env-installer
gh auth login                    # אימות חד-פעמי
gh repo create dev-env-installer --public --source=. --remote=origin --push
```

זה ייצור את ה-repo, יחבר remote, ויעלה הכל בפקודה אחת.

## שלב 3 — או ב-git רגיל

```bash
cd ~/path/to/dev-env-installer
git init -b main
git config user.name  "השם שלך"
git config user.email "האימייל שלך"
git add .
git commit -m "feat: production-ready dev-env installer for Windows + macOS"
git remote add origin https://github.com/<USER>/dev-env-installer.git
git push -u origin main
```

## שלב 4 — עדכון URLs בקבצים

לאחר שה-repo עלה, החליפי את `ronazvili67-a11y/dev-env-installer` בערך האמיתי בקבצים הבאים:

| קובץ | שורה | מחרוזת לחיפוש |
|---|---|---|
| `README.md` | 2 | `ronazvili67-a11y/dev-env-installer` (3 מופעים) |
| `windows/bootstrap.ps1` | param | `ronazvili67-a11y/dev-env-installer` |
| `mac/bootstrap.sh` | REPO= | `ronazvili67-a11y/dev-env-installer` |

פקודה אחת ב-Mac/Linux:
```bash
USER="rona-zvili"          # החליפי בשם המשתמשת שלך ב-GitHub
REPO="dev-env-installer"
find . -type f \( -name '*.md' -o -name '*.sh' -o -name '*.ps1' \) -print0 \
    | xargs -0 sed -i.bak "s|ronazvili67-a11y/dev-env-installer|${USER}/${REPO}|g"
find . -name '*.bak' -delete
git commit -am "chore: update repo URLs"
git push
```

ב-Windows PowerShell:
```powershell
$user = 'rona-zvili'
$repo = 'dev-env-installer'
Get-ChildItem -Recurse -Include *.md,*.sh,*.ps1 | ForEach-Object {
    $c = Get-Content $_.FullName -Raw
    $c2 = $c -replace 'ronazvili67-a11y/dev-env-installer', "$user/$repo"
    if ($c -ne $c2) { Set-Content $_.FullName -Value $c2 -NoNewline }
}
git commit -am "chore: update repo URLs"
git push
```

## שלב 5 — בדיקה

ה-One-Liner עכשיו אמור לעבוד למשתמשים שלך:

```powershell
# Windows
irm https://raw.githubusercontent.com/<USER>/dev-env-installer/main/windows/bootstrap.ps1 | iex
```

```bash
# Mac
curl -fsSL https://raw.githubusercontent.com/<USER>/dev-env-installer/main/mac/bootstrap.sh | bash
```

נסי את ה-Windows מ-VM, ואת ה-Mac מהמחשב של מישהו אחר (או מ-VM Mac), כדי לוודא שזה רץ נקי על מחשב חדש.

## שלב 6 — Releases (אופציונלי, מומלץ)

יצירת release ב-GitHub עם tag:
```bash
git tag -a v1.0.0 -m "First public release"
git push origin v1.0.0
gh release create v1.0.0 --generate-notes
```

ה-bootstrap מוריד מה-`main` branch כברירת מחדל, אבל אפשר לפנות ל-tag ספציפי:
```bash
BRANCH=v1.0.0 curl -fsSL https://raw.githubusercontent.com/<USER>/dev-env-installer/v1.0.0/mac/bootstrap.sh | bash
```

## שלב 7 — README badges (אופציונלי)

הוסיפי לראש ה-`README.md`:

```markdown
![Lint](https://github.com/<USER>/dev-env-installer/actions/workflows/lint.yml/badge.svg)
![Smoke](https://github.com/<USER>/dev-env-installer/actions/workflows/smoke-test.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
```

## שלב 8 — אבטחה

- וודאי ש-Branch protection ב-`main` מסומן: PR-only, CI חייב לעבור.
- אל תאחסני סודות ב-repo. אם בעתיד תוסיפי MCP server שצריך טוקן — תני למשתמש להזריק אותו דרך `gh secret set` ו-env var.
