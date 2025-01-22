#Requires -Modules ActiveDirectory

Function Find-DisabledMembersInGroups {
    <#
    .SYNOPSIS
        Retrieves Active Directory groups that contain disabled members.

    .DESCRIPTION
        This script queries Active Directory to find groups that have members who are disabled.
        It helps administrators to identify and manage groups with inactive accounts.

    .PARAMETER Name
        Specifies the name of one or more groups to search for disabled members.  This parameter is optional.

    .PARAMETER Type
        Specifies the type of the group (Security or Distribution).  This parameter is optional


    .PARAMETER SearchBase
        Specifies the distinguished name of an Active Directory container or organizational unit. The search for
        groups with disabled members will be limited to this container and its children. This parameter is optional.

    .PARAMETER IncludeDomainUsers
        Specifies whether to include the "Domain Users" group in the processing.  If this parameter is not provided,
        the "Domain Users" group will be excluded from the results.  Since all users are members of the "Domain Users"
        group by default, specifying this parameter will cause all disabled users to be reported.

    .PARAMETER IncludeDomainComputers
        Specifies whether to include the "Domain Computers" group in the processing.  If this parameter is not provided,
        the "Domain Computers" group will be excluded from the results.  Since all computers are members of the
        "Domain Computers" group by default, specifying this parameter will cause all disabled computers to be reported.

    .EXAMPLE
        Find-DisabledMembersInGroups

    .EXAMPLE
        Find-DisabledMembersInGroups -SearchBase 'OU=Groups,DC=example,DC=com' -Type 'Security'

    .EXAMPLE
        Find-DisabledMembersInGroups -IncludeDomainUsers

    .EXAMPLE
        Find-DisabledMembersInGroups -IncludeDomainComputers

    .INPUTS
        None.  Find-DisabledMembersInGroups does not accept pipelined input.
    
    .OUTPUTS
        System.Management.Automation.PSCustomObject

    .NOTES
        Author: Raymond Jette
        Date: 01/21/2025
        https://github.com/rayjette
    #>
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()]
    Param (
        [ValidateNotNullOrEmpty()]
        [string]$SearchBase,

        [ValidateSet('Security', 'Distribution')]
        [string]$Type,

        [switch]$IncludeDomainUsers,

        [switch]$IncludeDomainComputers
    )

    # Helper functions to check if accounts are enabled
    Function Test-IsADComputerEnabled($Identity) {
        [bool](Get-ADComputer -Identity $Identity).enabled
    }

    Function Test-IsADUserEnabled($Identity) {
        [bool](Get-ADUser -Identity $Identity).enabled
    }

    # Parameters for Get-ADGroup
    $getADGroupParams = @{ Filter = '*' }

    # If SearchBase is specified add it to the parameter list
    if ($PSBoundParameters.ContainsKey('SearchBase')) {
        $getADGroupParams.add('SearchBase', $SearchBase)
    }

    # Get groups from Active Directory.
    $groups = Get-ADGroup @getADGroupParams

    # Filter groups by Type (if specified)
    if ($PSBoundParameters.ContainsKey('Type')) {
        $groups = $groups | Where-Object { $_.GroupCategory -eq $type }
    }

    # Initialize a counter for the progress bar
    $count = 0

    # List of disabled users to exclude by default
    $excludedUsers = @('krbtgt')

    foreach ($group in $groups) {
        # Skip the "Domain Users" group unless IncludeDomainUsers is specified
        if ($group.name -eq 'Domain Users' -and -not $IncludeDomainUsers) {
            continue
        }
        
        # Skip the "Domain Computers" group unless IncludeDomainComputers is specified
        if ($group.name -eq 'Domain Computers' -and -not $IncludeDomainComputers) {
            continue
        }

        # Update counter and generate a progress bar.
        $count++
        $progressParams = @{
            Activity = "Checking if group has disabled members: {0}" -f $group.name
            Status   = "Finding Group {0} of {1}" -f $count, $groups.count
            PercentComplete = (($count / $groups.count) * 100)
        }
        Write-Progress @progressParams

        # Get the members of the current group
        $groupMembers = Get-ADGroupMember -Identity $group.distinguishedName

        # Variables to store disabled users and computers.
        $disabledUsers = @()
        $disabledComputers = @()

        # Check each member for disabled status
        foreach ($member in $groupMembers) {
            # Skip any excluded users
            if ($member.objectClass -eq 'user' -and $excludedUsers -contains $member.samAccountName) {
                continue
            }

            # Check if the user is disabled
            if ($member.objectClass -eq 'user' -and -not (Test-IsADUserEnabled -Identity $member.samAccountName)) {
                $disabledUsers += $member.name
            }
            # Check if the computer is disabled
            elseif ($member.objectClass -eq 'computer' -and -not (Test-IsADComputerEnabled -Identity $member.samAccountName)) {
                $disabledComputers += $member.name
            }
        }

        # Return results for disabled users
        foreach ($user in $disabledUsers) {
            [PSCustomObject]@{
                GroupName = $group.name
                MemberType = 'User'
                DisabledObject = $user
            }
        }

        # Return results for disabled computers
        foreach ($computer in $disabledComputers) {
            [PSCustomObject]@{
                GroupName = $group.name
                MemberType = 'Computer'
                DisabledObject = $computer
            }
        }
    }
} # Find-DisabledMembersInGroups