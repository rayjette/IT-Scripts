#Requires -Modules ActiveDirectory

Function Get-ADInactiveUser {
    <#
    .SYNOPSIS
        Find inactive user account objects in Active Directory.

    .DESCRIPTION
        Get-ADInactiveUser searches for user accounts in Active Directory that are inactive based on the specific criteria.

    .PARAMETER Days
        Specifies the number of days a user account has not been used to be considered inactive.  Default is 90 days.

    .PARAMETER NeverLogon
        Reports only user accounts that have never logged on.

    .PARAMETER DisabledOnly
        Reports only user accounts that are disabled.

    .PARAMETER SearchBase
        Specifies the Organizational Unit (OU) to search within.

    .EXAMPLE
        Get-ADInactiveUser
        Finds Active Directory user account objects which have been inactive for 90 days or more.

    .EXAMPLE
        Get-ADInactiveUser -Days 60
        Finds Active Directory user objects which have not been logged on for 60 days or more.

    .EXAMPLE
        Get-ADInactiveUser -DisabledOnly
        Reports only Active Directory user accounts which are disabled.

    .EXAMPLE
        Get-ADInactiveUser -NeverLogon
        Reports only Active Directory user accounts which have never been logged on.

    .EXAMPLE
        Get-ADInactiveUser -SearchBase 'OU=Users,DC=contoso,DC=com'
        Finds Active Directory computer accounts in the specified OU.

    .INPUTS
        None.  Get-ADInactiveUser does not accept pipeline input.

    .OUTPUTS
        Microsoft.ActiveDirectory.Management.ADUser

    .NOTES
        Author: Raymond Jette
    #>
    [OutputType([Microsoft.ActiveDirectory.Management.ADUser])]
    [CmdletBinding(DefaultParameterSetName='Default')]
    Param (
        [ValidateNotNullOrEmpty()]
        [Int32]$Days = 90,

        [Parameter(Mandatory, ParameterSetName='NeverLogon')]
        [switch]$NeverLogon,

        [Parameter(Mandatory, ParameterSetName='DisabledOnly')]
        [switch]$DisabledOnly,

        [string]$SearchBase
    )

    # Calculate the date to filter inactive computers
    $filterDate = (Get-Date).AddDays(-$Days)

    # The parameter for Get-ADUser
    $splat = @{
        Filter     = '*'
        Properties = 'LastLogonDate'
    }

    # Add SearchBase parameter if specified
    if ($PSBoundParameters.ContainsKey('SearchBase')) {
        $splat.add('SearchBase', $SearchBase)
    }

    try {
        # Retrieve user objects from Active Directory
        $users = Get-ADUser @splat

        # Filter users base on specified criteria
        $users | Where-Object {
            ($NeverLogon -and -not $_.LastLogonDate) -or
            ($DisabledOnly -and -not $_.Enabled) -or
            ($_.LastLogonDate -lt $filterDate)
        }
    } catch {
        Write-Error _Message "An error occurred while retrieving or filtering user accounts: $_"
    }
}