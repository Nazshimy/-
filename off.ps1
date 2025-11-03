<#
.SYNOPSIS
    This script undoes the security script's actions.
    It restores the hosts file from backup and removes the SafeSearch lock.
    !! MUST be run as Administrator !!
#>

# --- Administrator Check ---
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Error: Please run this script as Administrator."
    Write-Host "Press Enter to exit..."
    Read-Host
    exit
}

Write-Host "Starting system restore process..." -ForegroundColor Yellow

# --- Path Settings ---
$hostsDir = "$env:SystemRoot\System32\drivers\etc"
$hostsFilePath = "$hostsDir\hosts"

# Registry paths that were modified
$regPathChrome = "HKLM:\SOFTWARE\Policies\Google\Chrome"
$regPathEdge = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
$regPathBing = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"

try {
    # --- 1. Restore hosts file ---
    Write-Host "Searching for the latest hosts backup file..."
    
    # Find the most recent backup file created by the original script
    $latestBackup = Get-ChildItem -Path $hostsDir -Filter "hosts.backup.*" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

    if ($latestBackup) {
        Write-Host "Backup found: $($latestBackup.FullName)"
        Write-Host "Restoring hosts file from backup..."
        Copy-Item -Path $latestBackup.FullName -Destination $hostsFilePath -Force
        Write-Host "Hosts file restored successfully." -ForegroundColor Green
    } else {
        Write-Warning "Warning: No backup file 'hosts.backup.*' found in '$hostsDir'."
        Write-Warning "Could not restore the hosts file automatically."
    }

    # --- 2. Remove SafeSearch lock ---
    Write-Host "Removing SafeSearch lock from the Registry..."

    # Use separate try/catch for each removal, in case one path doesn't exist
    try {
        if (Test-Path $regPathChrome) {
            Remove-ItemProperty -Path $regPathChrome -Name "ForceSafeSearch" -ErrorAction Stop
            Write-Host "- Removed SafeSearch lock from Chrome."
        }
    } catch {}

    try {
        if (Test-Path $regPathEdge) {
            Remove-ItemProperty -Path $regPathEdge -Name "SafeSearchEnabled" -ErrorAction Stop
            Write-Host "- Removed SafeSearch lock from Edge."
        }
    } catch {}

    try {
        if (Test-Path $regPathBing) {
            # Remove all keys the previous script added
            Remove-ItemProperty -Path $regPathBing -Name "ConnectedSearchSafeSearch" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $regPathBing -Name "AllowSearchToUseLocation" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $regPathBing -Name "DisableWebSearch" -ErrorAction SilentlyContinue
            Write-Host "- Removed SafeSearch lock from Bing (Windows Search)."
        }
    } catch {}
    
    Write-Host "Registry settings restored." -ForegroundColor Green

    # --- Finish ---
    Write-Host "Restore process completed!" -ForegroundColor Green
    Write-Host "For changes to take effect, please restart your browsers."
    Write-Host "In some cases, a full computer restart may be required."

}
catch {
    Write-Warning "A critical error occurred during the restore process:"
    Write-Warning $_.Exception.Message
    Write-Host "The restore may have only been partially completed." -ForegroundColor Red
}

Write-Host "Press Enter to exit..."
Read-Host