# GPS Kiosk Diagnostic Script for Remote Deployment Issues
# This script checks why kiosk browser and startup components aren't working

Write-Host "=== GPS Kiosk Deployment Diagnostics ===" -ForegroundColor Green
Write-Host ""

# Check if quick-setup.ps1 ran to completion
Write-Host "1. Checking setup completion status..." -ForegroundColor Yellow
$installPath = "C:\gps-kiosk"
$startupScript = "$installPath\start-gps-kiosk.bat"
$shortcutPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\GPS Kiosk.lnk"

if (Test-Path $startupScript) {
    Write-Host "   ✅ Startup script exists: $startupScript" -ForegroundColor Green
} else {
    Write-Host "   ❌ Startup script missing: $startupScript" -ForegroundColor Red
    Write-Host "      This indicates quick-setup.ps1 didn't complete successfully" -ForegroundColor Yellow
}

if (Test-Path $shortcutPath) {
    Write-Host "   ✅ Windows startup shortcut exists" -ForegroundColor Green
} else {
    Write-Host "   ❌ Windows startup shortcut missing" -ForegroundColor Red
}

# Check registry startup entry
Write-Host ""
Write-Host "2. Checking Windows startup registry..." -ForegroundColor Yellow
try {
    $startupRegistry = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    $gpsEntry = Get-ItemProperty -Path $startupRegistry -Name "GPS-Kiosk" -ErrorAction SilentlyContinue
    if ($gpsEntry) {
        Write-Host "   ✅ Registry startup entry exists" -ForegroundColor Green
        Write-Host "      Path: $($gpsEntry.'GPS-Kiosk')" -ForegroundColor White
    } else {
        Write-Host "   ❌ Registry startup entry missing" -ForegroundColor Red
    }
} catch {
    Write-Host "   ⚠️  Cannot check registry (may need Administrator)" -ForegroundColor Yellow
}

# Check Docker containers
Write-Host ""
Write-Host "3. Checking Docker containers..." -ForegroundColor Yellow
try {
    $containerStatus = docker ps --filter "name=gps-kiosk" --format "{{.Status}}" 2>$null
    if ($containerStatus) {
        Write-Host "   ✅ GPS Kiosk container: $containerStatus" -ForegroundColor Green
    } else {
        Write-Host "   ❌ GPS Kiosk container not running" -ForegroundColor Red
        $allContainers = docker ps -a --filter "name=gps-kiosk" --format "{{.Status}}" 2>$null
        if ($allContainers) {
            Write-Host "      Container exists but stopped: $allContainers" -ForegroundColor Yellow
        } else {
            Write-Host "      Container doesn't exist - setup may have failed" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "   ❌ Docker not available or not running" -ForegroundColor Red
}

# Check web interface accessibility
Write-Host ""
Write-Host "4. Checking GPS Kiosk web interface..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/signalk/" -TimeoutSec 5 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "   ✅ Web interface accessible (HTTP $($response.StatusCode))" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Web interface responded with HTTP $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ❌ Web interface not accessible" -ForegroundColor Red
    Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Gray
}

# Check Microsoft Edge availability
Write-Host ""
Write-Host "5. Checking Microsoft Edge..." -ForegroundColor Yellow
$edgePaths = @(
    "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    "C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
)

$edgeFound = $false
foreach ($edgePath in $edgePaths) {
    if (Test-Path $edgePath) {
        Write-Host "   ✅ Microsoft Edge found: $edgePath" -ForegroundColor Green
        $edgeFound = $true
        break
    }
}

if (-not $edgeFound) {
    Write-Host "   ❌ Microsoft Edge not found in standard locations" -ForegroundColor Red
    Write-Host "      Browser launch will fail" -ForegroundColor Yellow
}

# Check auto-login configuration
Write-Host ""
Write-Host "6. Checking auto-login configuration..." -ForegroundColor Yellow
try {
    $winlogon = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -ErrorAction SilentlyContinue
    if ($winlogon.AutoAdminLogon -eq "1") {
        Write-Host "   ✅ Auto-login enabled for: $($winlogon.DefaultUserName)" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Auto-login not configured (manual login required)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ⚠️  Cannot check auto-login (may need Administrator)" -ForegroundColor Yellow
}

# Check execution policy
Write-Host ""
Write-Host "7. Checking PowerShell execution policy..." -ForegroundColor Yellow
$policy = Get-ExecutionPolicy -Scope CurrentUser
if ($policy -eq "RemoteSigned" -or $policy -eq "Unrestricted") {
    Write-Host "   ✅ Execution policy: $policy (OK)" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Execution policy: $policy (may block scripts)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Green

if (Test-Path $startupScript) {
    Write-Host "✅ Setup appears to have completed - startup components created" -ForegroundColor Green
    
    if ($containerStatus -like "*Up*") {
        Write-Host "✅ System is ready - try manual browser launch:" -ForegroundColor Green
        Write-Host '   Start-Process "msedge.exe" "--kiosk http://localhost:3000/@signalk/freeboard-sk/?zoom=12&northup=1&movemap=1&kiosk=1 --edge-kiosk-type=fullscreen --no-first-run --user-data-dir=C:\KioskBrowser"' -ForegroundColor Cyan
    } else {
        Write-Host "⚠️  Containers not running - try:" -ForegroundColor Yellow
        Write-Host "   docker compose up -d" -ForegroundColor Cyan
    }
} else {
    Write-Host "❌ Setup incomplete - startup components missing" -ForegroundColor Red
    Write-Host "   Try running setup again:" -ForegroundColor Yellow
    Write-Host "   .\quick-setup.ps1" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "For detailed logs, check:" -ForegroundColor White
Write-Host "   docker logs gps-kiosk" -ForegroundColor Gray
Write-Host "   Get-EventLog -LogName Application -Source 'GPS Kiosk' -Newest 10" -ForegroundColor Gray