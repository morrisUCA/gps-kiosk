# install.ps1

$ErrorActionPreference = "Stop"

# Variables
$repoURL = "https://github.com/YOUR_USERNAME/gps-kiosk.git"
$repoPath = "C:\gps-kiosk"
$browserURL = "http://localhost:3000"

# Start Docker Desktop if not running
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe" -ErrorAction SilentlyContinue
Start-Sleep -Seconds 15

# -------------------------------
# Install Git if it's missing
# -------------------------------
if (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) {
    Write-Host "Git not found. Installing..."

    $gitInstaller = "$env:TEMP\git-installer.exe"
    Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.45.1.windows.1/Git-2.45.1-64-bit.exe" -OutFile $gitInstaller

    Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT /NORESTART" -Wait

    if (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) {
        Write-Host "Git install failed."
        exit 1
    }

    Write-Host "Git installed successfully."
}

# Clone or pull latest code
if (Test-Path $repoPath) {
    cd $repoPath
    git reset --hard
    git pull
} else {
    git clone $repoURL $repoPath
    cd $repoPath
}

# Docker compose up
docker compose down
docker compose pull
docker compose up -d

Start-Sleep -Seconds 10

# Open in Edge kiosk mode
Start-Process "msedge.exe" "--kiosk $browserURL --edge-kiosk-type=fullscreen --no-first-run --user-data-dir=C:\KioskBrowser"
