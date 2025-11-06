# GPS Kiosk Auto-Setup Script
# Fully automated installation with Docker auto-install, latest pulls, and startup configuration

param(
    [string]$InstallPath = "C:\gps-kiosk"
)

$ErrorActionPreference = "Stop"

Write-Host "=== GPS Kiosk Auto-Setup ===" -ForegroundColor Green

# Function to install Docker Desktop automatically
function Install-DockerDesktop {
    Write-Host "Docker not found. Installing Docker Desktop..." -ForegroundColor Yellow
    
    try {
        # Try winget first (fastest)
        Write-Host "Attempting installation via winget..." -ForegroundColor Yellow
        $result = winget install Docker.DockerDesktop --accept-package-agreements --accept-source-agreements --silent
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Docker Desktop installed via winget." -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "Winget installation failed, trying direct download..." -ForegroundColor Yellow
    }
    
    # Fallback: Direct download
    try {
        Write-Host "Downloading Docker Desktop..." -ForegroundColor Yellow
        $dockerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
        $dockerInstaller = "$env:TEMP\DockerDesktopInstaller.exe"
        
        Invoke-WebRequest -Uri $dockerUrl -OutFile $dockerInstaller -UseBasicParsing
        
        Write-Host "Installing Docker Desktop..." -ForegroundColor Yellow
        $process = Start-Process -FilePath $dockerInstaller -ArgumentList "install --quiet --accept-license" -Wait -PassThru
        
        Remove-Item $dockerInstaller -Force -ErrorAction SilentlyContinue
        
        if ($process.ExitCode -eq 0) {
            Write-Host "Docker Desktop installed successfully." -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "Failed to install Docker: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    
    return $false
}

# Function to ensure Docker Desktop is running
function Start-DockerDesktop {
    $dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    
    if (-not (Test-Path $dockerPath)) {
        return $false
    }
    
    # Check if Docker Desktop is already running
    $dockerProcess = Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue
    if (-not $dockerProcess) {
        Write-Host "Starting Docker Desktop..." -ForegroundColor Yellow
        Start-Process $dockerPath -ErrorAction SilentlyContinue
        
        # Wait for Docker Desktop to start
        $timeout = 180 # 3 minutes
        $elapsed = 0
        do {
            Start-Sleep -Seconds 5
            $elapsed += 5
            $dockerProcess = Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue
        } while (-not $dockerProcess -and $elapsed -lt $timeout)
        
        if (-not $dockerProcess) {
            Write-Host "Failed to start Docker Desktop process." -ForegroundColor Red
            return $false
        }
    }
    
    # Wait for Docker daemon to be ready
    Write-Host "Waiting for Docker daemon to be ready..." -ForegroundColor Yellow
    $timeout = 300 # 5 minutes
    $elapsed = 0
    do {
        Start-Sleep -Seconds 5
        $elapsed += 5
        try {
            $dockerVersionOutput = docker version 2>&1
            $dockerVersionString = $dockerVersionOutput -join " "
            
            # Check for API errors that indicate Docker daemon issues
            if ($dockerVersionString -like "*500 Internal Server Error*" -or 
                $dockerVersionString -like "*Access is denied*" -or
                $dockerVersionString -like "*docker daemon is not running*") {
                throw "Docker daemon has internal errors: $dockerVersionString"
            }
            
            # If we get here without errors, Docker is working
            Write-Host "Docker daemon is ready." -ForegroundColor Green
            return $true
        } catch {
            if ($elapsed -gt 60) {
                Write-Host "   Docker error: $($_.Exception.Message)" -ForegroundColor Red
            }
            # Docker daemon not ready yet, continue waiting
        }
    } while ($elapsed -lt $timeout)
    
    Write-Host "Docker daemon failed to become ready within timeout." -ForegroundColor Red
    Write-Host "This is likely due to missing Windows features (Hyper-V, Containers)." -ForegroundColor Yellow
    Write-Host "Run the diagnostic script: .\docker-diagnostic.ps1" -ForegroundColor Cyan
    return $false
}

# Check and install Docker if needed
Write-Host "Checking Docker..." -ForegroundColor Yellow
$dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"

if (-not (Test-Path $dockerPath)) {
    Write-Host "Docker Desktop not found. Installing..." -ForegroundColor Yellow
    if (-not (Install-DockerDesktop)) {
        Write-Host "Failed to install Docker Desktop. Please install manually." -ForegroundColor Red
        Write-Host "Download from: https://www.docker.com/products/docker-desktop/"
        exit 1
    }
}

# Ensure Docker Desktop is running and daemon is ready
if (-not (Start-DockerDesktop)) {
    Write-Host "Failed to start Docker Desktop or daemon is not responding." -ForegroundColor Red
    Write-Host "Please:" -ForegroundColor Yellow
    Write-Host "1. Manually start Docker Desktop" -ForegroundColor White
    Write-Host "2. Wait for it to fully start (whale icon in system tray)" -ForegroundColor White
    Write-Host "3. Run this script again" -ForegroundColor White
    Write-Host ""
    Write-Host "If Docker Desktop won't start:" -ForegroundColor Yellow
    Write-Host "- Try running as Administrator" -ForegroundColor White
    Write-Host "- Check Windows features: Hyper-V and Containers" -ForegroundColor White
    Write-Host "- Restart your computer" -ForegroundColor White
    exit 1
}

# Auto-install Git if needed
Write-Host "Checking Git..." -ForegroundColor Yellow
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git not found. Installing Git..." -ForegroundColor Yellow
    try {
        winget install Git.Git --accept-package-agreements --accept-source-agreements --silent
        
        # Refresh PATH
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
        
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            throw "Git installation verification failed"
        }
        Write-Host "Git installed successfully." -ForegroundColor Green
    } catch {
        Write-Host "Warning: Git installation failed. Will use direct download method." -ForegroundColor Yellow
    }
}

