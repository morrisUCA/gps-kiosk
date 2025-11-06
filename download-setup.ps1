# GPS Kiosk Anonymous Download and Setup Script
# Downloads from GitHub without requiring login/git

param(
    [string]$InstallPath = "C:\gps-kiosk",
    [string]$TempPath = "$env:TEMP\gps-kiosk-download"
)

$ErrorActionPreference = "Stop"

Write-Host "=== GPS Kiosk Anonymous Download Setup ===" -ForegroundColor Green

# Check if Docker is installed and running
Write-Host "Checking Docker..." -ForegroundColor Yellow
$dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"

if (-not (Test-Path $dockerPath)) {
    Write-Host "Docker Desktop not found. Please install Docker Desktop first." -ForegroundColor Red
    Write-Host "Download from: https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
    exit 1
}

# Ensure Docker Desktop is running
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
        Write-Host "Failed to start Docker Desktop. Please start it manually." -ForegroundColor Red
        exit 1
    }
}

# Wait for Docker daemon to be ready
Write-Host "Waiting for Docker daemon..." -ForegroundColor Yellow
$timeout = 300 # 5 minutes
$elapsed = 0
do {
    Start-Sleep -Seconds 5
    $elapsed += 5
    try {
        docker version | Out-Null
        Write-Host "Docker is ready." -ForegroundColor Green
        break
    } catch {
        if ($elapsed -ge $timeout) {
            Write-Host "Docker daemon timeout. Please check Docker Desktop status." -ForegroundColor Red
            exit 1
        }
    }
} while ($elapsed -lt $timeout)

# Clean up temp directory if it exists
if (Test-Path $TempPath) {
    Remove-Item -Recurse -Force $TempPath
}
New-Item -ItemType Directory -Force -Path $TempPath | Out-Null

# Download repository ZIP from GitHub
Write-Host "Downloading GPS Kiosk from GitHub..." -ForegroundColor Yellow
$zipUrl = "https://github.com/morrisUCA/gps-kiosk/archive/refs/heads/dev-morris.zip"
$zipPath = "$TempPath\gps-kiosk.zip"

try {
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
    Write-Host "Downloaded successfully!" -ForegroundColor Green
} catch {
    Write-Host "Failed to download from GitHub: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Extract the ZIP file
Write-Host "Extracting files..." -ForegroundColor Yellow
try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $TempPath)
    
    # Find the extracted folder (GitHub adds branch name to folder)
    $extractedFolder = Get-ChildItem -Directory -Path $TempPath | Where-Object { $_.Name -like "gps-kiosk-*" } | Select-Object -First 1
    
    if (-not $extractedFolder) {
        throw "Could not find extracted folder"
    }
    
    Write-Host "Extracted to: $($extractedFolder.FullName)" -ForegroundColor Green
} catch {
    Write-Host "Failed to extract ZIP file: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Remove existing installation if it exists
if (Test-Path $InstallPath) {
    Write-Host "Removing existing installation..." -ForegroundColor Yellow
    # Stop any running containers first
    try {
        Set-Location $InstallPath
        docker compose down 2>$null
    } catch {
        # Ignore errors if docker-compose.yml doesn't exist
    }
    Remove-Item -Recurse -Force $InstallPath
}

# Move extracted files to installation directory
Write-Host "Installing to $InstallPath..." -ForegroundColor Yellow
try {
    Move-Item -Path $extractedFolder.FullName -Destination $InstallPath
    Write-Host "Installation files copied successfully!" -ForegroundColor Green
} catch {
    Write-Host "Failed to move files: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Clean up temporary files
Remove-Item -Recurse -Force $TempPath

# Change to installation directory
Set-Location $InstallPath

# Stop any existing containers
Write-Host "Stopping existing containers..." -ForegroundColor Yellow
try {
    docker compose down 2>$null
    Write-Host "Existing containers stopped." -ForegroundColor Green
} catch {
    Write-Host "No existing containers to stop or error occurred." -ForegroundColor Yellow
}

# Pull latest images
Write-Host "Pulling latest Docker images..." -ForegroundColor Yellow
try {
    docker compose pull
    Write-Host "Docker images pulled successfully." -ForegroundColor Green
} catch {
    Write-Host "Warning: Failed to pull images: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "Continuing with existing images..." -ForegroundColor Yellow
}

# Start containers
Write-Host "Starting GPS Kiosk containers..." -ForegroundColor Yellow
try {
    docker compose up -d
    Write-Host "Containers started successfully." -ForegroundColor Green
} catch {
    Write-Host "Failed to start containers: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please check Docker Desktop is running and try again." -ForegroundColor Yellow
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

# Create startup script
Write-Host "Creating startup configuration..." -ForegroundColor Yellow
$startupScript = @"
@echo off
cd /d "$InstallPath"
docker compose up -d
timeout /t 10 /nobreak >nul
start msedge --kiosk "http://localhost:3000/@signalk/freeboard-sk/?zoom=12&northup=1&movemap=1&kiosk=1" --edge-kiosk-type=fullscreen --no-first-run --user-data-dir=C:\KioskBrowser
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
Start-Process "msedge.exe" "--kiosk `"http://localhost:3000/@signalk/freeboard-sk/?zoom=12&northup=1&movemap=1&kiosk=1`" --edge-kiosk-type=fullscreen --no-first-run --user-data-dir=C:\KioskBrowser"

Write-Host ""
Write-Host "=== Setup Complete! ===" -ForegroundColor Green
Write-Host "GPS Kiosk is now running and will start automatically on boot." -ForegroundColor White
Write-Host "Application URL: http://localhost:3000/@signalk/freeboard-sk/?zoom=12&northup=1&movemap=1&kiosk=1" -ForegroundColor White
Write-Host "Installation Path: $InstallPath" -ForegroundColor White
Write-Host "Downloaded from: dev-morris branch" -ForegroundColor White
Write-Host ""
Write-Host "To manage the application:" -ForegroundColor Yellow
Write-Host "  Start:  docker compose up -d" -ForegroundColor White
Write-Host "  Stop:   docker compose down" -ForegroundColor White
Write-Host "  Update: Re-run this script to download latest version" -ForegroundColor White