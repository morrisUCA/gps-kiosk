# GPS Kiosk Detection Script for Intune
# This script checks if the GPS Kiosk application is properly installed and running

try {
    # Check if the repository exists
    if (-not (Test-Path "C:\gps-kiosk\docker-compose.yml")) {
        exit 1
    }
    
    # Check if Docker is available
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        exit 1
    }
    
    # Check if the GPS Kiosk container is running
    $containerStatus = docker ps --filter "name=gps-kiosk" --filter "status=running" --quiet 2>$null
    
    if ($containerStatus) {
        Write-Output "GPS Kiosk is installed and running"
        exit 0
    }
    else {
        # Container exists but not running - still consider it installed
        $containerExists = docker ps -a --filter "name=gps-kiosk" --quiet 2>$null
        if ($containerExists) {
            Write-Output "GPS Kiosk is installed"
            exit 0
        }
        else {
            exit 1
        }
    }
}
catch {
    exit 1
}