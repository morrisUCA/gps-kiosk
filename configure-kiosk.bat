@echo off
REM GPS Kiosk Auto-Login and Kiosk Configuration Batch Script
REM This script configures Windows for unattended GPS Kiosk operation

echo.
echo ===============================================
echo    GPS Kiosk Auto-Login Configuration
echo ===============================================
echo.
echo This script will configure your Windows system for:
echo   ✓ Automatic login (no password prompt)
echo   ✓ Kiosk mode startup integration
echo   ✓ GPS navigation auto-launch
echo   ✓ Display power management
echo.
echo WARNING: This will modify Windows registry settings
echo for unattended operation. Only use on dedicated kiosk systems.
echo.

REM Check if running as Administrator
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: This script must be run as Administrator
    echo.
    echo Right-click this batch file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo Running as Administrator ✓
echo.

REM Get current directory
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

REM Check if PowerShell script exists
if not exist "configure-auto-login.ps1" (
    echo ERROR: configure-auto-login.ps1 not found in current directory
    echo Please ensure you're running this from the GPS Kiosk installation folder
    echo.
    pause
    exit /b 1
)

echo.
echo === Current Configuration Status ===
powershell -ExecutionPolicy Bypass -Command "& '.\configure-auto-login.ps1' -ShowCurrent"

echo.
echo ==========================================
echo    Auto-Login Configuration
echo ==========================================
echo.

REM Prompt for username
set /p USERNAME="Enter Windows username for auto-login: "
if "%USERNAME%"=="" (
    echo ERROR: Username cannot be empty
    pause
    exit /b 1
)

REM Prompt for password (Note: This will be visible - for security use PowerShell version)
echo.
echo WARNING: Password will be visible during entry
echo For secure entry, use: configure-auto-login.ps1 directly
echo.
set /p PASSWORD="Enter password for %USERNAME%: "
if "%PASSWORD%"=="" (
    echo ERROR: Password cannot be empty
    pause
    exit /b 1
)

echo.
echo ==========================================
echo    Applying Kiosk Configuration
echo ==========================================
echo.
echo Configuring auto-login for: %USERNAME%
echo.

REM Call PowerShell script with parameters
powershell -ExecutionPolicy Bypass -Command "& '.\configure-auto-login.ps1' -Username '%USERNAME%' -Password '%PASSWORD%'"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Configuration failed
    pause
    exit /b 1
)

echo.
echo ==========================================
echo    Additional Kiosk Optimizations
echo ==========================================
echo.

REM Configure Windows for kiosk mode
echo Applying additional kiosk optimizations...

REM Disable Windows Update restart notifications
echo   ✓ Configuring Windows Update settings...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoRebootWithLoggedOnUsers" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AUPowerManagement" /t REG_DWORD /d 0 /f >nul 2>&1

REM Disable notification center
echo   ✓ Disabling notification center...
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /t REG_DWORD /d 1 /f >nul 2>&1

REM Hide taskbar
echo   ✓ Configuring taskbar for kiosk mode...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAutoHideInTabletMode" /t REG_DWORD /d 1 /f >nul 2>&1

REM Disable Cortana
echo   ✓ Disabling Cortana...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f >nul 2>&1

REM Configure Edge for kiosk mode
echo   ✓ Configuring Microsoft Edge for kiosk...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "KioskModeEnabled" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "NewTabPageSetFeedType" /t REG_DWORD /d 0 /f >nul 2>&1

echo.
echo ==========================================
echo    GPS Kiosk Startup Integration
echo ==========================================
echo.

REM Check if GPS Kiosk startup script exists
if exist "start-gps-kiosk.bat" (
    echo   ✓ GPS Kiosk startup script found
    
    REM Add to registry startup (more reliable than startup folder)
    echo   ✓ Adding GPS Kiosk to Windows startup registry...
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "GPS-Kiosk" /t REG_SZ /d "\"%CD%\start-gps-kiosk.bat\"" /f >nul 2>&1
    
    echo   ✓ GPS Kiosk will start automatically on boot
) else (
    echo   ⚠ GPS Kiosk startup script not found
    echo     Run quick-setup.ps1 or download-setup.ps1 first to create startup scripts
)

echo.
echo ==========================================
echo    Configuration Complete!
echo ==========================================
echo.
echo Auto-login configured for: %USERNAME%
echo GPS Kiosk will start automatically on boot
echo.
echo RESTART REQUIRED for changes to take effect
echo.
echo After restart, your system will:
echo   1. Boot directly to desktop (no login prompt)
echo   2. Start Docker containers automatically  
echo   3. Launch GPS navigation in kiosk mode
echo   4. Display full-screen marine navigation
echo.
echo To verify configuration:
echo   configure-kiosk.bat (run this script again)
echo.
echo To disable auto-login later:
echo   configure-auto-login.ps1 -Username "%USERNAME%" -Password "" -ShowCurrent
echo.

set /p RESTART="Restart computer now? (y/N): "
if /i "%RESTART%"=="y" (
    echo.
    echo Restarting computer in 10 seconds...
    echo Press Ctrl+C to cancel
    timeout /t 10
    shutdown /r /t 0
) else (
    echo.
    echo Please restart your computer manually to apply all changes.
    echo.
    pause
)