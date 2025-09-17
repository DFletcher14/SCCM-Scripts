$logFilePath = "C:\Windows\fndr\logs"
$logFileName = "$logFilePath\Redist-PackageToDP.log"

# Function to write our logs
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "FNDR: $timestamp - $Message"
    

    if (-not (Test-Path $logFilePath)) {
        New-Item -Path $logFilePath -ItemType Directory -Force | Out-Null
    }

    if (Test-Path $logFileName) {
        $cutoff = (Get-Date).AddDays(-90)
        $filteredLines = Get-Content $logFileName | Where-Object {
            if ($_ -match '^FNDR: (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})') {
                [datetime]$logTime = $matches[1]
                return $logTime -ge $cutoff
            } else {
                return $true
            }
        }
        $filteredLines | Set-Content -Path $logFileName
    }

    Add-Content -Path $logFileName -Value $logMessage
    
}

Write-Log "Starting Redist-PackageToDP Script"

$DPName = Read-Host "Enter Distribution Point FQDN"
$PkgID = Get-Content (Join-Path $env:TEMP "PackageIDs.txt") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }


foreach($package in $PkgID){
    Write-Log "Attempting to remove packages from $DPName"
    try{
        Remove-CMContentDistribution -ApplicationID $package -DistributionPointName $DPName -Force
        Write-Log "Successfully removed $package from $DPName"
        Write-Host "Successfully removed $package from $DPName" -ForegroundColor Green
    }catch{
        Write-Log "Failed to remove $package from $DPName. Error: $_"
        Write-Host "Failed to remove $package from $DPName. Error: $_" -ForegroundColor Red
    }

    Start-Sleep 20
    
    Write-Log "Attempting to add packages to $DPName"
    try{
        Start-CMContentDistribution -ApplicationID $package -DistributionPointName $DPName -Force
        Write-Log "Successfully added $package to $DPName"
        Write-Host "Successfully added $package to $DPName"-ForegroundColor Green
    }catch{
        Write-Log "Failed to add $package to $DPName. Error: $_"
        Write-Host "Failed to add $package to $DPName. Error: $_" -ForegroundColor Red
    }
    
    Start-Sleep 20

}
