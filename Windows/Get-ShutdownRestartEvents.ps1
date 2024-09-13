Function Get-ShutdownRestartEvents {
    <#
        .SYNOPSIS
            Gets information about reboot and shutdown events.

        .DESCRIPTION
            Gets information about reboot and shutdown events.

        .EXAMPLE
            Get-ShutdownRestartEvents

        .INPUTS
            Get-ShutdownRestartEvents does not accept input from the pipeline.

        .OUTPUTS
            System.Management.Automation.PSCustomObject.

        .NOTES
            Raymond Jette
    #>

    $filter = @{
        LogName = 'System'
        ID = @(41, 1074)
    }

    foreach ($event in (Get-WinEvent -FilterHashtable $filter)) {

        $result = [PSCustomObject]@{
            Time     = $event.TimeCreated
            Computer = $event.machinename
            Action   = $null
            Process  = $null
            User     = $null
            Reason   = $null
        }

        if ($event.id -eq 1074) {
            $result.action   = $event.properties[4].value
            $result.process  = $event.properties[0].value
            $result.user     = $event.properties[6].value
            $result.reason   = $event.properties[2].value

        } elseif ($event.id -eq 41) {
            $message = 'The system has rebooted without cleanly shutting down first.'
            if ($event.message -like "*$($message)*") {
                $result.reason = 'Stopped responding, crashed, or lost power'
                $result.action = 'Reboot or power on'
                
            } else {
                Write-Warning -Message "Unknown event"
            }
        }
        $result
    }
}