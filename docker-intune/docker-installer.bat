@echo off
mkdir C:\temp 2>nul
echo Starting Docker installation at %date% %time% >> C:\temp\docker-intune.log
powershell.exe -ExecutionPolicy Bypass -File "%~dp0install-docker.ps1" >> C:\temp\docker-intune.log 2>&1
echo Installation completed with exit code %ERRORLEVEL% at %date% %time% >> C:\temp\docker-intune.log
exit %ERRORLEVEL%