
<#
.SYNOPSIS
Removes specified SCCM packages from a Distribution Point's WMI and Content Library.

.DESCRIPTION
This script reads a list of SCCM package IDs from a text file and removes each package from both the WMI repository and the Content Library on a specified Distribution Point.

.PARAMETER DPName
The FQDN of the Distribution Point.

.PARAMETER PackageIDs.txt
A text file containing one PackageID per line, located in the user's %TEMP% directory.

.EXAMPLE
.\Remove-SCCMPackageFromDP.ps1

.NOTES
Author: Daniel Fletcher
Date: 05/09/2025
#>


$logFilePath = "C:\Windows\fndr\logs"
$logFileName = "$logFilePath\Remove-SCCMPackageFromDP.log"

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

Write-Log "Starting Remove-SCCMPackageFromDP.Log"
Write-Host "Please ensure you have the necessary input file created in $env:TEMP" -ForegroundColor Yellow

# Get Distribution Point Name via user input | Get input path for PackageIDs
$DPName = Read-Host "Enter Distribution Point FQDN"
$PkgID = Get-Content (Join-Path $env:TEMP "PackageIDs.txt") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

$creds = Get-Credential

Write-Log "Starting Removal Process"
foreach($package in $PkgID){

    $wmiObj = Get-WmiObject -ComputerName $DPName -Namespace Root\SCCMDP -Class SMS_PackagesInContLib -Filter "PackageID = '$package'" 
    
    if($wmiObj){
        try{
            #remove from wmi
            $wmiObj | Remove-WmiObject
            Write-Log "Removed $package from WMI on $DPName"
            Write-Host "Removed $package from WMI on $DPName" -ForegroundColor Green
        }catch{
        Write-Log "$package could not be removed from WMI on $DPName, please verify if it is still present."
        Write-Host "$package could not be removed from WMI on $DPName, please verify if it is still present." -ForegroundColor Red
        }
    }else{
        Write-Log "$package was not found in WMI on $DPName"
        Write-Host "$package was not found in WMI on $DPName" -ForegroundColor Yellow
    }

    try{
        #remove from content library
        $ContentLib = Invoke-Command -ComputerName $DPName -Credential $creds -ScriptBlock  {(Get-ItemProperty HKLM:SOFTWARE\Microsoft\SMS\DP).ContentLibraryPath}
        $driveletter = $ContentLib[0]
        $Location = "\\" + $DPName + "\$driveletter$\sccmcontentlib\pkglib"
        $iniPath = Join-Path $Location "$package.INI"

        if(Test-Path $iniPath) {
            Set-Location $Location
            Remove-Item "$package.INI"
            Set-Location $env:SystemDrive
            Write-Log "Done! $package was removed from Content Library on $DPName"
            Write-Host "Done! $package was removed from Content Library on $DPName" -ForegroundColor Green
        }else{
            Write-Log "$package was not found in Content Library on $DPName"
            Write-Host "$package was not found in Content Library on $DPName" -ForegroundColor Yellow
        }
    }catch{
            Write-Log "$package could not be removed from Content Library on $DPName, please verify if content is still present."
            Write-Host "$package could not be removed from Content Library on $DPName, please verify if content is still present." -ForegroundColor Red
        }


        #remove packages from distribution point
        try{
            Remove-CMContentDistribution -PackageID $package -Force -DistributionPointName $DPName
            Write-Log "Removed $package from Distribution Point $DPName"
            Write-Host "Removed $package from Distribution Point $DPName" -ForegroundColor Green
        }catch{
            Write-Log "$package could not be removed from Distribution Point $DPName"
            Write-Host "$package could not be removed from Distribution Point $DPName" -ForegroundColor Red
        }
            
}

