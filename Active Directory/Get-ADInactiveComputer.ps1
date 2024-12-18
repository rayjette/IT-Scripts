Function Get-ADInactiveComputer {
    <#
        .SYNOPSIS
        Find inactive computer account objects.

        .DESCRIPTION
        Find inactive Active Directory computer account objects.

        .PARAMETER InactiveDays
        Accounts which have not been logged on to in this number of days will be considered inactive.  A default value of 90 InactiveDays is provided.

        .PARAMETER NeverLogon
        The NeverLogon parameter will cause Get-ADInactiveComputer to return computer accounts which have never been used to logon.

        .PARAMETER DisabledOnly
        Find Active Directory computer accounts which are disabled.

        .EXAMPLE
        Get-ADInactiveComputer
        Finds Active Directory computer objects which have not been logged on for 90 days or more or which have never been logged on to.

        .EXAMPLE
        Get-ADInactiveComputer -InactiveDays 60
        Finds Active Directory computer objects which have not been logged on for 60 days or more or have never been logged on to.

        Get-ADInactiveComputer -DisabledOnly
        Finds Active Directory computer accounts which are disabled.

        .INPUTS
        None.  Get-ADInactiveComputer does not accept pipeline input.

        .OUTPUTS
        Microsoft.ActiveDirectory.Management.ADComputer
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