# Function to get repository via Git or direct download
function Get-Repository {
    param([string]$Path)
    
    if (Test-Path $Path) {
        Write-Host "Repository exists. Updating to latest..." -ForegroundColor Yellow
        Set-Location $Path
        
        if (Get-Command git -ErrorAction SilentlyContinue) {
            try {
                git reset --hard HEAD  # Ensure clean state
                git pull
                Write-Host "Repository updated via Git." -ForegroundColor Green
                return
            } catch {
                Write-Host "Git pull failed, trying fresh download..." -ForegroundColor Yellow
                Remove-Item -Recurse -Force $Path
            }
        }
    }
    
    # Use Git if available
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Host "Cloning repository via Git..." -ForegroundColor Yellow
        try {
            git clone https://github.com/morrisUCA/gps-kiosk.git $Path
            Set-Location $Path
            Write-Host "Repository cloned via Git." -ForegroundColor Green
            return
        } catch {
            Write-Host "Git clone failed, trying direct download..." -ForegroundColor Yellow
        }
    }
    
    # Fallback: Direct download
    Write-Host "Downloading repository as ZIP..." -ForegroundColor Yellow
    $tempPath = "$env:TEMP\gps-kiosk-download"
    $zipUrl = "https://github.com/morrisUCA/gps-kiosk/archive/refs/heads/dev-morris.zip"
    $zipPath = "$tempPath\gps-kiosk.zip"
    
    if (Test-Path $tempPath) {
        Remove-Item -Recurse -Force $tempPath
    }
    New-Item -ItemType Directory -Force -Path $tempPath | Out-Null
    
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
    
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $tempPath)
    
    $extractedFolder = Get-ChildItem -Directory -Path $tempPath | Where-Object { $_.Name -like "gps-kiosk-*" } | Select-Object -First 1
    
    if (Test-Path $Path) {
        Remove-Item -Recurse -Force $Path
    }
    
    Move-Item -Path $extractedFolder.FullName -Destination $Path
    Remove-Item -Recurse -Force $tempPath
    Set-Location $Path
    Write-Host "Repository downloaded and extracted." -ForegroundColor Green
}

# Get latest repository
Write-Host "Setting up repository..." -ForegroundColor Yellow
Get-Repository -Path $InstallPath

