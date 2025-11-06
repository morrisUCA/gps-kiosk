# Alternative Docker Setup for Remote Machines
# This installs Docker Engine instead of Docker Desktop

param(
    [string]$InstallPath = "C:\gps-kiosk"
)

Write-Host "=== GPS Kiosk Docker Engine Setup (Alternative) ===" -ForegroundColor Green
Write-Host "This is an alternative setup for remote machines without Docker Desktop" -ForegroundColor Yellow
Write-Host ""

# Check if we can use Docker Desktop first
Write-Host "Checking if Docker Desktop is usable..." -ForegroundColor Yellow
try {
    docker version | Out-Null
    Write-Host "Docker Desktop is working! Using regular setup instead..." -ForegroundColor Green
    & .\quick-setup.ps1 -InstallPath $InstallPath
    exit 0
} catch {
    Write-Host "Docker Desktop not working, proceeding with Docker Engine setup..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "WARNING: This remote machine needs Windows features enabled for Docker." -ForegroundColor Red
Write-Host "To fix Docker Desktop properly, run as Administrator:" -ForegroundColor Yellow
Write-Host "  Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All" -ForegroundColor Gray
Write-Host "  Enable-WindowsOptionalFeature -Online -FeatureName Containers -All" -ForegroundColor Gray
Write-Host "  Then restart the computer" -ForegroundColor Gray
Write-Host ""

Write-Host "For now, here's what you can do manually:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Enable Windows Features (REQUIRED):" -ForegroundColor Yellow
Write-Host "   - Run as Administrator: Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All" -ForegroundColor White
Write-Host "   - Run as Administrator: Enable-WindowsOptionalFeature -Online -FeatureName Containers -All" -ForegroundColor White
Write-Host "   - Restart the computer" -ForegroundColor White
Write-Host ""
Write-Host "2. After restart, run:" -ForegroundColor Yellow
Write-Host "   - .\quick-setup.ps1" -ForegroundColor White
Write-Host ""
Write-Host "3. Or download and run manually:" -ForegroundColor Yellow
Write-Host "   - Download repository: git clone https://github.com/morrisUCA/gps-kiosk.git" -ForegroundColor White
Write-Host "   - Run: docker compose up -d" -ForegroundColor White
Write-Host "   - Open: http://localhost:3000" -ForegroundColor White
Write-Host ""

Write-Host "The GPS Kiosk application requires Docker to run the Signal K server." -ForegroundColor Cyan
Write-Host "Without proper Docker setup, the application cannot start." -ForegroundColor Cyan