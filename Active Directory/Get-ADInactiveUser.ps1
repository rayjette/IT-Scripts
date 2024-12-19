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

    .EXAMPLE
        Find-ADUnsuedComputers
        Finds Active Directory user objects which have not been logged on for 90 days or more or which have never been logged on to.

    .EXAMPLE
        Get-ADInactiveUser -Days 60
        Finds Active Directory user objects which have not been logged on for 60 days or more or have never been logged on to.

        Get-ADInactiveUser -DisabledOnly
        Finds Active Directory user accounts which are disabled.

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

    # A helper function to test if an AD User object is enabled
    Function Test-IsADUserEnabled($Identity) {
        [bool](Get-ADUser -Identity $Identity).enabled
    }


    $filterDate = (Get-Date).AddDays(-$Days)

    # The parameter for Get-ADUser
    $splat = @{
        Filter     = '*'
        Properties = 'LastLogonDate'
    }

    if ($PSBoundParameters.ContainsKey('SearchBase')) {
        $splat.add('SearchBase', $SearchBase)
    }

    $users = Get-ADUser @splat

    $users | Where-Object {
        ($NeverLogon -and -not $_.LastLogonDate) -or
        ($DisabledOnly -and -not $_.Enabled) -or
        ($_.LastLogonDate -lt $filterDate)
    }
}