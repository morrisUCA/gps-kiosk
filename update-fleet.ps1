# GPS Kiosk Fleet Update Script
# Run this from your management machine to update multiple GPS Kiosk deployments

param(
    [string[]]$ComputerNames = @("GPS-KIOSK-01", "GPS-KIOSK-02"),  # Add your machine names
    [pscredential]$Credential = (Get-Credential -Message "Enter credentials for remote machines")
)

Write-Host "=== GPS Kiosk Fleet Update ===" -ForegroundColor Green
Write-Host "Updating $($ComputerNames.Count) machines with auto-update functionality..." -ForegroundColor Yellow

foreach ($computer in $ComputerNames) {
    Write-Host ""
    Write-Host "Updating $computer..." -ForegroundColor Cyan
    
    try {
        $session = New-PSSession -ComputerName $computer -Credential $Credential -ErrorAction Stop
        
        $result = Invoke-Command -Session $session -ScriptBlock {
            # Navigate to GPS Kiosk directory
            Set-Location C:\gps-kiosk
            
            # Pull latest repository updates
            git pull origin main
            
            # Stop containers
            $stopOutput = docker compose down 2>&1
            
            # Pull latest Docker image
            $pullOutput = docker compose pull 2>&1
            
            # Start with new image
            $startOutput = docker compose up -d --force-recreate 2>&1
            
            # Wait and check status
            Start-Sleep 10
            $status = docker ps --filter "name=gps-kiosk" --format "{{.Status}}" 2>$null
            
            return @{
                Computer = $env:COMPUTERNAME
                GitPull = $gitOutput -join " "
                DockerStop = $stopOutput -join " "
                DockerPull = $pullOutput -join " "
                DockerStart = $startOutput -join " "
                Status = $status
                Success = $status -like "*Up*"
            }
        }
        
        Remove-PSSession $session
        
        if ($result.Success) {
            Write-Host "  ✅ $computer updated successfully: $($result.Status)" -ForegroundColor Green
        } else {
            Write-Host "  ❌ $computer update failed" -ForegroundColor Red
            Write-Host "     Status: $($result.Status)" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "  ❌ Failed to connect to $computer" -ForegroundColor Red
        Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Fleet update complete!" -ForegroundColor Green
Write-Host "All machines will now auto-update Volume contents from GitHub on restart." -ForegroundColor White