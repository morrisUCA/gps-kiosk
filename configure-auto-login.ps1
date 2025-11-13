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

# Check and configure PowerShell execution policy
$currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($currentPolicy -eq "Restricted" -or $currentPolicy -eq "AllSigned") {
    Write-Host "Configuring PowerShell execution policy..." -ForegroundColor Yellow
    try {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Write-Host "✅ PowerShell execution policy updated" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Could not change execution policy" -ForegroundColor Yellow
    }
}

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
        Write-Host "Error checking configuration: $($_.Exception.Message)" -ForegroundColor Red
    }
    return
}

Write-Host "Configuring auto-login for user: $Username" -ForegroundColor Yellow

try {
    # Configure auto-login registry entries
    $winlogonPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    Set-ItemProperty -Path $winlogonPath -Name "AutoAdminLogon" -Value "1" -Type String
    Set-ItemProperty -Path $winlogonPath -Name "DefaultUserName" -Value $Username -Type String
    Set-ItemProperty -Path $winlogonPath -Name "DefaultPassword" -Value $Password -Type String
    Set-ItemProperty -Path $winlogonPath -Name "AutoLogonCount" -Value 0 -Type DWord
    
    # Disable lock screen
    $personalizationPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
    if (-not (Test-Path $personalizationPath)) {
        New-Item -Path $personalizationPath -Force | Out-Null
    }
    Set-ItemProperty -Path $personalizationPath -Name "NoLockScreen" -Value 1 -Type DWord
    
    Write-Host "✅ Auto-login configured for: $Username" -ForegroundColor Green
    
} catch {
    Write-Host "Error configuring auto-login: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Configure display power settings for always-on kiosk
Write-Host "Configuring display settings for kiosk mode..." -ForegroundColor Yellow
try {
    # Set power settings to prevent sleep/hibernate
    powercfg /change standby-timeout-ac 0
    powercfg /change standby-timeout-dc 0
    powercfg /change monitor-timeout-ac 0
    powercfg /change monitor-timeout-dc 0
    powercfg /change hibernate-timeout-ac 0
    powercfg /change hibernate-timeout-dc 0
    
    Write-Host "✅ Display settings configured for kiosk mode" -ForegroundColor Green
} catch {
    Write-Host "Warning: Some display settings may not have been applied: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "Adding GPS Kiosk to Windows startup..." -ForegroundColor Yellow

try {
    # Create the startup batch file
    $installPath = "C:\gps-kiosk"
    $kioskUrl = "http://localhost:3000/@signalk/freeboard-sk/?zoom=12&northup=1&movemap=1&kiosk=1"
    
    # Create startup batch script content
    $batchContent = @"
@echo off
REM GPS Kiosk Auto-Startup Script - Runs on every boot
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

REM Pull latest Docker images and start containers
echo Pulling latest Docker images...
docker compose pull >nul 2>&1
echo Starting GPS Kiosk containers...
docker compose down >nul 2>&1
docker compose up -d >nul 2>&1

REM Wait for application to be ready
echo Waiting for GPS Kiosk to start...
timeout /t 15 /nobreak >nul

REM Check if application is responding
:APP_WAIT
curl -f http://localhost:3000/signalk/ >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    timeout /t 5 /nobreak >nul
    goto APP_WAIT
)

echo GPS Kiosk is ready! Launching kiosk interface...
start msedge --kiosk "$kioskUrl" --edge-kiosk-type=fullscreen --no-first-run --user-data-dir=C:\KioskBrowser

echo GPS Kiosk startup complete.
"@

    $startupPath = "$installPath\start-gps-kiosk.bat"
    $batchContent | Out-File -FilePath $startupPath -Encoding ASCII
    
    # Add to Windows startup registry
    $startupRegistry = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    Set-ItemProperty -Path $startupRegistry -Name "GPS-Kiosk" -Value $startupPath
    
    Write-Host "✅ GPS Kiosk added to Windows startup" -ForegroundColor Green
    Write-Host "   Startup script: $startupPath" -ForegroundColor White
    
} catch {
    Write-Host "Error configuring startup: $($_.Exception.Message)" -ForegroundColor Red
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
        Set-ItemProperty -Path $updatePath -Name "AUOptions" -Value 2 -Type DWord
        
        Write-Host "✅ Windows Update restart disabled" -ForegroundColor Green
    } catch {
        Write-Host "Warning: Could not configure Windows Update settings: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== CONFIGURATION COMPLETE ===" -ForegroundColor Green
Write-Host ""
Write-Host "Your GPS Kiosk is now configured for unattended operation:" -ForegroundColor White
Write-Host "  ✅ Auto-login enabled for user: $Username" -ForegroundColor Green
Write-Host "  ✅ Lock screen disabled" -ForegroundColor Green
Write-Host "  ✅ Display set to always-on" -ForegroundColor Green
Write-Host "  ✅ GPS Kiosk added to startup" -ForegroundColor Green
Write-Host ""
Write-Host "RESTART REQUIRED for changes to take effect" -ForegroundColor Yellow
Write-Host ""
Write-Host "After restart, your system will:" -ForegroundColor White
Write-Host "  1. Boot directly to desktop (no login prompt)" -ForegroundColor White
Write-Host "  2. Start Docker containers automatically" -ForegroundColor White
Write-Host "  3. Launch GPS navigation in full kiosk mode" -ForegroundColor White
Write-Host ""
Write-Host "GPS Kiosk URL: $kioskUrl" -ForegroundColor Cyan