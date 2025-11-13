# GPS Kiosk Auto-Login and Kiosk Mode Configuration
# This script configures Windows for unattended GPS Kiosk operation

param(
    [Parameter(Mandatory = $true)]
    [string]$Username,
    
    [Parameter(Mandatory = $true)]
    [string]$Password,
    
    [switch]$DisableUpdates,
    [switch]$ShowCurrent
)

Write-Host "=== GPS Kiosk Auto-Login Configuration ===" -ForegroundColor Green
Write-Host ""

# Check if running as Administrator
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

if ($ShowCurrent) {
    Write-Host "=== Current Auto-Login Configuration ===" -ForegroundColor Yellow
    try {
        $autoLoginUser = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultUserName" -ErrorAction SilentlyContinue
        $autoLoginEnabled = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoAdminLogon" -ErrorAction SilentlyContinue
        
        if ($autoLoginEnabled.AutoAdminLogon -eq "1") {
            Write-Host "Auto-Login: ENABLED for user '$($autoLoginUser.DefaultUserName)'" -ForegroundColor Green
        } else {
            Write-Host "Auto-Login: DISABLED" -ForegroundColor Red
        }
        
        # Check startup configuration
        $startupPath = "C:\gps-kiosk\start-gps-kiosk.bat"
        $startupRegistry = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
        $startupEntry = Get-ItemProperty -Path $startupRegistry -Name "GPS-Kiosk" -ErrorAction SilentlyContinue
        
        if ($startupEntry) {
            Write-Host "GPS Kiosk Startup: CONFIGURED" -ForegroundColor Green
            Write-Host "  Command: $($startupEntry.'GPS-Kiosk')" -ForegroundColor White
        } else {
            Write-Host "GPS Kiosk Startup: NOT CONFIGURED" -ForegroundColor Red
        }
        
    } catch {
        Write-Host "Could not read current configuration: $($_.Exception.Message)" -ForegroundColor Red
    }
    exit 0
}

