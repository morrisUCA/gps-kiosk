# Enable Windows Features for Docker
# This script enables the required Windows features for Docker Desktop to work properly

param(
    [switch]$Force
)

Write-Host "=== Enable Docker Windows Features ===" -ForegroundColor Green
Write-Host ""

# Check if running as Administrator
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

Write-Host "Running as Administrator ✓" -ForegroundColor Green
Write-Host ""

# Check current feature status
Write-Host "Checking current Windows feature status..." -ForegroundColor Yellow

try {
    $hyperV = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -ErrorAction Stop
    $containers = Get-WindowsOptionalFeature -Online -FeatureName Containers -ErrorAction Stop
    
    Write-Host "Hyper-V Status: $($hyperV.State)" -ForegroundColor $(if ($hyperV.State -eq "Enabled") { "Green" } else { "Red" })
    Write-Host "Containers Status: $($containers.State)" -ForegroundColor $(if ($containers.State -eq "Enabled") { "Green" } else { "Red" })
    Write-Host ""
    
    $needsHyperV = $hyperV.State -ne "Enabled"
    $needsContainers = $containers.State -ne "Enabled"
    
    if (-not $needsHyperV -and -not $needsContainers) {
        Write-Host "✓ All required features are already enabled!" -ForegroundColor Green
        Write-Host "Your Docker should work properly now." -ForegroundColor Green
        exit 0
    }
    
    if (-not $Force) {
        Write-Host "The following features need to be enabled:" -ForegroundColor Yellow
        if ($needsHyperV) { Write-Host "  - Hyper-V Platform" -ForegroundColor White }
        if ($needsContainers) { Write-Host "  - Containers" -ForegroundColor White }
        Write-Host ""
        Write-Host "WARNING: A computer restart will be required after enabling these features." -ForegroundColor Red
        Write-Host ""
        $response = Read-Host "Do you want to continue? (y/N)"
        if ($response -notlike "y*") {
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            exit 0
        }
    }
    
    Write-Host ""
    Write-Host "Enabling Windows features..." -ForegroundColor Yellow
    
    $restartRequired = $false
    
    if ($needsHyperV) {
        Write-Host "Enabling Hyper-V..." -ForegroundColor Cyan
        try {
            $result = Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
            if ($result.RestartNeeded) {
                $restartRequired = $true
            }
            Write-Host "✓ Hyper-V enabled successfully" -ForegroundColor Green
        } catch {
            Write-Host "✗ Failed to enable Hyper-V: $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
    }
    
    if ($needsContainers) {
        Write-Host "Enabling Containers..." -ForegroundColor Cyan
        try {
            $result = Enable-WindowsOptionalFeature -Online -FeatureName Containers -All -NoRestart
            if ($result.RestartNeeded) {
                $restartRequired = $true
            }
            Write-Host "✓ Containers enabled successfully" -ForegroundColor Green
        } catch {
            Write-Host "✗ Failed to enable Containers: $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
    }
    
    Write-Host ""
    Write-Host "=== SUCCESS ===" -ForegroundColor Green
    Write-Host "Windows features have been enabled successfully!" -ForegroundColor Green
    Write-Host ""
    
    if ($restartRequired) {
        Write-Host "IMPORTANT: A restart is required for the changes to take effect." -ForegroundColor Red
        Write-Host ""
        Write-Host "After restart:" -ForegroundColor Yellow
        Write-Host "1. Docker Desktop should work properly" -ForegroundColor White
        Write-Host "2. Run your GPS Kiosk setup: .\quick-setup.ps1" -ForegroundColor White
        Write-Host ""
        $restartNow = Read-Host "Do you want to restart now? (y/N)"
        if ($restartNow -like "y*") {
            Write-Host "Restarting computer..." -ForegroundColor Yellow
            Restart-Computer -Force
        } else {
            Write-Host "Remember to restart your computer before using Docker!" -ForegroundColor Yellow
        }
    } else {
        Write-Host "No restart required. Docker should work now!" -ForegroundColor Green
    }
    
} catch {
    Write-Host "ERROR: Failed to check Windows features: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "This might be a permission issue or unsupported Windows version." -ForegroundColor Yellow
    exit 1
}