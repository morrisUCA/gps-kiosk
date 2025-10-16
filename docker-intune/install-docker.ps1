# Docker Desktop Installation Script for Intune
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Add logging for troubleshooting
Start-Transcript -Path "C:\temp\docker-install.log" -Append

try {
    Write-Host "Starting Docker Desktop installation..."
    
    # Make sure the installer exists
    $installerPath = Join-Path $PSScriptRoot "Docker Desktop Installer.exe"
    if (-not (Test-Path $installerPath)) {
        throw "Docker Desktop Installer.exe not found at: $installerPath"
    }
    
    Write-Host "Found installer at: $installerPath"
    
    # Check if Docker is already installed
    $dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    if (Test-Path $dockerPath) {
        Write-Host "Docker Desktop is already installed, checking version..."
        try {
            $version = & "C:\Program Files\Docker\Docker\resources\bin\docker.exe" --version 2>$null
            if ($version) {
                Write-Host "Docker is already installed and functional: $version"
                exit 0
            }
        }
        catch {
            Write-Host "Docker installation appears corrupted, proceeding with reinstall..."
        }
    }
    
    # Install with proper arguments
    Write-Host "Running Docker Desktop installer..."
    $process = Start-Process -FilePath $installerPath -ArgumentList "install --quiet --accept-license" -Wait -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Host "Docker Desktop installed successfully"
        
        # Verify installation
        Start-Sleep -Seconds 10
        if (Test-Path $dockerPath) {
            Write-Host "Installation verified successfully"
            exit 0
        }
        else {
            throw "Installation completed but Docker Desktop.exe not found"
        }
    }
    else {
        throw "Installation failed with exit code: $($process.ExitCode)"
    }
    
}
catch {
    Write-Error "Installation failed: $_"
    exit 1
}
finally {
    Stop-Transcript
}