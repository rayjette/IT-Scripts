Function Get-ADInactiveComputer {
    <#
        .SYNOPSIS
        Find inactive computer account objects in Active Directory.

        .DESCRIPTION
        Get-ADInactiveComputer searches for inactive Active Directory computer account objects.
        It can filter accounts based on the number of days since the last logon,
        accounts that have never logged on, and accounts that are disabled.

        .PARAMETER InactiveDays
        Specifies the number of days since the last logon to consider a computer account inactive.
        The default value is 90 days.

        .PARAMETER NeverLogon
        Filters the results to include only computer accounts that have never logged on.

        .PARAMETER DisabledOnly
        Filters the result to include only computer accounts that are disabled.

        .PARAMETER SearchBase
        Specifies the distinguished name of the OU to search in.

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
        Raymond Jette
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

    $filterDate = (Get-Date).AddDays(-$InactiveDays)

    # The parameter for Get-ADComputer
    $splat = @{
        Filter     = '*'
        Properties = 'LastLogonDate', 'Enabled'
    }
    # If the SearchBase parameter was specified add it to the parameters to Get-ADComputer.
    if ($PSBoundParameters.ContainsKey('SearchBase')) {
        $splat.add('SearchBase', $SearchBase)
    }

    # Get computers objects from Active Directory.
    $computers = Get-ADComputer @splat
    
    # If the DisabledOnly parameter is specified we are only instrested in disabled computer objects.
    if ($PSBoundParameters.ContainsKey('DisabledOnly')) {
        foreach ($computer in $computers) {
            if (-not ($computer.enabled)) {
                $computer
            }
        }
    }
    # If the NeverLogon parameter is present output computers which have never logged on.
    elseif ($PSBoundParameters.ContainsKey('NeverLogon')) {
        $computers | Where-Object {$null -eq $_.LastLogonDate}
    }
    # Output all computers which have not logged on since or before $filterDate.
    else {
        $computers | Where-Object {$_.LastLogonDate -lt $filterDate}
    }
} # Get-ADInactiveComputer