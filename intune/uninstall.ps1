# GPS Kiosk Uninstall Script
# This script removes the GPS Kiosk application and cleans up resources

$ErrorActionPreference = "Continue"

Write-Host "Uninstalling GPS Kiosk Application..."

try {
    # Stop and remove Docker containers
    if (Test-Path "C:\gps-kiosk\docker-compose.yml") {
        Set-Location "C:\gps-kiosk"
        Write-Host "Stopping GPS Kiosk containers..."
        docker compose down --volumes --remove-orphans 2>$null
    }
    
    # Remove any lingering containers
    $containers = docker ps -a --filter "name=gps-kiosk" --quiet 2>$null
    if ($containers) {
        Write-Host "Removing GPS Kiosk containers..."
        docker rm -f $containers 2>$null
    }
    
    # Remove Docker images (optional - comment out if you want to keep images)
    # $images = docker images --filter "reference=morrisuca/gps-kiosk" --quiet 2>$null
    # if ($images) {
    #     Write-Host "Removing GPS Kiosk images..."
    #     docker rmi -f $images 2>$null
    # }
    
    # Remove the application directory
    if (Test-Path "C:\gps-kiosk") {
        Write-Host "Removing application files..."
        Remove-Item -Path "C:\gps-kiosk" -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Clean up browser profile (optional)
    if (Test-Path "C:\KioskBrowser") {
        Write-Host "Removing kiosk browser profile..."
        Remove-Item -Path "C:\KioskBrowser" -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host "GPS Kiosk Application uninstalled successfully."
    
}
catch {
    Write-Host "Error during uninstallation: $($_.Exception.Message)"
    exit 1
}

exit 0