Write-Host "This will configure your computer for unattended GPS Kiosk operation:" -ForegroundColor Yellow
Write-Host "  ✓ Enable automatic login for user: $Username" -ForegroundColor White
Write-Host "  ✓ Add GPS Kiosk to Windows startup" -ForegroundColor White
Write-Host "  ✓ Disable lock screen and screensaver" -ForegroundColor White
Write-Host "  ✓ Keep display always on" -ForegroundColor White
Write-Host "  ✓ Disable Windows update restarts (optional)" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "Continue with kiosk configuration? (y/N)"
if ($confirm -notlike "y*") {
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Configuring auto-login..." -ForegroundColor Yellow

try {
    # Configure auto-login registry entries
    $winlogonPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    
    Set-ItemProperty -Path $winlogonPath -Name "AutoAdminLogon" -Value "1" -Type String
    Set-ItemProperty -Path $winlogonPath -Name "DefaultUserName" -Value $Username -Type String
    Set-ItemProperty -Path $winlogonPath -Name "DefaultPassword" -Value $Password -Type String
    Set-ItemProperty -Path $winlogonPath -Name "AutoLogonCount" -Value 0 -Type DWord
    
    Write-Host "Auto-login configured for user: $Username" -ForegroundColor Green
} catch {
    Write-Host "Failed to configure auto-login: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "Configuring kiosk display settings..." -ForegroundColor Yellow

try {
    # Disable lock screen
    $personalizationPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
    if (-not (Test-Path $personalizationPath)) {
        New-Item -Path $personalizationPath -Force | Out-Null
    }
    Set-ItemProperty -Path $personalizationPath -Name "NoLockScreen" -Value 1 -Type DWord
    
    # Disable screensaver and keep display on
    $screenSaverPath = "HKCU:\Control Panel\Desktop"
    Set-ItemProperty -Path $screenSaverPath -Name "ScreenSaveActive" -Value "0" -Type String
    Set-ItemProperty -Path $screenSaverPath -Name "ScreenSaverIsSecure" -Value "0" -Type String
    Set-ItemProperty -Path $screenSaverPath -Name "ScreenSaveTimeOut" -Value "0" -Type String
    
    # Set power plan to never turn off display
    powercfg /change standby-timeout-ac 0
    powercfg /change standby-timeout-dc 0
    powercfg /change monitor-timeout-ac 0
    powercfg /change monitor-timeout-dc 0
    powercfg /change hibernate-timeout-ac 0
    powercfg /change hibernate-timeout-dc 0
    
    Write-Host "Display settings configured for kiosk mode" -ForegroundColor Green
} catch {
    Write-Host "Warning: Some display settings may not have been applied: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "Adding GPS Kiosk to Windows startup..." -ForegroundColor Yellow

try {
    # Create the startup batch file if it doesn't exist
    $installPath = "C:\gps-kiosk"
    $startupScript = @"
@echo off
REM GPS Kiosk Auto-Startup Script - Runs on every boot
REM This ensures latest updates and launches the kiosk interface

echo Starting GPS Kiosk Auto-Startup...
cd /d "$installPath"

REM Ensure Docker Desktop is running
echo Checking Docker Desktop...
docker version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Starting Docker Desktop...
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    
    REM Wait for Docker to be ready
    :DOCKER_WAIT
    timeout /t 5 /nobreak >nul
    docker version >nul 2>&1
    if %ERRORLEVEL% NEQ 0 goto DOCKER_WAIT
    echo Docker is ready.
)

REM Update repository if Git is available
if exist .git (
    echo Updating GPS Kiosk to latest version...
    git reset --hard HEAD >nul 2>&1
    git pull >nul 2>&1
)

REM Pull latest Docker images
echo Pulling latest Docker images...
docker compose pull >nul 2>&1

REM Stop and restart containers with latest images
echo Starting GPS Kiosk containers...
docker compose down >nul 2>&1
docker compose up -d >nul 2>&1

REM Wait for application to be ready
echo Waiting for GPS Kiosk to start...
timeout /t 15 /nobreak >nul

REM Check if application is responding
:APP_WAIT
powershell -Command "try { `$response = Invoke-WebRequest -Uri 'http://localhost:3000/@signalk/freeboard-sk/' -TimeoutSec 5; if (`$response.StatusCode -eq 200) { exit 0 } else { exit 1 } } catch { exit 1 }" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    timeout /t 5 /nobreak >nul
    goto APP_WAIT
)

echo GPS Kiosk is ready! Launching kiosk interface...
start msedge --kiosk "http://localhost:3000/@signalk/freeboard-sk/?zoom=12&northup=1&movemap=1&kiosk=1" --edge-kiosk-type=fullscreen --no-first-run --user-data-dir=C:\KioskBrowser

echo GPS Kiosk startup complete.
"@

    $startupPath = "$installPath\start-gps-kiosk.bat"
    $startupScript | Out-File -FilePath $startupPath -Encoding ASCII
    
    # Add to Windows startup registry
    $startupRegistry = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    Set-ItemProperty -Path $startupRegistry -Name "GPS-Kiosk" -Value $startupPath
    
    Write-Host "GPS Kiosk added to Windows startup" -ForegroundColor Green
    Write-Host "Startup script: $startupPath" -ForegroundColor White
} catch {
    Write-Host "Failed to configure startup: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

if ($DisableUpdates) {
    Write-Host "Configuring Windows Update settings..." -ForegroundColor Yellow
    try {
        # Disable automatic restart after updates
        $updatePath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        if (-not (Test-Path $updatePath)) {
            New-Item -Path $updatePath -Force | Out-Null
        }
        Set-ItemProperty -Path $updatePath -Name "NoAutoRebootWithLoggedOnUsers" -Value 1 -Type DWord
        Set-ItemProperty -Path $updatePath -Name "AUOptions" -Value 2 -Type DWord  # Notify before downloading
        
        Write-Host "Windows Update restart disabled" -ForegroundColor Green
    } catch {
        Write-Host "Warning: Could not configure Windows Update settings: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== CONFIGURATION COMPLETE ===" -ForegroundColor Green
Write-Host ""
Write-Host "Your GPS Kiosk is now configured for unattended operation:" -ForegroundColor White
Write-Host "  ✓ Auto-login enabled for user: $Username" -ForegroundColor Green
Write-Host "  ✓ GPS Kiosk will start automatically on boot" -ForegroundColor Green
Write-Host "  ✓ Display will stay on (no screensaver/sleep)" -ForegroundColor Green
Write-Host "  ✓ Lock screen disabled" -ForegroundColor Green
if ($DisableUpdates) {
    Write-Host "  ✓ Automatic restart after Windows updates disabled" -ForegroundColor Green
}
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Restart the computer to test the configuration" -ForegroundColor White
Write-Host "2. The computer should automatically:" -ForegroundColor White
Write-Host "   - Log in as $Username" -ForegroundColor Gray
Write-Host "   - Start Docker Desktop" -ForegroundColor Gray
Write-Host "   - Pull latest GPS Kiosk updates" -ForegroundColor Gray
Write-Host "   - Launch the navigation interface in full-screen" -ForegroundColor Gray
Write-Host ""
Write-Host "GPS Kiosk URL: http://localhost:3000/@signalk/freeboard-sk/?zoom=12&northup=1&movemap=1&kiosk=1" -ForegroundColor Cyan
Write-Host ""

$restartNow = Read-Host "Restart computer now to test? (y/N)"
if ($restartNow -like "y*") {
    Write-Host "Restarting computer..." -ForegroundColor Yellow
    Restart-Computer -Force
} else {
    Write-Host "Configuration saved. Restart when ready to test." -ForegroundColor Yellow
}