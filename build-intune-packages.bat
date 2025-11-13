@echo off
REM Build Intune Packages Script
REM This script rebuilds the .intunewin packages from source

echo ================================
echo   Building Intune Packages
echo ================================
echo.

REM Check if IntuneWinAppUtil.exe exists
if not exist "tools\IntuneWinAppUtil.exe" (
    echo Error: IntuneWinAppUtil.exe not found in tools folder
    echo Please download it from: https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool
    echo.
    pause
    exit /b 1
)

REM Create output directory if it doesn't exist
if not exist "intune_out" mkdir intune_out

echo Building GPS Kiosk Launcher package...
tools\IntuneWinAppUtil.exe -c intune -s gps-kiosk-launcher.bat -o intune_out
if %ERRORLEVEL% NEQ 0 (
    echo Failed to build GPS Kiosk package
    pause
    exit /b 1
)

echo.
echo Building Docker Installer package...
REM Check if Docker installer exists
if not exist "docker-intune\Docker Desktop Installer.exe" (
    echo Docker Desktop Installer not found.
    echo Downloading Docker Desktop Installer...
    powershell -Command "Invoke-WebRequest -Uri 'https://desktop.docker.com/win/main/amd64/Docker%%20Desktop%%20Installer.exe' -OutFile 'docker-intune\Docker Desktop Installer.exe'"
)

tools\IntuneWinAppUtil.exe -c docker-intune -s docker-installer.bat -o intune_out
if %ERRORLEVEL% NEQ 0 (
    echo Failed to build Docker Installer package
    pause
    exit /b 1
)

echo.
echo ================================
echo   Build Complete!
echo ================================
echo.
echo Generated packages:
dir intune_out\*.intunewin
echo.
echo Ready for Intune deployment.
pause