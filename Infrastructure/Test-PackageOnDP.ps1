
$logFilePath = "C:\Windows\fndr\logs"
$logFileName = "$logFilePath\Check-PackageDistributionStatus.log"

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

Write-Log "Starting Check-PackageDistributionStatus.Log"
Write-Host "Please ensure you have the necessary input file created in $env:TEMP" -ForegroundColor Yellow

# Get Distribution Point Name via user input | Get input path for PackageIDs
$DPName = Read-Host "Enter Distribution Point FQDN"
$PkgID = Get-Content (Join-Path $env:TEMP "PackageIDs.txt") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

$creds = Get-Credential


foreach($package in $PkgID){

    $wmiObj = Get-WmiObject -ComputerName $DPName -Namespace Root\SCCMDP -Class SMS_PackagesInContLib -Filter "PackageID = '$package'" 
    
    if($wmiObj){
        try{
            # Check WMI for packageIDs
            Write-Log "$package found in WMI on $DPName"
            Write-Host "$package found in WMI on $DPName" -ForegroundColor Green
        }catch{
        Write-Log "$package could not be found from WMI on $DPName."
        Write-Host "$package could not be found from WMI on $DPName." -ForegroundColor Red
        }
    }

    # Set Content Lib Variables
    $ContentLib = Invoke-Command -ComputerName $DPName -Credential $creds -ScriptBlock  {(Get-ItemProperty HKLM:SOFTWARE\Microsoft\SMS\DP).ContentLibraryPath}
        $driveletter = $ContentLib[0]
        $Location = "\\" + $DPName + "\$driveletter$\sccmcontentlib\pkglib"
        $iniPath = Join-Path $Location "$package.INI"
    # Check Content lib for package ini's
    if(Test-Path $iniPath){
        try{
            Write-Log "$package was found in Content Library on $DPName"
            Write-Host "$package was found in Content Library on $DPName" -ForegroundColor Green
        }catch{
            Write-Log "$package was not found in Content Library on $DPName"
            Write-Host "$package was not found in Content Library on $DPName" -ForegroundColor Yellow
        }
    }
            
}

