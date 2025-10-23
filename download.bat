@echo off
echo =================================
echo    GPS Kiosk Download Setup
echo =================================
echo.
echo This will:
echo - Download GPS Kiosk from GitHub (no login required)
echo - Extract and install the application
echo - Pull Docker images
echo - Start the application
echo - Configure startup on boot
echo.
echo No Git installation or GitHub login required!
echo.
pause

powershell.exe -ExecutionPolicy Bypass -File "%~dp0download-setup.ps1"

echo.
echo Setup complete! Press any key to exit...
pause >nul