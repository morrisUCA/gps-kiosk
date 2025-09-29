# Docker Desktop Installation Script for Intune
$ErrorActionPreference = "Stop"

Write-Host "Starting Docker Desktop installation..."

# Variables
$dockerInstaller = "$PSScriptRoot\Docker Desktop Installer.exe"
$installArgs = @(
    "install",
    "--quiet",
    "--accept-license",
    "--always-run-service"
)

try {
    # Check if Docker Desktop is already installed
    $dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    if (Test-Path $dockerPath) {
        Write-Host "Docker Desktop is already installed. Checking if it's running..."
        
        # Start Docker Desktop if not running
        $dockerProcess = Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue
        if (-not $dockerProcess) {
            Write-Host "Starting Docker Desktop..."
            Start-Process $dockerPath -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 30
        }
        
        Write-Host "Docker Desktop installation verified."
        exit 0
    }

    # Check if installer exists
    if (-not (Test-Path $dockerInstaller)) {
        Write-Host "Error: Docker Desktop installer not found at: $dockerInstaller"
        Write-Host "Please ensure 'Docker Desktop Installer.exe' is in the same folder as this script."
        exit 1
    }

    # Install Docker Desktop
    Write-Host "Running Docker Desktop installer..."
    $process = Start-Process -FilePath $dockerInstaller -ArgumentList $installArgs -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -eq 0) {
        Write-Host "Docker Desktop installed successfully."
        
        # Wait a moment for installation to complete
        Start-Sleep -Seconds 10
        
        # Try to start Docker Desktop
        if (Test-Path $dockerPath) {
            Write-Host "Starting Docker Desktop..."
            Start-Process $dockerPath -ErrorAction SilentlyContinue
        }
        
        Write-Host "Docker Desktop installation completed."
        exit 0
    }
    else {
        Write-Host "Docker Desktop installation failed with exit code: $($process.ExitCode)"
        exit 1
    }

}
catch {
    Write-Host "Error during Docker Desktop installation: $($_.Exception.Message)"
    exit 1
}