<#
.SYNOPSIS
    This script enhances computer security by blocking websites and locking SafeSearch.
    It pulls the block list directly from a GitHub Raw URL.
    !! MUST be run as Administrator !!
#>

# --- Administrator Check ---
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Error: Please run this script as Administrator."
    Write-Host "Press Enter to exit..."
    Read-Host
    exit
}

Write-Host "Starting security process..." -ForegroundColor Green

# --- Settings ---
$hostsFilePath = "$env:SystemRoot\System32\drivers\etc\hosts"

try {
    # --- Section 4: Backup original hosts file ---
    $backupFileName = "$hostsFilePath.backup.$(Get-Date -Format 'yyyy-MM-dd-HHmm')"
    Write-Host "Backing up original hosts file to: $backupFileName"
    Copy-Item -Path $hostsFilePath -Destination $backupFileName -Force
    
    # --- Section 1: Load block list from GitHub ---
    
    # === הקישור שלך הוזן כאן ===
    $blockListUrl = "https://raw.githubusercontent.com/Nazshimy/-/refs/heads/main/list.txt" 
    
    Write-Host "Downloading block list from GitHub: $blockListUrl"
    
    try {
        # IRM יוריד את הקובץ ויחלק אותו אוטומטית למערך של שורות
        $domainsToBlock = Invoke-RestMethod -Uri $blockListUrl -ErrorAction Stop
    }
    catch {
        # אם ההורדה נכשלת, עצור את הסקריפט עם הודעת שגיאה
        throw "Error: Failed to download block list from GitHub. Check the URL or your internet connection."
    }

    if (-not $domainsToBlock -or $domainsToBlock.Count -eq 0) {
        throw "Error: The block list downloaded from GitHub is empty."
    }
    
    Write-Host "Successfully downloaded $($domainsToBlock.Count) domains."


    # --- Section 2: Format and append addresses to hosts file ---
    Write-Host "Formatting domains and updating hosts file..."
    
    # יצירת מערך שיחזיק את השורות המעוצבות
    $formattedLines = @() 
    
    foreach ($domain in $domainsToBlock) {
        # בדיקה שהשורה אינה ריקה
        if (-not [string]::IsNullOrWhiteSpace($domain)) {
            
            # הסרת רווחים מיותרים
            $trimmedDomain = $domain.Trim() 
            
            # הוספת הדומיין הראשי
            $formattedLines += "127.0.0.1 $trimmedDomain"
            
            # בונוס: הוספת גרסת 'www' (אם היא לא קיימת) כדי לחסום גם אותה
            if (-not $trimmedDomain.StartsWith("www.")) {
                $formattedLines += "127.0.0.1 www.$trimmedDomain"
            }
        }
    }
    
    # הוספת כותרת ברורה לקובץ ה-hosts
    $header = "`n# --- Custom GitHub block list added on $(Get-Date) ---`n"
    Add-Content -Path $hostsFilePath -Value $header

    # הוספת השורות החדשות והמעוצבות לקובץ ה-hosts
    Add-Content -Path $hostsFilePath -Value $formattedLines
    
    Write-Host "Hosts file updated successfully."

    # --- Section 3: Force SafeSearch ---
    Write-Host "Forcing SafeSearch settings in browsers..."
    
    # Force SafeSearch in Google Chrome
    $regPathChrome = "HKLM:\SOFTWARE\Policies\Google\Chrome"
    if (-not (Test-Path $regPathChrome)) { New-Item -Path $regPathChrome -Force | Out-Null }
    New-ItemProperty -Path $regPathChrome -Name "ForceSafeSearch" -Value 1 -PropertyType "DWord" -Force | Out-Null
    
    # Force SafeSearch in Microsoft Edge
    $regPathEdge = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
    if (-not (Test-Path $regPathEdge)) { New-Item -Path $regPathEdge -Force | Out-Null }
    New-ItemProperty -Path $regPathEdge -Name "SafeSearchEnabled" -Value 1 -PropertyType "DWord" -Force | Out-Null

    # Force SafeSearch for Bing (affects Edge and Windows Search)
    $regPathBing = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    if (-not (Test-Path $regPathBing)) { New-Item -Path $regPathBing -Force | Out-Null }
    New-ItemProperty -Path $regPathBing -Name "AllowSearchToUseLocation" -Value 0 -PropertyType "DWord" -Force | Out-Null
    New-ItemProperty -Path $regPathBing -Name "DisableWebSearch" -Value 0 -PropertyType "DWord" -Force | Out-Null
    New-ItemProperty -Path $regPathBing -Name "ConnectedSearchSafeSearch" -Value 2 -PropertyType "DWord" -Force | Out-Null

    Write-Host "SafeSearch settings updated successfully."
    
    # --- Finish ---
    Write-Host "Process completed successfully!" -ForegroundColor Green
    Write-Host "It is recommended to restart your browsers or computer."
}
catch {
    Write-Warning "A critical error occurred:"
    Write-Warning $_.Exception.Message
    Write-Host "No changes were made, or only partial changes were made." -ForegroundColor Red
}

Write-Host "Press Enter to exit..."
Read-Host