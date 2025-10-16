@echo off
echo =================================
echo    GPS Kiosk Quick Setup
echo =================================
echo.
echo This will:
echo - Clone the GPS Kiosk repository
echo - Pull Docker images
echo - Start the application
echo - Configure startup on boot
echo.
pause

powershell.exe -ExecutionPolicy Bypass -File "%~dp0quick-setup.ps1"

echo.
echo Setup complete! Press any key to exit...
pause >nul