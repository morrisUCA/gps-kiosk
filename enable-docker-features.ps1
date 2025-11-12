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

Write-Host "Running as Administrator - OK" -ForegroundColor Green
Write-Host ""

# Check current feature status
Write-Host "Checking current Windows feature status..." -ForegroundColor Yellow

try {
    $wsl = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -ErrorAction Stop
    $vmPlatform = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -ErrorAction Stop
    $containers = Get-WindowsOptionalFeature -Online -FeatureName Containers -ErrorAction Stop
    
    Write-Host "WSL Status: $($wsl.State)" -ForegroundColor $(if ($wsl.State -eq "Enabled") { "Green" } else { "Red" })
    Write-Host "Virtual Machine Platform Status: $($vmPlatform.State)" -ForegroundColor $(if ($vmPlatform.State -eq "Enabled") { "Green" } else { "Red" })
    Write-Host "Containers Status: $($containers.State)" -ForegroundColor $(if ($containers.State -eq "Enabled") { "Green" } else { "Red" })
    Write-Host ""
    
    $needsWSL = $wsl.State -ne "Enabled"
    $needsVMPlatform = $vmPlatform.State -ne "Enabled"
    $needsContainers = $containers.State -ne "Enabled"
    
    if (-not $needsWSL -and -not $needsVMPlatform) {
        Write-Host "SUCCESS: All required features are already enabled!" -ForegroundColor Green
        Write-Host "Your Docker Desktop with WSL 2 should work properly now." -ForegroundColor Green
        exit 0
    }
    
    Write-Host "The following features need to be enabled for Docker Desktop WSL 2:" -ForegroundColor Yellow
    if ($needsWSL) { Write-Host "  - Windows Subsystem for Linux (WSL)" -ForegroundColor White }
    if ($needsVMPlatform) { Write-Host "  - Virtual Machine Platform" -ForegroundColor White }
    if ($needsContainers) { Write-Host "  - Containers (optional for Windows containers)" -ForegroundColor White }
    Write-Host ""
    Write-Host "WARNING: A computer restart will be required after enabling these features." -ForegroundColor Red
    Write-Host ""
    
    if (-not $Force) {
        $response = Read-Host "Do you want to continue? (y/N)"
        if ($response -notlike "y*") {
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            exit 0
        }
    }
    
    Write-Host ""
    Write-Host "Enabling Windows features..." -ForegroundColor Yellow
    
    $restartRequired = $false
    
    # Enable WSL and Virtual Machine Platform for Docker Desktop WSL 2 backend
    Write-Host "Enabling WSL (Windows Subsystem for Linux)..." -ForegroundColor Cyan
    $result = Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
    if ($result.RestartNeeded) {
        $restartRequired = $true
    }
    Write-Host "WSL enabled successfully" -ForegroundColor Green
    
    Write-Host "Enabling Virtual Machine Platform..." -ForegroundColor Cyan
    $result = Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
    if ($result.RestartNeeded) {
        $restartRequired = $true
    }
    Write-Host "Virtual Machine Platform enabled successfully" -ForegroundColor Green
    
    # Also enable Containers feature for Windows containers support (optional)
    if ($needsContainers) {
        Write-Host "Enabling Containers feature..." -ForegroundColor Cyan
        $result = Enable-WindowsOptionalFeature -Online -FeatureName Containers -All -NoRestart
        if ($result.RestartNeeded) {
            $restartRequired = $true
        }
        Write-Host "Containers feature enabled successfully" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "=== SUCCESS ===" -ForegroundColor Green
    Write-Host "Windows features have been enabled successfully!" -ForegroundColor Green
    Write-Host ""
    
    if ($restartRequired) {
        Write-Host "IMPORTANT: A restart is required for the changes to take effect." -ForegroundColor Red
        Write-Host ""
        Write-Host "After restart:" -ForegroundColor Yellow
        Write-Host "1. Docker Desktop should work with WSL 2 backend" -ForegroundColor White
        Write-Host "2. Run your GPS Kiosk setup: .\quick-setup.ps1" -ForegroundColor White
        Write-Host "3. Docker Desktop will automatically use WSL 2 backend" -ForegroundColor White
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
    Write-Host ""
    Write-Host "Manual commands to try:" -ForegroundColor Yellow
    Write-Host "Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux" -ForegroundColor Gray
    Write-Host "Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform" -ForegroundColor Gray
    Write-Host "Enable-WindowsOptionalFeature -Online -FeatureName Containers -All" -ForegroundColor Gray
    exit 1
}