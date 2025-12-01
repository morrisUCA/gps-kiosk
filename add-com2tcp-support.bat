@echo off
REM Add COM2TCP functionality to existing GPS Kiosk startup script
REM Run this script to update an existing installation with SVO-GPS specific functionality

echo Adding COM2TCP support to GPS Kiosk startup...

set "startupScript=C:\gps-kiosk\start-gps-kiosk.bat"

if not exist "%startupScript%" (
    echo ERROR: GPS Kiosk startup script not found at %startupScript%
    echo Please run quick-setup.ps1 first to create the startup script.
    pause
    exit /b 1
)

REM Create a backup of the existing script
copy "%startupScript%" "%startupScript%.backup" >nul
echo Created backup: %startupScript%.backup

REM Check if COM2TCP logic already exists
findstr /c:"COM2TCP" "%startupScript%" >nul
if %ERRORLEVEL% EQU 0 (
    echo COM2TCP functionality already exists in startup script.
    pause
    exit /b 0
)

REM Create temporary file with updated script
set "tempScript=%TEMP%\gps-kiosk-updated.bat"

REM Copy everything up to the browser launch
findstr /v /c:"GPS Kiosk is ready" "%startupScript%" > "%tempScript%"

REM Add COM2TCP logic
echo. >> "%tempScript%"
echo REM Check computer name and start COM2TCP if needed >> "%tempScript%"
echo echo Checking computer name for specialized configuration... >> "%tempScript%"
echo if "%%COMPUTERNAME%%"=="SVO-GPS" ^( >> "%tempScript%"
echo     echo Computer is SVO-GPS, starting COM2TCP for serial data bridge... >> "%tempScript%"
echo     if exist "tools\com2tcp.exe" ^( >> "%tempScript%"
echo         start "COM2TCP" /min "tools\com2tcp.exe" --baud 4800 \\.\COM4 127.0.0.1 10110 >> "%tempScript%"
echo         echo COM2TCP started: COM4 at 4800 baud -^> 127.0.0.1:10110 >> "%tempScript%"
echo     ^) else ^( >> "%tempScript%"
echo         echo WARNING: COM2TCP executable not found in tools directory >> "%tempScript%"
echo     ^) >> "%tempScript%"
echo ^) else ^( >> "%tempScript%"
echo     echo Computer name is %%COMPUTERNAME%%, skipping COM2TCP startup >> "%tempScript%"
echo ^) >> "%tempScript%"
echo. >> "%tempScript%"

REM Add the browser launch and completion
echo echo GPS Kiosk is ready! Launching browser... >> "%tempScript%"
echo start msedge --kiosk "http://localhost:3000/@signalk/freeboard-sk/?zoom=12&northup=1&movemap=1&kiosk=1" --edge-kiosk-type=fullscreen --no-first-run --user-data-dir=C:\KioskBrowser >> "%tempScript%"
echo. >> "%tempScript%"
echo echo GPS Kiosk startup complete. >> "%tempScript%"

REM Replace the original script
move "%tempScript%" "%startupScript%"

echo.
echo ✅ COM2TCP functionality added to GPS Kiosk startup script!
echo.
echo Computer-specific behavior:
echo   - SVO-GPS: Will start COM2TCP bridge (COM4 4800 baud -> 127.0.0.1:10110)
echo   - Other computers: Will skip COM2TCP and run normally
echo.
echo To test: restart the computer or run: %startupScript%
echo.
pause