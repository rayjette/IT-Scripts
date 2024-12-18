Function Find-ADUnusedComputers {
    <#
        .SYNOPSIS
        Find unused Active Directory computer account objects.

        .DESCRIPTION
        Find unused Active Directory computer account objects.

        .PARAMETER InactiveDays
        Accounts which have not been logged on to in this number of days will be considered inactive.  A default value of 90 InactiveDays is provided.

        .PARAMETER OnlyNeverLogon
        Find Active Directory computer accounts which have never been logged on to.

        .PARAMETER DisabledOnly
        Find Active Directory computer accounts which are disabled.

        .EXAMPLE
        Find-ADUnsuedComputers
        Finds Active Directory computer objects which have not been logged on for 90 days or more or which have never been logged on to.

        .EXAMPLE
        Find-ADUnusedComputers -InactiveDays 60
        Finds Active Directory computer objects which have not been logged on for 60 days or more or have never been logged on to.

        Find-ADUnusedComputers -DisabledOnly
        Finds Active Directory computer accounts which are disabled.

        .INPUTS
        None.  Find-ADUnusedComputers does not accept pipeline input.

        .OUTPUTS
        Microsoft.ActiveDirectory.Management.ADComputer
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    Param (
        [ValidateNotNullOrEmpty()]
        [Int32]$InactiveDays = 90,

        [Parameter(Mandatory, ParameterSetName='NeverLogon')]
        [switch]$OnlyNeverLogon,

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
    # If the OnlyNeverLogon parameter is present output computers which have never logged on.
    elseif ($PSBoundParameters.ContainsKey('OnlyNeverLogon')) {
        $computers | Where-Object {$null -eq $_.LastLogonDate}
    }
    # Output all computers which have not logged on since or before $filterDate.
    else {
        $computers | Where-Object {$_.LastLogonDate -lt $filterDate}
    }
} # Find-ADUnusedComputers