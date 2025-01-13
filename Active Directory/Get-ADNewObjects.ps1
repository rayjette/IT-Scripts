#Requires -Modules ActiveDirectory

Function Get-ADNewObjects {
    <#
    .SYNOPSIS
        Finds new Active Directory objects created after a specified date.

    .DESCRIPTION
        This function queries Active Directory to find objects that were created after or equal to a specified date.
        By default, it looks for objects created in the last 7 days.

    .PARAMETER Date
        Returns Active Directory objects created after the specified date.

    .EXAMPLE
        Get-ADNewObjects 
        This command finds all Active Directory objects created in the last 7 days.

    .EXAMPLE
        Get-ADNewObjects -Date (Get-Date).AddDays(-30)
        This command finds all Active Directory objects created in the last 30 days.

    .INPUTS
        None.  Get-ADNewObjects does not accept input from the pipeline.

    .OUTPUTS
        Microsoft.ActiveDirectory.Management.ADObject

    .NOTES
        Author: Raymond Jette
        Date: 01/13/2025
        https://github.com/rayjette
    #>
    [CmdletBinding()]
    param (
        [DateTime]$Date = (Get-Date).AddDays(-7)
    )

    try {
        $getADObjectParams = @{
            Filter     = '*'
            Properties = 'whenCreated'
        }
        Get-ADObject @getADObjectParams | Where-Object {$_.whenCreated -ge $date}
    } catch {
        Write-Error "An error occurred while getting users from Active Directory: $_"
    }
}