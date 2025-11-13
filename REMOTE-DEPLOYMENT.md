# GPS Kiosk Remote Machine Deployment Guide

This guide covers deploying the GPS Kiosk system on a remote Windows machine for unattended marine navigation display.

## 📋 Prerequisites

### Hardware Requirements

- **Windows 10/11** (Pro or Enterprise recommended for kiosk features)
- **4GB RAM minimum** (8GB recommended)
- **20GB free disk space**
- **Network connectivity** (for Docker image downloads and updates)
- **Display output** (HDMI/DisplayPort for navigation display)

### Network Requirements

- **Internet access** for initial setup and Docker image downloads
- **Local network access** (if connecting to onboard NMEA devices)
- **Firewall ports**: 3000 (GPS Kiosk web interface)

## 🚀 Deployment Methods

### Method 1: Full Automated Setup (Recommended)

#### Step 1: Download and Extract

```powershell
# On the remote machine, open PowerShell as Administrator
Set-Location C:\
Invoke-WebRequest -Uri "https://github.com/Uncruise/gps-kiosk/archive/refs/heads/main.zip" -OutFile "gps-kiosk.zip"
Expand-Archive -Path "gps-kiosk.zip" -DestinationPath "C:\"
Rename-Item -Path "C:\gps-kiosk-main" -NewName "gps-kiosk"
Remove-Item "gps-kiosk.zip"
Set-Location "C:\gps-kiosk"
```

#### Step 2: Run Automated Setup

```powershell
# Execute the main setup script
.\quick-setup.ps1
```

**What this does:**

- ✅ Configures PowerShell execution policy
- ✅ Installs Docker Desktop with WSL 2 backend
- ✅ Downloads and starts GPS Kiosk containers
- ✅ Creates Windows startup integration
- ✅ Prompts for auto-login configuration

### Method 2: Git-Based Setup (For Development)

#### Step 1: Install Git (if needed)

```powershell
# Install Git via winget
winget install --id Git.Git -e --source winget
```

#### Step 2: Clone and Setup

```powershell
Set-Location C:\
git clone https://github.com/Uncruise/gps-kiosk.git
Set-Location gps-kiosk
.\quick-setup.ps1
```

### Method 3: Manual Docker-Only Setup

#### Step 1: Install Docker Desktop

```powershell
# Download and install Docker Desktop
winget install Docker.DockerDesktop
```

#### Step 2: Configure and Run

```powershell
Set-Location C:\gps-kiosk
docker compose pull
docker compose up -d
```

## 🔧 Remote Configuration Options

### Option A: Interactive Configuration (Remote Desktop)

1. **Connect via Remote Desktop** to the target machine
2. **Run setup scripts** interactively
3. **Configure auto-login** when prompted
4. **Test the system** before disconnecting

### Option B: Scripted Unattended Configuration

```powershell
# Pre-configure auto-login (run as Administrator)
.\configure-auto-login.ps1 -Username "kioskuser" -Password "YourSecurePassword"

# Or use the batch wrapper
.\configure-kiosk.bat
```

### Option C: PowerShell Remoting Setup

```powershell
# On the remote machine (run once as Administrator)
Enable-PSRemoting -Force
Set-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)" -Enabled True

# From your local machine
$cred = Get-Credential
$session = New-PSSession -ComputerName "REMOTE-PC-NAME" -Credential $cred
Invoke-Command -Session $session -ScriptBlock {
    Set-Location C:\gps-kiosk
    .\quick-setup.ps1
}
```

## 🛠️ Configuration Steps

### 1. System Configuration

```powershell
# Set execution policy (if needed)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Enable Windows features for Docker
.\enable-docker-features.ps1

# Install Docker Desktop with WSL 2
.\quick-setup.ps1
```

### 2. Auto-Login Setup (For Unattended Operation)

```powershell
# Configure automatic login (replace with actual credentials)
.\configure-auto-login.ps1 -Username "gpsuser" -Password "YourPassword"
```

### 3. Kiosk Mode Configuration

```powershell
# Apply all kiosk optimizations
.\configure-kiosk.bat
```

### 4. Network Device Configuration (Optional)

Edit `Volume\settings.json` to configure NMEA data sources:

```json
{
  "pipedProviders": [
    {
      "pipeElements": [
        {
          "type": "providers/simple",
          "options": {
            "type": "NMEA0183",
            "subOptions": {
              "type": "tcp",
              "host": "192.168.1.100",
              "port": "23"
            }
          }
        }
      ],
      "id": "GPS-DEVICE",
      "enabled": true
    }
  ]
}
```

## 📡 Remote Management

### Access URLs

- **Navigation Interface**: `http://REMOTE-IP:3000/@signalk/freeboard-sk/?zoom=12&northup=1&movemap=1&kiosk=1`
- **Admin Interface**: `http://REMOTE-IP:3000`
- **SignalK API**: `http://REMOTE-IP:3000/signalk/v1/api/`

### Docker Management Commands

```powershell
# Check container status
docker ps

# View logs
docker logs gps-kiosk

# Restart containers
docker compose restart

# Update to latest
docker compose pull
docker compose up -d --force-recreate

# Stop system
docker compose down
```

