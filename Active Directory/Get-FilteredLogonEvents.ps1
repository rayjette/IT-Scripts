function Get-FilteredLogonEvents {
    [CmdletBinding()]
    param (
        [string]$UserName,
        [string[]]$LogonType = @(),
        [string[]]$ExcludeLogonType = @(),
        [datetime]$StartTime
    )

    Add-Type -AssemblyName System.Core

    $logonTypeMap = @{
        "Interactive"         = 2
        "Network"             = 3
        "Batch"               = 4
        "Service"             = 5
        "Unlock"              = 7
        "NetworkCleartext"    = 8
        "NewCredentials"      = 9
        "RemoteInteractive"   = 10
        "CachedInteractive"   = 11
    }

    function Get-LogonTypeName {
        param ([int]$code)
        return $logonTypeMap.GetEnumerator() | Where-Object { $_.Value -eq $code } | Select-Object -ExpandProperty Key -First 1
    }

    # Enforce mutual exclusivity of -LogonType and -ExcludeLogonType
    if ($LogonType -and $ExcludeLogonType) {
        throw "You cannot use -LogonType and -ExcludeLogonType at the same time."
    }

    $includeLogonTypes = @()
    foreach ($lt in $LogonType) {
        if ($logonTypeMap.ContainsKey($lt)) {
            $includeLogonTypes += $logonTypeMap[$lt]
        } else {
            Write-Warning "Unknown LogonType: '$lt'. Valid types: $($logonTypeMap.Keys -join ', ')"
        }
    }

    $excludeLogonTypes = @()
    foreach ($lt in $ExcludeLogonType) {
        if ($logonTypeMap.ContainsKey($lt)) {
            $excludeLogonTypes += $logonTypeMap[$lt]
        } else {
            Write-Warning "Unknown LogonType to exclude: '$lt'. Valid types: $($logonTypeMap.Keys -join ', ')"
        }
    }

    $shouldFilterInclude = $includeLogonTypes.Count -gt 0
    $shouldFilterExclude = $excludeLogonTypes.Count -gt 0

    $eventIDs = @("EventID=4624", "EventID=4625")
    $conditions = @("($($eventIDs -join ' or '))")
    if ($StartTime) {
        $startUTC = $StartTime.ToUniversalTime().ToString("o")
        $conditions += "TimeCreated[@SystemTime >= '$startUTC']"
    }

    $xpathQuery = "*[System[$($conditions -join ' and ')]]"
    $logName = "Security"

    try {
        $query = New-Object System.Diagnostics.Eventing.Reader.EventLogQuery(
            $logName,
            [System.Diagnostics.Eventing.Reader.PathType]::LogName,
            $xpathQuery
        )
    } catch {
        Write-Error "Invalid XPath query: $xpathQuery"
        return
    }

    $reader = New-Object System.Diagnostics.Eventing.Reader.EventLogReader($query)

    while ($event = $reader.ReadEvent()) {
        $xml = [xml]$event.ToXml()
        $eventID = [int]$xml.Event.System.EventID

        $data = @{}
        foreach ($d in $xml.Event.EventData.Data) {
            $data[$d.Name] = $d.'#text'
        }

        $logonTypeRaw = $data['LogonType']
        if (-not [string]::IsNullOrWhiteSpace($logonTypeRaw) -and ($logonTypeRaw -as [int])) {
            $logonTypeValue = [int]$logonTypeRaw
        } else {
            $logonTypeValue = $null
        }

        $logonTypeName = if ($logonTypeValue) { Get-LogonTypeName -code $logonTypeValue } else { $null }
        $targetUser = $data['TargetUserName']
        $resultType = if ($eventID -eq 4624) { "Success" } else { "Failure" }

        # Apply logon type filters
        $logonTypeMatch = $true
        if ($shouldFilterInclude) {
            $logonTypeMatch = $includeLogonTypes -contains $logonTypeValue
        } elseif ($shouldFilterExclude) {
            $logonTypeMatch = -not ($excludeLogonTypes -contains $logonTypeValue)
        }

        $userMatch = $true
        if ($UserName) {
            $userMatch = $targetUser -like $UserName
        }

        if ($logonTypeMatch -and $userMatch) {
            [PSCustomObject]@{
                TimeCreated             = $event.TimeCreated
                Result                  = $resultType
                Account                 = $targetUser
                Domain                  = $data['TargetDomainName']
                SubjectAccount          = $data['SubjectUserName']
                SubjectDomain           = $data['SubjectDomainName']
                LogonType               = $logonTypeName
                Workstation             = $data['WorkstationName']
                IPAddress               = $data['IpAddress']
                LogonProcess            = $data['LogonProcessName']
                AuthenticationPackage   = $data['AuthenticationPackageName']
                FailureReason           = $data['FailureReason']
                Status                  = $data['Status']
                SubStatus               = $data['SubStatus']
                ProcessName             = $data['ProcessName']
                ProcessId               = $data['ProcessId']
                LogonGuid               = $data['LogonGuid']
                TargetLogonId           = $data['TargetLogonId']
                TransmittedServices     = $data['TransmittedServices']
                LmPackageName           = $data['LmPackageName']
                KeyLength               = $data['KeyLength']
            }
        }
    }

    $reader.Dispose()
}
