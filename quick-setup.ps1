# GPS Kiosk Quick Setup Script
# This script clones the repo, sets up Docker, and configures startup

param(
    [string]$InstallPath = "C:\gps-kiosk"
)

$ErrorActionPreference = "Stop"

Write-Host "=== GPS Kiosk Quick Setup ===" -ForegroundColor Green

# Check if Docker is installed and running
Write-Host "Checking Docker..." -ForegroundColor Yellow
try {
    docker version | Out-Null
    Write-Host "Docker is available." -ForegroundColor Green
}
catch {
    Write-Host "Docker is not available. Please install Docker Desktop first." -ForegroundColor Red
    Write-Host "Download from: https://www.docker.com/products/docker-desktop/"
    exit 1
}

# Check if Git is installed
Write-Host "Checking Git..." -ForegroundColor Yellow
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git not found. Installing Git..." -ForegroundColor Yellow
    winget install Git.Git --accept-package-agreements --accept-source-agreements --silent
    
    # Refresh PATH
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
    
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "Git installation failed. Please install Git manually." -ForegroundColor Red
        exit 1
    }
}

# Clone or update repository
Write-Host "Setting up repository..." -ForegroundColor Yellow
if (Test-Path $InstallPath) {
    Write-Host "Repository exists. Updating..." -ForegroundColor Yellow
    Set-Location $InstallPath
    git pull
}
else {
    Write-Host "Cloning repository..." -ForegroundColor Yellow
    git clone https://github.com/morrisUCA/gps-kiosk.git $InstallPath
    Set-Location $InstallPath
}

# Stop any existing containers
Write-Host "Stopping existing containers..." -ForegroundColor Yellow
docker compose down 2>$null

# Pull latest images
Write-Host "Pulling latest Docker images..." -ForegroundColor Yellow
docker compose pull

# Start containers
Write-Host "Starting GPS Kiosk containers..." -ForegroundColor Yellow
docker compose up -d

# Wait for application to be ready
Write-Host "Waiting for application to start..." -ForegroundColor Yellow
$maxAttempts = 30
$attempt = 0
$appReady = $false

do {
    Start-Sleep -Seconds 2
    $attempt++
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 5 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            $appReady = $true
            Write-Host "Application is ready!" -ForegroundColor Green
            break
        }
    }
    catch {
        # Application not ready yet
    }
} while ($attempt -lt $maxAttempts)

if (-not $appReady) {
    Write-Host "Warning: Application may not be fully ready, but continuing..." -ForegroundColor Yellow
}

# Create startup script
Write-Host "Creating startup configuration..." -ForegroundColor Yellow
$startupScript = @"
@echo off
cd /d "$InstallPath"
docker compose up -d
timeout /t 10 /nobreak >nul
start msedge --kiosk http://localhost:3000 --edge-kiosk-type=fullscreen --no-first-run --user-data-dir=C:\KioskBrowser
"@

$startupPath = "$InstallPath\start-gps-kiosk.bat"
$startupScript | Out-File -FilePath $startupPath -Encoding ASCII

# Create Windows startup shortcut
$startupFolder = [Environment]::GetFolderPath("Startup")
$shortcutPath = "$startupFolder\GPS Kiosk.lnk"

$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = $startupPath
$Shortcut.WorkingDirectory = $InstallPath
$Shortcut.Description = "GPS Kiosk Application"
$Shortcut.Save()

Write-Host "Startup shortcut created at: $shortcutPath" -ForegroundColor Green

# Launch the application now
Write-Host "Launching GPS Kiosk..." -ForegroundColor Green
Start-Process "msedge.exe" "--kiosk http://localhost:3000 --edge-kiosk-type=fullscreen --no-first-run --user-data-dir=C:\KioskBrowser"

Write-Host ""
Write-Host "=== Setup Complete! ===" -ForegroundColor Green
Write-Host "GPS Kiosk is now running and will start automatically on boot." -ForegroundColor White
Write-Host "Application URL: http://localhost:3000" -ForegroundColor White
Write-Host "Installation Path: $InstallPath" -ForegroundColor White
Write-Host ""
Write-Host "To manage the application:" -ForegroundColor Yellow
Write-Host "  Start:  docker compose up -d" -ForegroundColor White
Write-Host "  Stop:   docker compose down" -ForegroundColor White
Write-Host "  Update: git pull && docker compose pull && docker compose up -d" -ForegroundColor White