# Ensure Volume directory has latest config from GitHub
Write-Host "Ensuring Volume has latest configuration..." -ForegroundColor Yellow
$volumePath = "$InstallPath\Volume"
if (-not (Test-Path $volumePath)) {
    Write-Host "Creating Volume directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $volumePath | Out-Null
}

# Stop any existing containers to update safely
Write-Host "Stopping existing containers..." -ForegroundColor Yellow
try {
    $downOutput = docker compose down 2>&1
    $downString = $downOutput -join " "
    
    if ($downString -like "*500 Internal Server Error*" -or $downString -like "*Access is denied*") {
        throw "Docker API Error: $downString"
    }
    Write-Host "Existing containers stopped." -ForegroundColor Green
} catch {
    Write-Host "No existing containers to stop or Docker error: $($_.Exception.Message)" -ForegroundColor Yellow
    if ($_.Exception.Message -like "*500 Internal Server Error*") {
        Write-Host "ERROR: Docker daemon has internal errors. Check Windows features." -ForegroundColor Red
        Write-Host "Run: .\docker-diagnostic.ps1 for detailed diagnostics" -ForegroundColor Cyan
        exit 1
    }
}

# Always pull latest Docker images from Docker Hub
Write-Host "Pulling latest Docker images from Docker Hub..." -ForegroundColor Yellow
try {
    $pullOutput = docker compose pull 2>&1
    $pullString = $pullOutput -join " "
    
    if ($pullString -like "*500 Internal Server Error*" -or $pullString -like "*Access is denied*") {
        throw "Docker API Error: $pullString"
    }
    Write-Host "Docker images pulled successfully." -ForegroundColor Green
} catch {
    Write-Host "Warning: Failed to pull images: $($_.Exception.Message)" -ForegroundColor Yellow
    if ($_.Exception.Message -like "*500 Internal Server Error*") {
        Write-Host "ERROR: Docker daemon has internal errors. Cannot pull images." -ForegroundColor Red
        Write-Host "Run: .\docker-diagnostic.ps1 for detailed diagnostics" -ForegroundColor Cyan
        exit 1
    }
    Write-Host "Continuing with existing images..." -ForegroundColor Yellow
}

# Start containers
Write-Host "Starting GPS Kiosk containers..." -ForegroundColor Yellow
try {
    $upOutput = docker compose up -d 2>&1
    $upString = $upOutput -join " "
    
    if ($upString -like "*500 Internal Server Error*" -or $upString -like "*Access is denied*") {
        throw "Docker API Error: $upString"
    }
    Write-Host "Containers started successfully." -ForegroundColor Green
} catch {
    Write-Host "Failed to start containers: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Message -like "*500 Internal Server Error*") {
        Write-Host "ERROR: Docker daemon has internal errors. Cannot start containers." -ForegroundColor Red
        Write-Host "This is caused by missing Windows features." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "SOLUTION:" -ForegroundColor Cyan
        Write-Host "1. Run as Administrator:" -ForegroundColor White
        Write-Host "   Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All" -ForegroundColor Gray
        Write-Host "   Enable-WindowsOptionalFeature -Online -FeatureName Containers -All" -ForegroundColor Gray
        Write-Host "2. Restart the computer" -ForegroundColor White
        Write-Host "3. Run this script again" -ForegroundColor White
    }
    exit 1
}

# Wait for application to be ready
Write-Host "Waiting for application to start..." -ForegroundColor Yellow
$maxAttempts = 30
$attempt = 0
$appReady = $false

do {
    Start-Sleep -Seconds 2
    $attempt++
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000/@signalk/freeboard-sk/" -TimeoutSec 5 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            $appReady = $true
            Write-Host "Application is ready!" -ForegroundColor Green
            break
        }
    } catch {
        # Application not ready yet
    }
} while ($attempt -lt $maxAttempts)

if (-not $appReady) {
    Write-Host "Warning: Application may not be fully ready, but continuing..." -ForegroundColor Yellow
}

# Create enhanced startup script that auto-updates and launches
Write-Host "Creating auto-restart startup configuration..." -ForegroundColor Yellow
$startupScript = @"
@echo off
REM GPS Kiosk Auto-Startup Script
REM This runs on every boot and ensures latest updates

