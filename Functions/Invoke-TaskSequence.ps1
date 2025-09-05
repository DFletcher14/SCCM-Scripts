# MARK: Invoke-TaskSequence Function


function Invoke-TaskSequence {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskSequenceName,
        [switch]$VerboseLogging # Enables the following switch to run logging -VerboseLogging
    )
    # Retrieve the Task Sequence policy object
    $tsPolicy = Get-WmiObject -Namespace "root\ccm\policy\machine\actualconfig" -Class "CCM_TaskSequence" | Where-Object { $_.PKG_Name -eq $TaskSequenceName } | Select-Object -First 1
    if (-not $tsPolicy) {
        Write-Log "Task Sequence '$TaskSequenceName' not found in policy" -Severity 2
        return $false
    }
    if ($VerboseLogging) {
        Write-Log "Found Task Sequence: $($tsPolicy.PKG_PackageID) / $($tsPolicy.ADV_AdvertisementID)"
    }

    # Retrieve the matching Schedule ID
    $scheduleID = Get-WmiObject -Namespace "root\ccm\scheduler" -Class "CCM_Scheduler_History" | Where-Object { $_.ScheduleID -like "*$($tsPolicy.PKG_PackageID)*"} | Select-Object -ExpandProperty ScheduleID -First 1
    if (-not $scheduleID) {
        Write-Log "Schedule ID not found for PackageID '$($tsPolicy.PKG_PackageID)'" -Severity 2
        return $false
    }
    if ($VerboseLogging) {
        Write-Log "ScheduleID Found: $scheduleID"
    }

    # Check if the RepeatRunBehavior is set to RerunAlways, if not change the value
    if ($tsPolicy.PSObject.Properties.Name -contains "ADV_RepeatRunBehavior") {
        if ($tsPolicy.ADV_RepeatRunBehavior -ne "RerunAlways") {
            $tsPolicy.ADV_RepeatRunBehavior = "RerunAlways"
            if ($VerboseLogging) { Write-Log "RepeatRunBehavior set to RerunAlways" }
        }
    }

    # Set the mandatory assignment property to true mimicing it contains assignments
    if ($tsPolicy.PSObject.Properties.Name -contains "ADV_MandatoryAssignments") {
        $tsPolicy.ADV_MandatoryAssignments = $true
        if ($VerboseLogging) {Write-Log "MadatoryAssignments have are set to $true"}
    }
    #Comit the modified WMI after making the above changes
    $tsPolicy.Put() | Out-Null
    
    # Trigger the Task Sequence
    Invoke-WmiMethod -Namespace "root\ccm" -Class "SMS_Client" -Name "TriggerSchedule" -ArgumentList $scheduleID
    if ($VerboseLogging) { Write-Log "Task Sequence triggered successfully." }

    return $true

}
