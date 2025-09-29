# Docker Desktop Intune Deployment Guide

## Prerequisites
1. Download "Docker Desktop Installer.exe" from https://www.docker.com/products/docker-desktop/
2. Place it in this folder alongside the scripts

## Files in this package:
- `docker-installer.bat` - Entry point for Intune
- `install-docker.ps1` - Installation logic
- `detect-docker.ps1` - Detection script for Intune
- `Docker Desktop Installer.exe` - (You need to download this)

## Intune Configuration for Docker Desktop:

### Install Command:
```
docker-installer.bat
```

### Uninstall Command:
```
"C:\Program Files\Docker\Docker\Docker Desktop.exe" --uninstall
```

### Detection Rule:
Use the `detect-docker.ps1` PowerShell script

### Requirements:
- OS: Windows 10 1607+ or Windows 11
- Architecture: x64
- Disk Space: 4GB
- Memory: 4GB

## Package Creation:
```powershell
.\IntuneWinAppUtil.exe -c .\docker-intune -s docker-installer.bat -o .\intune_out
```

This will create `docker-installer.intunewin` for deployment.