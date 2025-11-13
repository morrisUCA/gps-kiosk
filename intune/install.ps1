# install.ps1

$ErrorActionPreference = "Stop"

# Variables
$repoURL = "https://github.com/Uncruise/gps-kiosk.git"
$repoPath = "C:\gps-kiosk"
$browserURL = "http://localhost:3000/@signalk/freeboard-sk/?zoom=12&northup=1&movemap=1&kiosk=1"

# Check if Docker Desktop is installed, install if needed
$dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
if (-not (Test-Path $dockerPath)) {
    Write-Host "Docker Desktop not found. Installing..."
    
    try {
        # Try multiple installation methods
        $installSuccess = $false
        
        # Method 1: Try winget from default source (not MS Store)
        Write-Host "Attempting installation via winget..."
        try {
            $result = winget install Docker.DockerDesktop --accept-package-agreements --accept-source-agreements --silent
            if ($LASTEXITCODE -eq 0) {
                $installSuccess = $true
                Write-Host "Docker Desktop installed via winget."
            }
        } catch {
            Write-Host "Winget installation failed: $($_.Exception.Message)"
        }
        
        # Method 2: Direct download and install if winget failed
        if (-not $installSuccess) {
            Write-Host "Downloading Docker Desktop directly..."
            $dockerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
            $dockerInstaller = "$env:TEMP\DockerDesktopInstaller.exe"
            
            Invoke-WebRequest -Uri $dockerUrl -OutFile $dockerInstaller -UseBasicParsing
            
            Write-Host "Installing Docker Desktop..."
            $process = Start-Process -FilePath $dockerInstaller -ArgumentList "install --quiet --accept-license" -Wait -PassThru
            
            if ($process.ExitCode -eq 0) {
                $installSuccess = $true
                Write-Host "Docker Desktop installed via direct download."
            }
            
            # Clean up installer
            Remove-Item $dockerInstaller -Force -ErrorAction SilentlyContinue
        }
        
        if (-not $installSuccess) {
            Write-Host "All Docker installation methods failed. Exiting."
            exit 1
        }
        
        # Wait for installation to complete
        Write-Host "Waiting for Docker Desktop installation to complete..."
        $installTimeout = 300 # 5 minutes
        $installElapsed = 0
        
        do {
            Start-Sleep -Seconds 10
            $installElapsed += 10
            if (Test-Path $dockerPath) {
                Write-Host "Docker Desktop installation completed."
                break
            }
        } while ($installElapsed -lt $installTimeout)
        
        if (-not (Test-Path $dockerPath)) {
            Write-Host "Docker Desktop installation failed or timed out. Exiting."
            exit 1
        }
    } catch {
        Write-Host "Failed to install Docker Desktop: $($_.Exception.Message)"
        exit 1
    }
}

# Start Docker Desktop if not running
$dockerProcess = Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue
if (-not $dockerProcess) {
    Write-Host "Starting Docker Desktop..."
    Start-Process $dockerPath -ErrorAction SilentlyContinue
    
    # Wait for Docker to be ready
    $timeout = 180 # 3 minutes timeout (longer for first-time setup)
    $elapsed = 0
    do {
        Start-Sleep -Seconds 5
        $elapsed += 5
        try {
            docker version | Out-Null
            $dockerReady = $true
            break
        } catch {
            $dockerReady = $false
        }
    } while ($elapsed -lt $timeout -and -not $dockerReady)
    
    if (-not $dockerReady) {
        Write-Host "Docker failed to start within timeout. Exiting."
        exit 1
    }
    
    Write-Host "Docker Desktop is ready."
} else {
    Write-Host "Docker Desktop is already running."
}

# -------------------------------
# Install Git if it's missing
# -------------------------------
if (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) {
    Write-Host "Git not found. Installing..."

    $gitInstaller = "$env:TEMP\git-installer.exe"
    Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.45.1.windows.1/Git-2.45.1-64-bit.exe" -OutFile $gitInstaller

    Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT /NORESTART" -Wait

    if (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) {
        Write-Host "Git install failed."
        exit 1
    }

    Write-Host "Git installed successfully."
}

# Clone or pull latest code
if (Test-Path $repoPath) {
    cd $repoPath
    git reset --hard
    git pull
} else {
    git clone $repoURL $repoPath
    cd $repoPath
}

# Docker compose up
Write-Host "Stopping existing containers..."
docker compose down

Write-Host "Pulling latest images..."
docker compose pull

Write-Host "Starting containers..."
docker compose up -d

# Wait for the application to be ready
Write-Host "Waiting for application to start..."
$maxAttempts = 30
$attempt = 0
$appReady = $false

do {
    Start-Sleep -Seconds 2
    $attempt++
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000/@signalk/freeboard-sk/" -TimeoutSec 5 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            $appReady = $true
            Write-Host "Application is ready!"
            break
        }
    } catch {
        # Application not ready yet, continue waiting
    }
} while ($attempt -lt $maxAttempts)

if (-not $appReady) {
    Write-Host "Warning: Application may not be fully ready, but proceeding to launch browser..."
}

# Open in Edge kiosk mode
Write-Host "Launching browser in kiosk mode..."
Start-Process "msedge.exe" "--kiosk $browserURL --edge-kiosk-type=fullscreen --no-first-run --user-data-dir=C:\KioskBrowser"
