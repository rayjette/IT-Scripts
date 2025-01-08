#Requires -Modules ActiveDirectory

Function Find-ADEmptyGroup {
    <#
    .SYNOPSIS
        Finds empty Active Directory groups.

    .DESCRIPTION
        This script finds empty Active Directory groups.  It allows filtering by search base and group type (Security or Distribution).

    .PARAMETER SearchBase
        The distinguished name of the Active Directory container to search within.

    .PARAMETER Type
        The type of group to search for.  Valid values are 'Security' and 'Distribution'.

    .EXAMPLE
        Find-ADEmptyGroup
        Finds all empty Active Directory groups in the entire directory.

    .EXAMPLE
        Find-ADEmptyGroup -SearchBase 'OU=MyGroups,DC=MyDomain,DC=com'
        Finds all empty Active Directory groups within the specified OU.

    .EXAMPLE
        Find-ADEmptyGroup -Type Security
        Finds all empty Active Directory security groups.

    .EXAMPLE
        Find-ADEmptyGroup -Type Distribution
        Finds all empty Active Directory distribution groups.

    .INPUTS
        None.  Find-ADEmptyGroup does not accept input from the pipeline.

    .OUTPUTS
        Microsoft.ActiveDirectory.Management.ADGroup

    .NOTES
        Author: Raymond Jette
        Date: 01/08/2025
    #>
    [OutputType([Microsoft.ActiveDirectory.Management.ADGroup])]
    [CmdletBinding()]
    param 
    (
        # The distinguished name of the AD container to search within
        [ValidateNotNullOrEmpty()]
        [string]$SearchBase,

        # The type of group to search for
        [ValidateSet('Security', 'Distribution')]
        [string]$Type
    )

    # initialize a hashtable to store parameter for Get-ADGroup cmdlet
    $getADGroupParams = @{ Filter = '*'}

    # Add SearchBase to the parameters if it is provided
    if ($PSBoundParameters.ContainsKey('SearchBase')) {
        $getADGroupParams.add('SearchBase', $SearchBase)
    }

    try {
        # Retrieve all AD groups based on the specified parameters
        Write-Verbose "Retrieving AD groups"
        $groups = Get-ADGroup @getADGroupParams

        # Filter groups by type if the Type parameter is provided
        if ($PSBoundParameters.ContainsKey('Type')) {
            Write-Verbose "Filtering groups by type: $Type"
            $groups = $groups | Where-Object {$_.GroupCategory -eq $type}
        }

        # Filter out non-empty groups
        Write-Verbose "Filter out non-empty groups"
        $groups | Where-Object {
            (Get-ADGroupMember -Identity $_.DistinguishedName -ErrorAction SilentlyContinue).Count -eq 0
        }
    } catch {
        Write-Error "An error occurred while retrieving or filtering groups: $_"
    }
} # Find-ADEmptyGroup