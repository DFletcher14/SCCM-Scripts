# MARK: Add-DeviceToCollection
function Add-DeviceToCollection {
    param (
        [string] $InputFile = "C:\Users\admin_dflet001\Desktop\Scripts\Input.txt",
        [string] $Collection
    )
    
    # Script running variable, used to invoke-cmcollectionupdate later on
    $scriptFailed = $false

    Write-Host "`n[Add-DeviceToCollection] Starting Script.." -ForegroundColor Green
    # Check if input file exists
    if (-not (Test-Path $InputFile)){
        Write-Host "Input File not found at $InputFile" -ForegroundColor Red
        $scriptFailed = $true
        return
   }
   # check if collection is provided, if not prompt for it
   if (-not ($Collection)){
       $Collection = Read-Host "Enter Collection Name"
   }
   # check if the collection exists
   if (-not (Get-CmDeviceCollection -Name $Collection -ErrorAction SilentlyContinue)){
        Write-Host "Collection '$Collection' Could not be found" -ForegroundColor Red
        $scriptFailed = $true
        return
   }
   # Get the list of device names from the input file
   $DeviceNames = Get-Content $InputFile | Where-Object { $_.Trim() -ne "" }
   # Loop through each device name and add it to the collection
   foreach ($DeviceName in $DeviceNames){
        $TrimmedName = $DeviceName.Trim()
        $Device = Get-CmDevice -Name $TrimmedName
        if ($Device){
            Add-CMDeviceCollectionDirectMembershipRule -CollectionName $Collection -ResourceID $Device.ResourceID
            Write-Host "$TrimmedName added to $Collection" -ForegroundColor Green
        }else{
            Write-Host "$TrimmedName not found" -ForegroundColor Red
            $scriptFailed = $true
        }
   }
   # If devices were added to the collection, force a membership update on the collection
   if (-not $scriptFailed) {
    Invoke-CMCollectionUpdate -Name $Collection
    Write-Host "Collection update has been initiated for $Collection" -ForegroundColor Green
   }
}

# MARK: Update-CollectionMembership
function Update-CollectionMembership {
    param (
        [string] $Collection
    )
    # check if collection is provided, if not prompt for it
    if (-not ($Collection)) {
        $Collection = Read-Host "Enter Collection Name"
    }
    # check collection exists, if so update membership
    if (-not (Get-CmDeviceCollection -Name $Collection -ErrorAction SilentlyContinue)) {
        Write-Host "Collection '$Collection' could not be found" -ForegroundColor Red
        return
    }else{
        Invoke-CMCollectionUpdate -Name $Collection
        Write-Host "Collection update has been initiated for $Collection" -ForegroundColor Green
    }
}

# MARK: Remove-DeviceFromCollection
function Remove-DeviceFromCollection {
    param (
        [string] $InputFile = "C:\Users\admin_dflet001\Desktop\Scripts\Input.txt",
        [string] $Collection
    )
    
    # Script running variable, used to invoke-cmcollectionupdate later on
    $scriptFailed = $false

    Write-Host "`n[Remove-DeviceFromCollection] Starting Script.." -ForegroundColor Green
    # Check if input file exists
    if (-not (Test-Path $InputFile)){
        Write-Host "Input File not found at $InputFile" -ForegroundColor Red
        $scriptFailed = $true
        return
   }
   # check if collection is provided, if not prompt for it
   if (-not ($Collection)){
       $Collection = Read-Host "Enter Collection Name"
   }
   # check if the collection exists
   if (-not (Get-CmDeviceCollection -Name $Collection -ErrorAction SilentlyContinue)){
        Write-Host "Collection '$Collection' Could not be found" -ForegroundColor Red
        $scriptFailed = $true
        return
   }
   # Get the list of device names from the input file
   $DeviceNames = Get-Content $InputFile | Where-Object { $_.Trim() -ne "" }
   # Loop through each device name and remove it to the collection
   foreach ($DeviceName in $DeviceNames){
        $TrimmedName = $DeviceName.Trim()
        $Device = Get-CmDevice -Name $TrimmedName
        if ($Device){
            Remove-CMDeviceCollectionDirectMembershipRule -CollectionName $Collection -ResourceID $Device.ResourceID
            Write-Host "$TrimmedName removed from $Collection" -ForegroundColor Green
        }else{
            Write-Host "$TrimmedName not found" -ForegroundColor Red
            $scriptFailed = $true
            return
        }
   }
   # If devices were removed from the collection, force a membership update on the collection
   if (-not $scriptFailed) {
    Invoke-CMCollectionUpdate -Name $Collection
    Write-Host "Devices have been removed and Collection update has been triggered" -ForegroundColor Green
   }
}

# MARK: Remove-DeviceFromSCCM

function Remove-DeviceFromSCCM {
    param (
        [string] $InputFile = "C:\Users\admin_dflet001\Desktop\Scripts\Input.txt"
    )
    Write-Host "`n[Remove-DeviceFromSCCM] Starting Script.." -ForegroundColor Green
    # Check if input file exists
    if (-not (Test-Path $InputFile)){
        Write-Host "Input File not found at $InputFile" -ForegroundColor Red
        return
    }
    # Get the list of device names from the input file
    $DeviceNames = Get-Content $InputFile | Where-Object { $_.Trim() -ne ""}
    # Confirm with the user before proceeding
    Write-Host "`nThis will remove any devices listed in $InputFile from SCCM" -ForegroundColor Yellow
    $Confirm = Read-Host "Do you want to continue? (Y/N)"
    if ($Confirm -ne "Y" -and $Confirm -ne "y") {
        Write-Host "Operation cancelled." -ForegroundColor Red
        return
    }
    # loops through each device name in the input file and attempts to removes it from SCCM
    foreach ($Name in $DeviceNames){
        $TrimmedName = $Name.Trim()
        $Device = Get-CmDevice -Name $TrimmedName
        if ($Device) {
            Remove-CmResource -ResourceID $Device.ResourceID -Force
            Write-Host "$TrimmedName removed from SCCM" -ForegroundColor Green
        }else{
            Write-Host "$TrimmedName not found in SCCM" -ForegroundColor Red
        }
    }
    Write-Host "`n[Remove-DeviceFromSCCM] Script has completed." -ForegroundColor Green
}
