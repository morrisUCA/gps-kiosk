# Docker Diagnostic Script for GPS Kiosk
# Run this script to diagnose Docker Desktop issues

param(
    [switch]$Fix
)

Write-Host "=== GPS Kiosk Docker Diagnostic ===" -ForegroundColor Green
Write-Host ""

$dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
$issues = @()

# Check 1: Docker Desktop Installation
Write-Host "1. Checking Docker Desktop installation..." -ForegroundColor Yellow
if (Test-Path $dockerPath) {
    Write-Host "   [OK] Docker Desktop is installed" -ForegroundColor Green
} else {
    Write-Host "   [ERROR] Docker Desktop not found" -ForegroundColor Red
    $issues += "Docker Desktop is not installed"
}

# Check 2: Docker Desktop Process
Write-Host "2. Checking Docker Desktop process..." -ForegroundColor Yellow
$dockerProcess = Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue
if ($dockerProcess) {
    Write-Host "   [OK] Docker Desktop process is running" -ForegroundColor Green
} else {
    Write-Host "   [ERROR] Docker Desktop process not found" -ForegroundColor Red
    $issues += "Docker Desktop is not running"
    
    if ($Fix -and (Test-Path $dockerPath)) {
        Write-Host "   [FIX] Starting Docker Desktop..." -ForegroundColor Cyan
        Start-Process $dockerPath
        Start-Sleep -Seconds 10
    }
}

# Check 3: Docker Daemon
Write-Host "3. Checking Docker daemon..." -ForegroundColor Yellow
try {
    $version = docker version --format "{{.Server.Version}}" 2>$null
    if ($version) {
        Write-Host "   ✅ Docker daemon is responding (version: $version)" -ForegroundColor Green
    } else {
        throw "No version returned"
    }
} catch {
    Write-Host "   ❌ Docker daemon is not responding" -ForegroundColor Red
    $issues += "Docker daemon is not accessible"
}

# Check 4: Docker Compose
Write-Host "4. Checking Docker Compose..." -ForegroundColor Yellow
try {
    $composeVersion = docker compose version --short 2>$null
    if ($composeVersion) {
        Write-Host "   ✅ Docker Compose is available (version: $composeVersion)" -ForegroundColor Green
    } else {
        throw "No compose version"
    }
} catch {
    Write-Host "   ❌ Docker Compose is not available" -ForegroundColor Red
    $issues += "Docker Compose is not working"
}

# Check 5: Windows Features (Hyper-V, Containers)
Write-Host "5. Checking Windows features..." -ForegroundColor Yellow
try {
    $hyperV = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -ErrorAction SilentlyContinue
    $containers = Get-WindowsOptionalFeature -Online -FeatureName Containers -ErrorAction SilentlyContinue
    
    if ($hyperV.State -eq "Enabled") {
        Write-Host "   ✅ Hyper-V is enabled" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Hyper-V is not enabled" -ForegroundColor Yellow
        $issues += "Hyper-V feature may need to be enabled"
    }
    
    if ($containers.State -eq "Enabled") {
        Write-Host "   ✅ Containers feature is enabled" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Containers feature is not enabled" -ForegroundColor Yellow
        $issues += "Containers feature may need to be enabled"
    }
} catch {
    Write-Host "   ⚠️  Could not check Windows features" -ForegroundColor Yellow
}

# Check 6: User Permissions
Write-Host "6. Checking user permissions..." -ForegroundColor Yellow
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    Write-Host "   ✅ Running as Administrator" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Not running as Administrator" -ForegroundColor Yellow
    Write-Host "   💡 Some Docker operations may require admin privileges" -ForegroundColor Cyan
}

# Summary
Write-Host ""
Write-Host "=== DIAGNOSTIC SUMMARY ===" -ForegroundColor Green
if ($issues.Count -eq 0) {
    Write-Host "✅ All checks passed! Docker should be working properly." -ForegroundColor Green
    Write-Host ""
    Write-Host "If you're still having issues, try:" -ForegroundColor Yellow
    Write-Host "• Restart Docker Desktop" -ForegroundColor White
    Write-Host "• Restart your computer" -ForegroundColor White
    Write-Host "• Check Docker Desktop settings" -ForegroundColor White
} else {
    Write-Host "❌ Found $($issues.Count) issue(s):" -ForegroundColor Red
    foreach ($issue in $issues) {
        Write-Host "   • $issue" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "=== RECOMMENDED FIXES ===" -ForegroundColor Yellow
    
    if ($issues -contains "Docker Desktop is not installed") {
        Write-Host "📥 Install Docker Desktop:" -ForegroundColor Cyan
        Write-Host "   Download from: https://www.docker.com/products/docker-desktop/" -ForegroundColor White
    }
    
    if ($issues -contains "Docker Desktop is not running") {
        Write-Host "🚀 Start Docker Desktop:" -ForegroundColor Cyan
        Write-Host "   • Double-click Docker Desktop icon" -ForegroundColor White
        Write-Host "   • Or run: Start-Process '$dockerPath'" -ForegroundColor White
        Write-Host "   • Or run this script with -Fix parameter" -ForegroundColor White
    }
    
    if ($issues -contains "Docker daemon is not accessible") {
        Write-Host "🔧 Fix Docker Daemon:" -ForegroundColor Cyan
        Write-Host "   • Wait for Docker Desktop to fully start (whale icon in system tray)" -ForegroundColor White
        Write-Host "   • Try restarting Docker Desktop" -ForegroundColor White
        Write-Host "   • Check Windows Event Logs for Docker errors" -ForegroundColor White
    }
    
    if ($issues -like "*Hyper-V*" -or $issues -like "*Containers*") {
        Write-Host "🏗️  Enable Windows Features:" -ForegroundColor Cyan
        Write-Host "   Run as Administrator:" -ForegroundColor White
        Write-Host "   Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All" -ForegroundColor Gray
        Write-Host "   Enable-WindowsOptionalFeature -Online -FeatureName Containers -All" -ForegroundColor Gray
        Write-Host "   Then restart your computer" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "💡 Run with -Fix parameter to attempt automatic fixes" -ForegroundColor Cyan
Write-Host "   Example: .\docker-diagnostic.ps1 -Fix" -ForegroundColor Gray