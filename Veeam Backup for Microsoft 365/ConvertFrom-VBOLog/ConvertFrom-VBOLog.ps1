Function ConvertFrom-VBOLog
{
    <#
    .SYNOPSIS
    Parses the entries in the specified Veeam Backup for Microsoft 365
    log file into fields which are returned as objects of type 
    system.management.automation.pscustomobject.

    .DESCRIPTION 
    Parses the entries in the specified Veeam Backup for Microsoft 365
    log file into fields which are returned as objects of type 
    system.management.automation.pscustomobject.

    ConvertFrom-VBOLog has been tested for Veeam Backup for Miicrosoft 365
    build 7.0.0.438 P2023015 with the following log files:
    - Veeam.Archiver.REST
    - Veeam.Archiver.Proxy
    - Veeam.Archiver.Service
    - Veeam.Archiver.Shell
    - Job logs

    .PARAMETER FileName
    The full path to the filename.

    .EXAMPLE
    ConvertFrom-VBOLog -FileName C:\ProgramData\Veeam\Backup365\Logs\Veeam.Archiver.Proxy_2021_07_16_06_48_16.log | Format-Table

    .INPUTS
    None.  You can't pipe objects to ConvertFrom-VBOLog.

    .OUTPUTS
    system.managment.automation.pscustomobject.

    .NOTES
    Author: Raymond Jette
    https://github.com/rayjette
    Version: 1.0
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]$FileName
    )

    # A helper function that converts a give date with the 
    # format dd.m.m.yyyy into mm.dd.yyyy.
    Function ConvertTo-NormalizedDate($date)
    {
        Get-Date ([datetime]::parseexact($date, 'dd.mm.yyyy', $null)) -Format 'mm.dd.yyyy'
    }

    $pattern = @(
        '^\[(?<Date>\d{2}\.\d{2}\.\d{4}) (?<Time>\d{2}:\d{2}:\d{2}\.\d{3})\]',
        '\s+(?<ProcessID>\d+)\s+\((?<ThreadID>\d{4})\)(?<Event>.*)$'
    ) -join ''

    if (-not (Test-Path -Path $FileName -PathType Leaf)) {
        Write-Error -Message "Path must be valid." 
    } else {
        Get-Content -Path $FileName | ForEach-Object {
            if ($_ -match $pattern) {
                [PSCustomObject]@{
                    Date = ConvertTo-NormalizedDate -Date $matches.Date
                    Time = $matches.Time
                    ProcessID = $matches.ProcessID
                    ThreadID = $matches.ThreadID
                    Event = $matches.Event.trim()
                }
            }
        }
    }
} # ConvertFrom-VBOLog