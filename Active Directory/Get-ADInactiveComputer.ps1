#Requires -Modules ActiveDirectory

Function Get-ADInactiveComputer {
    <#
    .SYNOPSIS
        Find inactive computer account objects in Active Directory.

    .DESCRIPTION
            Get-ADInactiveComputer searches for computer accounts in Active Directory that are inactive based on the specific criteria.

    .PARAMETER InactiveDays
        Specifies the number of days a computer account has been inactive.  Default is 90 days.

    .PARAMETER NeverLogon
        Filters the results to include only computer accounts that have never logged on.

    .PARAMETER DisabledOnly
        Finds computer accounts that are disabled.

    .PARAMETER SearchBase
        Specifies the Organizational Unit (OU) to search within.

    .EXAMPLE
        Get-ADInactiveComputer
        Finds Active Directory computer account objects which have been inactive for 90 days or more.

    .EXAMPLE
        Get-ADInactiveComputer -InactiveDays 60
        Finds Active Directory computer objects which have not been logged on for 60 days or more.

    .EXAMPLE
        Get-ADInactiveComputer -DisabledOnly
        Finds Active Directory computer accounts which are disabled.

    .EXAMPLE
        Get-ADInactiveComputer -NeverLogon
        Finds Active Directory computer accounts which have never been logged on.

    .EXAMPLE
        Get-ADInactiveComputer -SearchBase 'OU=Computers,DC=contoso,DC=com'
        Finds Active Directory computer accounts in the specified OU.

    .INPUTS
        None.  Get-ADInactiveComputer does not accept pipeline input.

    .OUTPUTS
        Microsoft.ActiveDirectory.Management.ADComputer

    .NOTES
        Author: Raymond Jette
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    Param (
        [ValidateNotNullOrEmpty()]
        [Int32]$InactiveDays = 90,

        [Parameter(Mandatory, ParameterSetName='NeverLogon')]
        [switch]$NeverLogon,

        [Parameter(Mandatory, ParameterSetName='DisabledOnly')]
        [switch]$DisabledOnly,

        [string]$SearchBase
    )

    # Calculate the date to filter inactive computers
    $filterDate = (Get-Date).AddDays(-$InactiveDays)

    # The parameter for Get-ADComputer
    $splat = @{
        Filter     = '*'
        Properties = 'LastLogonDate', 'Enabled'
    }

    # Add SearchBase parameter if specified
    if ($PSBoundParameters.ContainsKey('SearchBase')) {
        $splat.add('SearchBase', $SearchBase)
    }

    try {
        # Retrieve computer objects from Active Directory
        $computers = Get-ADComputer @splat
        
        # Filter computers base on specified criteria
        $computers | Where-Object {
            ($NeverLogon -and -not $_.LastLogonDate) -or
            ($DisabledOnly -and -not $_.Enabled) -or
            ($_.LastLogonDate -lt $filterDate)
        }
    } catch {
        Write-Error _Message "An error occurred while retrieving or filtering computer accounts: $_"
    }
} # Get-ADInactiveComputer