echo Starting GPS Kiosk Auto-Startup...
cd /d "$InstallPath"

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

REM Pull latest images from Docker Hub
echo Pulling latest Docker images...
docker compose pull

REM Stop and restart containers with latest images
echo Restarting containers with latest configuration...
docker compose down
docker compose up -d

REM Wait for application to be ready
echo Waiting for GPS Kiosk to start...
timeout /t 15 /nobreak >nul

REM Check if application is responding
:APP_WAIT
powershell -Command "try { `$response = Invoke-WebRequest -Uri 'http://localhost:3000/@signalk/freeboard-sk/' -TimeoutSec 5; if (`$response.StatusCode -eq 200) { exit 0 } else { exit 1 } } catch { exit 1 }" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    timeout /t 5 /nobreak >nul
    goto APP_WAIT
)

echo GPS Kiosk is ready! Launching browser...
start msedge --kiosk "http://localhost:3000/@signalk/freeboard-sk/?zoom=12&northup=1&movemap=1&kiosk=1" --edge-kiosk-type=fullscreen --no-first-run --user-data-dir=C:\KioskBrowser

echo GPS Kiosk startup complete.
"@

$startupPath = "$InstallPath\start-gps-kiosk.bat"
$startupScript | Out-File -FilePath $startupPath -Encoding ASCII

# Create update script for manual updates
$updateScript = @"
@echo off
REM GPS Kiosk Update Script
echo Updating GPS Kiosk to latest version...
cd /d "$InstallPath"

REM Update repository
if exist .git (
    echo Updating from Git...
    git reset --hard HEAD
    git pull
) else (
    echo Git not available, manual update required.
)

REM Pull latest Docker images
echo Pulling latest Docker images...
docker compose pull

REM Restart with latest
echo Restarting with latest updates...
docker compose down
docker compose up -d

echo Update complete!
pause
"@

$updatePath = "$InstallPath\update-gps-kiosk.bat"
$updateScript | Out-File -FilePath $updatePath -Encoding ASCII

# Create Windows startup shortcut
$startupFolder = [Environment]::GetFolderPath("Startup")
$shortcutPath = "$startupFolder\GPS Kiosk.lnk"

$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = $startupPath
$Shortcut.WorkingDirectory = $InstallPath
$Shortcut.Description = "GPS Kiosk Auto-Startup"
$Shortcut.Save()

Write-Host "Auto-startup configured:" -ForegroundColor Green
Write-Host "  - Startup script: $startupPath" -ForegroundColor White
Write-Host "  - Update script: $updatePath" -ForegroundColor White
Write-Host "  - Windows startup: $shortcutPath" -ForegroundColor White

# Launch the application now
Write-Host "Launching GPS Kiosk..." -ForegroundColor Green
Start-Process "msedge.exe" "--kiosk `"http://localhost:3000/@signalk/freeboard-sk/?zoom=12&northup=1&movemap=1&kiosk=1`" --edge-kiosk-type=fullscreen --no-first-run --user-data-dir=C:\KioskBrowser"

Write-Host ""
Write-Host "=== Auto-Setup Complete! ===" -ForegroundColor Green
Write-Host "GPS Kiosk will now:" -ForegroundColor White
Write-Host "  ✅ Auto-start on every boot" -ForegroundColor White
Write-Host "  ✅ Auto-pull latest Docker images" -ForegroundColor White
Write-Host "  ✅ Auto-update Volume config from GitHub" -ForegroundColor White
Write-Host "  ✅ Auto-launch in kiosk mode" -ForegroundColor White
Write-Host ""
Write-Host "Application URL: http://localhost:3000/@signalk/freeboard-sk/?zoom=12&northup=1&movemap=1&kiosk=1" -ForegroundColor Cyan
Write-Host "Installation Path: $InstallPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Manual operations:" -ForegroundColor Yellow
Write-Host "  Update: Run update-gps-kiosk.bat" -ForegroundColor White
Write-Host "  Stop:   docker compose down" -ForegroundColor White
Write-Host "  Start:  docker compose up -d" -ForegroundColor White