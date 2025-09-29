# GPS Kiosk - Intune Deployment Guide

## Overview
This package deploys a GPS Kiosk application using Docker containers, automatically pulling the latest configuration from GitHub and launching in fullscreen kiosk mode.

## Prerequisites
- Windows 10/11 (64-bit)
- Internet connectivity
- Administrator privileges
- Docker Desktop (can be installed separately or as dependency)

## Files Included
- `gps-kiosk-launcher.bat` - Main entry point
- `install.ps1` - Installation script
- `detection.ps1` - Intune detection script
- `uninstall.ps1` - Uninstall script

## Intune Configuration

### Install Command
```
gps-kiosk-launcher.bat
```

### Uninstall Command
```
powershell.exe -ExecutionPolicy Bypass -File "uninstall.ps1"
```

### Detection Rules
Use the provided `detection.ps1` script as a PowerShell detection rule.

### Requirements
- OS: Windows 10 1607+ or Windows 11
- Architecture: x64
- Disk Space: 4GB
- Memory: 4GB

## What the Application Does
1. Installs Git if missing
2. Clones/updates GPS Kiosk repository from GitHub
3. Starts Docker Desktop if not running
4. Deploys GPS Kiosk container with proper volume mounting
5. Launches Microsoft Edge in fullscreen kiosk mode

## Troubleshooting
- Check Docker Desktop is installed and running
- Verify internet connectivity to GitHub and Docker Hub
- Ensure Windows firewall allows Docker and browser connections
- Check Windows Event Logs for PowerShell execution errors

## Support
For issues, check the container logs:
```
docker logs gps-kiosk
```