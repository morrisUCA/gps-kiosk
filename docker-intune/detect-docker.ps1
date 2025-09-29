# Docker Desktop Detection Script for Intune
try {
    # Check if Docker Desktop executable exists
    $dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    if (-not (Test-Path $dockerPath)) {
        exit 1
    }
    
    # Check if Docker CLI is available and working
    try {
        $dockerVersion = docker --version 2>$null
        if ($dockerVersion -and $dockerVersion -like "*Docker version*") {
            Write-Output "Docker Desktop is installed: $dockerVersion"
            exit 0
        }
        else {
            exit 1
        }
    }
    catch {
        exit 1
    }
}
catch {
    exit 1
}