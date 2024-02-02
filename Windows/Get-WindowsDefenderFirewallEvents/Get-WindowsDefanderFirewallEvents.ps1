Function Get-WindowsDefenderFirewallEvents
{
    <#
    .SYNOPSIS

    Gets events from the Windows firewall log.

    .DESCRIPTION

    Gets events from the Windows firewall log.

    .PARAMETER Path

    The location of the firewall log file.  This parameter is only needed if you are using a log file that is not in the default location.

    .EXAMPLE

    Get-WindowsDefenderFirewallEvents

    .EXAMPLE

    Get-WindowsDefenderFirewallEvents -Path C:\Windows\System32\LogFiles\Firewall\pfirewall.log

    .NOTES

    Firewall logging must be enabled on the computer for Get-WindowsDefenerFirewallEvents to work.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [System.IO.FileInfo]
        $Path = 'C:\Windows\System32\LogFiles\Firewall\pfirewall.log'
    )
    Set-StrictMode -Version Latest
    
    if (Test-Path -Path $Path -PathType Leaf) {
        Get-Content -Path $path | Select-Object -Skip 5 | 
            ForEach-Object {
                # Split the log entry at a space and if the value is
                # a single '-' then replace it with a null value.
                $split = $_ -split(' ') | ForEach-Object {
                    if ($_ -match '^\-$') { $null } else { $_ }
                }
                $dateTime = '{0} {1}' -f $split[0], $split[1]
                [PSCustomObject]@{
                    DateTime   = [datetime] $dateTime
                    Action     = $split[2]
                    Protocol   = $split[3]
                    SourceIP   = $split[4]
                    DestIP     = $split[5]
                    SourcePort = $split[6]
                    DestPort   = $split[7]
                    Size       = $split[8]
                    TCPFlags   = $split[9]
                    TCPSyn     = $split[10]
                    TCPAck     = $split[11]
                    TCPWin     = $split[12]
                    IcmpType   = $split[13]
                    IcmpCode   = $split[14]
                    Info       = $split[15]
                    Path       = $split[16]
                }
        }
    } else {
        throw 'Path does not exist.'
    }
} 