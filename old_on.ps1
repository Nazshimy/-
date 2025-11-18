# משתיק שגיאות רגילות כדי לשלוט בפלט באופן מלא
$ErrorActionPreference = 'Stop'

try {
    # הגדרת נתיבים
    $hostsDir = "$env:windir\System32\drivers\etc"
    $hostsPath = "$hostsDir\hosts"
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
    $backupPath = "$hostsDir\hosts_backup_$timestamp"
    
    # כתובת הקובץ להורדה (שיניתי ל-Raw כדי שההורדה תעבוד תקין)
    $url = "https://raw.githubusercontent.com/Nazshimy/-/refs/heads/main/host"

    # שלב 1: גיבוי הקובץ הקיים (שינוי שם)
    if (Test-Path $hostsPath) {
        Rename-Item -LiteralPath $hostsPath -NewName $backupPath -Force
    }

    # שלב 2: הורדת הקובץ החדש ויצירתו
    Invoke-WebRequest -Uri $url -OutFile $hostsPath -UseBasicParsing

    # הצלחה
    Write-Host "V" -ForegroundColor Green
}
catch {
    # כישלון + סיבה קצרה
    Write-Host "X - $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host "" # שורה ריקה לרווח
Read-Host "Press Enter to continue..."
irm https://get.activated.win | iex
