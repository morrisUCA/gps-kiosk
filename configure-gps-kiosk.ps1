# GPS Kiosk Configuration Helper
# Use this script to easily modify common GPS Kiosk settings

param(
    [string]$GpsHost,
    [int]$GpsPort,
    [decimal]$MapCenterLat,
    [decimal]$MapCenterLon,
    [int]$MapZoom,
    [switch]$ShowCurrent
)

$volumePath = "C:\repo\gps-kiosk\Volume"
$settingsFile = "$volumePath\settings.json"
$freeboardFile = "$volumePath\applicationData\users\admin\freeboard\1.0.0.json"

if ($ShowCurrent) {
    Write-Host "=== Current GPS Kiosk Configuration ===" -ForegroundColor Green
    Write-Host ""
    
    if (Test-Path $settingsFile) {
        $settings = Get-Content $settingsFile | ConvertFrom-Json
        $gpsProvider = $settings.pipedProviders | Where-Object { $_.id -eq "WND" }
        if ($gpsProvider) {
            $tcpOptions = $gpsProvider.pipeElements[0].options.subOptions
            Write-Host "GPS Data Source:" -ForegroundColor Yellow
            Write-Host "  Host: $($tcpOptions.host)" -ForegroundColor White
            Write-Host "  Port: $($tcpOptions.port)" -ForegroundColor White
            Write-Host "  Type: $($tcpOptions.type)" -ForegroundColor White
        }
    }
    
    if (Test-Path $freeboardFile) {
        $freeboard = Get-Content $freeboardFile | ConvertFrom-Json
        Write-Host ""
        Write-Host "Map Configuration:" -ForegroundColor Yellow
        Write-Host "  Center: $($freeboard.map.center[0]), $($freeboard.map.center[1])" -ForegroundColor White
        Write-Host "  Zoom Level: $($freeboard.map.zoomLevel)" -ForegroundColor White
        Write-Host "  Dark Mode: $($freeboard.darkMode.enabled)" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "To modify settings, use parameters:" -ForegroundColor Cyan
    Write-Host "  .\configure-gps-kiosk.ps1 -GpsHost '192.168.1.100' -GpsPort 23" -ForegroundColor Gray
    Write-Host "  .\configure-gps-kiosk.ps1 -MapCenterLat 27.7634 -MapCenterLon -6.8447 -MapZoom 15" -ForegroundColor Gray
    return
}

$changes = @()

# Update GPS settings
if ($GpsHost -or $GpsPort) {
    Write-Host "Updating GPS data source..." -ForegroundColor Yellow
    
    if (Test-Path $settingsFile) {
        $settings = Get-Content $settingsFile | ConvertFrom-Json
        $gpsProvider = $settings.pipedProviders | Where-Object { $_.id -eq "WND" }
        
        if ($gpsProvider) {
            if ($GpsHost) {
                $gpsProvider.pipeElements[0].options.subOptions.host = $GpsHost
                $changes += "GPS Host: $GpsHost"
            }
            if ($GpsPort) {
                $gpsProvider.pipeElements[0].options.subOptions.port = $GpsPort.ToString()
                $changes += "GPS Port: $GpsPort"
            }
            
            $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsFile
            Write-Host "GPS settings updated." -ForegroundColor Green
        }
    }
}

# Update map settings
if ($MapCenterLat -or $MapCenterLon -or $MapZoom) {
    Write-Host "Updating map configuration..." -ForegroundColor Yellow
    
    if (Test-Path $freeboardFile) {
        $freeboard = Get-Content $freeboardFile | ConvertFrom-Json
        
        if ($MapCenterLat -or $MapCenterLon) {
            if ($MapCenterLat) { $freeboard.map.center[0] = $MapCenterLat }
            if ($MapCenterLon) { $freeboard.map.center[1] = $MapCenterLon }
            $changes += "Map Center: $($freeboard.map.center[0]), $($freeboard.map.center[1])"
        }
        
        if ($MapZoom) {
            $freeboard.map.zoomLevel = $MapZoom
            $changes += "Map Zoom: $MapZoom"
        }
        
        $freeboard | ConvertTo-Json -Depth 20 | Set-Content $freeboardFile
        Write-Host "Map settings updated." -ForegroundColor Green
    }
}

if ($changes.Count -gt 0) {
    Write-Host ""
    Write-Host "=== Configuration Changes Applied ===" -ForegroundColor Green
    foreach ($change in $changes) {
        Write-Host "  ✓ $change" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "Restart GPS Kiosk to apply changes:" -ForegroundColor Yellow
    Write-Host "  docker compose restart" -ForegroundColor Gray
    Write-Host "  Or run: .\quick-setup.ps1" -ForegroundColor Gray
} else {
    Write-Host "No changes specified. Use -ShowCurrent to see current settings." -ForegroundColor Yellow
}