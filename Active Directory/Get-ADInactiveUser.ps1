#Requires -Modules ActiveDirectory

Function Get-ADInactiveUser {
    <#
    .SYNOPSIS
        Find unused Active Directory user account objects.

    .DESCRIPTION
        Find unused Active Directory user account objects.

    .PARAMETER Days
        Accounts which have not been logged on to in this number of days will be considered inactive.  A default value of 90 days is provided.

    .PARAMETER NeverLogon
        Find Active Directory user accounts which have never been logged on to.

    .PARAMETER DisabledOnly
        Find Active Directory user accounts which are disabled.

    .PARAMETER SearchBase
        Specifies the Organizational Unit (OU) to search within.

    .EXAMPLE
        Get-ADInactiveUser
        Finds Active Directory user objects which have not been logged on for 90 days or more.

    .EXAMPLE
        Get-ADInactiveUser -Days 60
        Finds Active Directory user objects which have not been logged on for 60 days or more.

        Get-ADInactiveUser -DisabledOnly
        Finds Active Directory user accounts which are disabled.

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

    $filterDate = (Get-Date).AddDays(-$Days)

    # The parameter for Get-ADUser
    $splat = @{
        Filter     = '*'
        Properties = 'LastLogonDate'
    }

    if ($PSBoundParameters.ContainsKey('SearchBase')) {
        $splat.add('SearchBase', $SearchBase)
    }

    try {
        $users = Get-ADUser @splat

        $users | Where-Object {
            ($NeverLogon -and -not $_.LastLogonDate) -or
            ($DisabledOnly -and -not $_.Enabled) -or
            ($_.LastLogonDate -lt $filterDate)
        }
    } catch {
        Write-Error _Message "An error occurred while retrieving or filtering user accounts: $_"
    }
}