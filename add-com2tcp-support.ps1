# Add COM2TCP Support to GPS Kiosk
# This script adds conditional COM2TCP startup for SVO-GPS computer

param(
    [string]$StartupScriptPath = "C:\gps-kiosk\start-gps-kiosk.bat"
)

Write-Host "=== Adding COM2TCP Support to GPS Kiosk ===" -ForegroundColor Green

# Check if startup script exists
if (-not (Test-Path $StartupScriptPath)) {
    Write-Host "❌ GPS Kiosk startup script not found: $StartupScriptPath" -ForegroundColor Red
    Write-Host "Please run quick-setup.ps1 first to create the startup script." -ForegroundColor Yellow
    exit 1
}

# Create backup
$backupPath = "$StartupScriptPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item $StartupScriptPath $backupPath
Write-Host "✅ Created backup: $backupPath" -ForegroundColor Green

# Read existing script
$scriptContent = Get-Content $StartupScriptPath -Raw

# Check if COM2TCP logic already exists
if ($scriptContent -like "*COM2TCP*") {
    Write-Host "ℹ️  COM2TCP functionality already exists in startup script." -ForegroundColor Yellow
    exit 0
}

# Find the browser launch line and insert COM2TCP logic before it
$browserLaunchPattern = "echo GPS Kiosk is ready! Launching browser..."
$com2tcpLogic = @"

REM Check computer name and start COM2TCP if needed
echo Checking computer name for specialized configuration...
if "%COMPUTERNAME%"=="SVO-GPS" (
    echo Computer is SVO-GPS, starting COM2TCP for serial data bridge...
    if exist "tools\com2tcp.exe" (
        start "COM2TCP" /min "tools\com2tcp.exe" --baud 4800 \\.\COM4 127.0.0.1 10110
        echo COM2TCP started: COM4 at 4800 baud -> 127.0.0.1:10110
    ) else (
        echo WARNING: COM2TCP executable not found in tools directory
    )
) else (
    echo Computer name is %COMPUTERNAME%, skipping COM2TCP startup
)

"@

# Insert COM2TCP logic before browser launch
$updatedScript = $scriptContent -replace $browserLaunchPattern, "$com2tcpLogic$browserLaunchPattern"

# Write updated script
$updatedScript | Out-File -FilePath $StartupScriptPath -Encoding ASCII

Write-Host "✅ COM2TCP functionality added to GPS Kiosk startup script!" -ForegroundColor Green
Write-Host ""
Write-Host "Computer-specific behavior:" -ForegroundColor Cyan
Write-Host "  • SVO-GPS: Will start COM2TCP bridge (COM4 4800 baud -> 127.0.0.1:10110)" -ForegroundColor White
Write-Host "  • Other computers: Will skip COM2TCP and run normally" -ForegroundColor White
Write-Host ""
Write-Host "To test the updated startup:" -ForegroundColor Yellow
Write-Host "  1. Restart the computer, OR" -ForegroundColor White
Write-Host "  2. Run: $StartupScriptPath" -ForegroundColor White
Write-Host ""

# Show current computer name for reference
Write-Host "Current computer name: $env:COMPUTERNAME" -ForegroundColor Cyan
if ($env:COMPUTERNAME -eq "SVO-GPS") {
    Write-Host "✅ This computer will start COM2TCP on next restart" -ForegroundColor Green
} else {
    Write-Host "ℹ️  This computer will skip COM2TCP (not SVO-GPS)" -ForegroundColor Yellow
}