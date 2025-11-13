# Test GPS Kiosk restart functionality without rebooting
Write-Host "=== Testing GPS Kiosk Restart Sequence ===" -ForegroundColor Green

# Simulate restart by stopping everything
Write-Host "1. Stopping GPS Kiosk containers..." -ForegroundColor Yellow
docker compose down

# Stop Docker Desktop (optional - comment out if you don't want to test this)
# Write-Host "2. Stopping Docker Desktop..." -ForegroundColor Yellow
# Stop-Process -Name "Docker Desktop" -Force -ErrorAction SilentlyContinue

Write-Host "3. Running startup script to simulate boot..." -ForegroundColor Yellow
if (Test-Path "C:\gps-kiosk\start-gps-kiosk.bat") {
    Start-Process -FilePath "C:\gps-kiosk\start-gps-kiosk.bat" -Wait
    Write-Host "✅ Startup script completed" -ForegroundColor Green
} else {
    Write-Host "❌ Startup script not found - run quick-setup.ps1 first" -ForegroundColor Red
}

Write-Host ""
Write-Host "Test complete. Check that:" -ForegroundColor Cyan
Write-Host "- Docker containers are running: docker ps" -ForegroundColor White
Write-Host "- Web interface works: http://localhost:3000" -ForegroundColor White
Write-Host "- Browser launched in kiosk mode" -ForegroundColor White