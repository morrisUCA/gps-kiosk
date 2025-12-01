# GPS Kiosk Update Verification Script
# Run this on each machine after updating to verify auto-update functionality

Write-Host "=== GPS Kiosk Update Verification ===" -ForegroundColor Green

# Check if Docker container is running
$containerStatus = docker ps --filter "name=gps-kiosk" --format "{{.Status}}" 2>$null
if ($containerStatus -like "*Up*") {
    Write-Host "✅ Container Status: $containerStatus" -ForegroundColor Green
} else {
    Write-Host "❌ Container not running: $containerStatus" -ForegroundColor Red
}

# Check if auto-update startup script exists
$startupScript = "C:\gps-kiosk\start-gps-kiosk.bat"
if (Test-Path $startupScript) {
    Write-Host "✅ Startup script exists: $startupScript" -ForegroundColor Green
} else {
    Write-Host "❌ Startup script missing: $startupScript" -ForegroundColor Red
}

# Check if startup script has auto-update functionality
$scriptContent = Get-Content $startupScript -Raw -ErrorAction SilentlyContinue
if ($scriptContent -like "*docker compose pull*") {
    Write-Host "✅ Startup script includes auto-update (docker compose pull)" -ForegroundColor Green
} else {
    Write-Host "❌ Startup script missing auto-update functionality" -ForegroundColor Red
}

# Check web interface
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/signalk/" -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Web interface accessible (HTTP $($response.StatusCode))" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Web interface responded with HTTP $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Web interface not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

# Test auto-update by checking if Git is available in container
try {
    $gitTest = docker exec gps-kiosk git --version 2>$null
    if ($gitTest) {
        Write-Host "✅ Git available in container for auto-updates: $gitTest" -ForegroundColor Green
    } else {
        Write-Host "❌ Git not available in container - auto-update won't work" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Cannot test Git in container: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Update Verification Complete ===" -ForegroundColor Green
Write-Host "If all items show ✅, the machine is ready for auto-updates!" -ForegroundColor White