### Windows Service Management

```powershell
# Check auto-login status
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

# Check startup entries
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"

# View startup script
Get-Content C:\gps-kiosk\start-gps-kiosk.bat
```

## 🔍 Troubleshooting Remote Issues

### Diagnostic Commands

```powershell
# Run comprehensive diagnostics
.\docker-diagnostic.ps1

# Check Docker status
docker version
docker ps -a

# Check system resources
Get-ComputerInfo | Select TotalPhysicalMemory, CsProcessors
Get-PSDrive C | Select Used, Free, Size

# Test network connectivity
Test-NetConnection -ComputerName "docker.io" -Port 443
Test-NetConnection -ComputerName "localhost" -Port 3000
```

### Common Remote Issues

#### 1. Docker Won't Start

```powershell
# Check Windows features
Get-WindowsOptionalFeature -Online -FeatureName containers, Microsoft-Hyper-V
wsl --status

# Restart Docker Desktop
Stop-Process -Name "Docker Desktop" -Force -ErrorAction SilentlyContinue
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
```

#### 2. Network Access Issues

```powershell
# Check firewall rules
Get-NetFirewallRule -DisplayName "*Docker*" | Where Enabled -eq True
New-NetFirewallRule -DisplayName "GPS Kiosk" -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow
```

#### 3. Auto-Login Not Working

```powershell
# Verify registry settings
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" | 
  Select AutoAdminLogon, DefaultUserName, DefaultPassword
```

#### 4. Container Health Issues

```powershell
# Check container health
docker inspect gps-kiosk --format='{{.State.Health.Status}}'

# View detailed logs
docker logs gps-kiosk --tail 100 --timestamps
```

## 🔐 Security Considerations

### Network Security

- **Firewall**: Only open port 3000 if external access needed
- **VPN**: Use VPN for remote administration
- **Local Network**: Keep on isolated network segment if possible

### System Security

- **User Account**: Create dedicated kiosk user with minimal privileges
- **Auto-Login**: Only enable on physically secure systems
- **Updates**: Configure automatic security updates
- **Monitoring**: Set up remote monitoring for system health

### Access Control

```powershell
# Create limited kiosk user (run as Administrator)
New-LocalUser -Name "kioskuser" -Password (ConvertTo-SecureString "SecurePassword123!" -AsPlainText -Force)
Add-LocalGroupMember -Group "Users" -Member "kioskuser"

# Remove from administrative groups
Remove-LocalGroupMember -Group "Administrators" -Member "kioskuser" -ErrorAction SilentlyContinue
```

## 📊 Monitoring and Maintenance

### Health Check Script

```powershell
# Create monitoring script: monitor-gps-kiosk.ps1
$containerStatus = docker ps --filter "name=gps-kiosk" --format "{{.Status}}"
$webResponse = try { Invoke-WebRequest -Uri "http://localhost:3000/signalk/" -TimeoutSec 5 } catch { $null }

if ($containerStatus -like "*Up*" -and $webResponse.StatusCode -eq 200) {
    Write-Host "GPS Kiosk: HEALTHY" -ForegroundColor Green
    exit 0
} else {
    Write-Host "GPS Kiosk: UNHEALTHY" -ForegroundColor Red
    Write-Host "Container: $containerStatus"
    Write-Host "Web Status: $($webResponse.StatusCode)"
    exit 1
}
```

### Scheduled Maintenance

```powershell
# Create scheduled task for daily updates
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\gps-kiosk\update-gps-kiosk.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At "02:00AM"
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName "GPS Kiosk Daily Update" -Action $action -Trigger $trigger -Principal $principal
```

## 🚀 Deployment Checklist

### Pre-Deployment

- [ ] Remote machine has Windows 10/11
- [ ] Administrator access available
- [ ] Network connectivity confirmed
- [ ] Hardware requirements met

### During Deployment

- [ ] Download/clone GPS Kiosk code
- [ ] Run setup script (`quick-setup.ps1`)
- [ ] Configure auto-login credentials
- [ ] Test Docker containers start
- [ ] Verify web interface accessible

### Post-Deployment

- [ ] Test automatic startup after reboot
- [ ] Configure NMEA data sources (if applicable)
- [ ] Set up remote monitoring
- [ ] Document login credentials securely
- [ ] Test remote access URLs
- [ ] Schedule maintenance tasks

## 📞 Support and Troubleshooting

### Log Locations

- **Docker Logs**: `docker logs gps-kiosk`
- **Windows Event Log**: Event Viewer → Windows Logs → System
- **PowerShell Logs**: `Get-WinEvent -LogName "Windows PowerShell"`

### Common Commands

```powershell
# Quick status check
docker ps && curl -f http://localhost:3000/signalk/

# Full restart
docker compose down && docker compose up -d

# Emergency stop
docker stop gps-kiosk

# View configuration
Get-Content C:\gps-kiosk\Volume\settings.json
```

This comprehensive guide should enable successful deployment of the GPS Kiosk system on any remote Windows machine for unattended marine navigation display.
