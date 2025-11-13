# Docker Desktop Detection Script for Intune
try {
    # Check if Docker Desktop is installed
    $dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    if (Test-Path $dockerPath) {
        # Also verify it's a valid installation by checking the docker binary
        $dockerBinary = "C:\Program Files\Docker\Docker\resources\bin\docker.exe"
        if (Test-Path $dockerBinary) {
            try {
                # Try to get version to ensure it's functional
                $version = & $dockerBinary --version 2>$null
                if ($version -and $version -match "Docker version") {
                    Write-Output "Docker Desktop is installed and functional"
                    exit 0
                }
            }
            catch {
                # Binary exists but not functional
                exit 1
            }
        }
    }
    
    # Check registry for installation
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Docker Desktop"
    if (Test-Path $regPath) {
        Write-Output "Docker Desktop found in registry"
        exit 0
    }
    
    # If we get here, Docker is not properly installed
    exit 1
}
catch {
    exit 1
}