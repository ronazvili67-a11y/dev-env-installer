# Troubleshooting

## Windows

### `winget : The term 'winget' is not recognized`
ב-Windows 10 ישן (לפני 1809) או Windows Server אין winget מותקן. הסקריפט מנסה להתקין את App Installer אוטומטית מ-`https://aka.ms/getwinget`. אם זה נכשל:
1. פתח את **Microsoft Store**.
2. חפש **App Installer**, התקן.
3. הרץ מחדש את הסקריפט.

### `Running scripts is disabled on this system`
ה-One-Liner משתמש ב-`iex` שמריץ ב-process scope ולא דורש שינוי גלובלי. אם בכל זאת קיבלת את השגיאה — סביר שהרצת `.ps1` מקובץ שירדת. הרץ:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\windows\install.ps1
```

### Defender / SmartScreen חוסם
זה צפוי לסקריפטים אקראיים מהאינטרנט. אישור הריצה הוא החלטה שלך. אפשרויות:
- צפה בקובץ `bootstrap.ps1` לפני הרצה (URL מודגש ב-README).
- הורד את הקובץ ידנית, **Right-click → Properties → Unblock**, ואז הרץ.

### `claude` לא נמצא אחרי ההתקנה
1. סגור את הטרמינל ופתח חלון חדש (PATH מתעדכן רק בתהליכים חדשים).
2. אם זה לא עוזר: בדוק את `%LOCALAPPDATA%\Programs\claude` או `%USERPROFILE%\.local\bin` והוסף ל-PATH.
3. fallback: `npm install -g @anthropic-ai/claude-code`.

### תוסף Claude Code לא נטען ב-VS Code
פתח את VS Code, `Ctrl+Shift+X`, חפש **"Claude Code"** מאת **Anthropic**. ודא שזה ה-extension של `anthropic.claude-code`, ולא משהו אחר.

---

## macOS

### Xcode CLT — דיאלוג GUI חוסם
פעם ראשונה במק שלא מותקן עליו Xcode CLT, הסקריפט מנסה התקנה לא-אינטראקטיבית. אם זה לא עובד, יקפוץ דיאלוג. לחץ **Install** וחכה לסיום (יכול לקחת 10-20 דקות), ואז הרץ את הסקריפט שוב.

### `brew: command not found` אחרי שהסקריפט סיים
הסקריפט הוסיף את `brew shellenv` ל-`~/.zprofile` ו-`~/.bash_profile`. **פתח חלון טרמינל חדש**. אם זה עדיין לא עובד:
```bash
# Apple Silicon
eval "$(/opt/homebrew/bin/brew shellenv)"
# Intel
eval "$(/usr/local/bin/brew shellenv)"
```

### Apple Silicon vs Intel
הסקריפט מזהה אוטומטית. אם אתה על Apple Silicon, brew מותקן ב-`/opt/homebrew`. ב-Intel — `/usr/local`. אין צורך לעשות שום דבר ידנית.

### `code` לא נמצא ב-PATH
פתח את VS Code פעם אחת ידנית, לחץ `Cmd+Shift+P`, ובחר **"Shell Command: Install 'code' command in PATH"**.

### `claude` לא נמצא אחרי ההתקנה
1. פתח טרמינל חדש (לטעינת PATH מעודכן).
2. בדוק את `~/.local/bin` ו-`/usr/local/bin`.
3. fallback: `npm install -g @anthropic-ai/claude-code`.

### תוסף Claude Code לא נטען ב-VS Code
זהה ל-Windows: `Cmd+Shift+X`, חפש **"Claude Code"** מאת **Anthropic** (`anthropic.claude-code`).

---

## כללי

### איך מסירים את ההגדרות?
ה-backups של VS Code settings.json + Git config שלך נשמרו ליד הקובץ המקורי בסיומת `.bak.<timestamp>`. החזר אותם ידנית.

הסקריפטים אינם מסירים את הכלים שהותקנו (winget / brew דואגים לזה — `winget uninstall <id>` או `brew uninstall <name>`).

### לוג של ריצה כושלת
- **Windows**: `%TEMP%\dev-env-installer.log` (פתח עם `notepad`/`code`)
- **macOS**: `/tmp/dev-env-installer.log`

הצורה הכי מהירה לדבג: צרף את הלוג כשפתח issue ב-GitHub.
