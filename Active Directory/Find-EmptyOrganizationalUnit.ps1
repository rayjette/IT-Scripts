#Requires -Modules ActiveDirectory

Function Find-EmptyOrganizationalUnit {
    <#
    .SYNOPSIS
        Finds empty Organizational Units (OUs) in Active Directory.
    
    .DESCRIPTION
        This function searches for Organizational Units (OUs) in Active Directory that do not contain any objects.
        It allows specifying a search base to limit the search scope.

    .PARAMETER SearchBase
        The distinguished name of the Active Directory container to search within.  If not specified, the entire directory is searched.

    .EXAMPLE
        Find-EmptyOrganizationalUnit
        Finds all empty Organizational Units in the entire directory.

    .EXAMPLE
        Find-EmptyOrganizationalUnit -SearchBase 'OU=Department,DC=example,DC=com'
        Finds all empty Organizational Units within the specified OU.

    .INPUTS
        None.  Find-EmptyOrganizationalUnit does not accept input from the pipeline.

    .OUTPUTS
        Microsoft.ActiveDirectory.Management.ADOrganizationalUnit

    .NOTES
        Author: Raymond Jette
        Date: 01/09/2025
        https://github.com/rayjette
    #>
    [CmdletBinding()]
    param (
        # The distinguished name of the AD container to search within
        [string]$SearchBase
    )

    Function Test-IsOrganizationalUnitEmpty {
        param (
            # The distinguished name of the OU to check
            [Parameter(Mandatory)]
            [string]$DistinguishedName
        )

        try {
            # Define properties for the AD object search
            $adObjectProperties = @{
                Filter        = '*'
                SearchBase    = $DistinguishedName
                SearchScope   = 'OneLevel'
                ResultSetSize = 1
            }

            # Perform the search
            $object = Get-ADObject @adObjectProperties

            return -not $object
        } catch {
            Write-Error "Failed to check if OU is empty: $_"
            return $false
        }
    }

    try {
        # Define properties for the OU search
        $splat = @{
            Filter = '*'
        }

        # Add the SearchBase parameter if specified
        if ($PSBoundParameters.ContainsKey('SearchBase')) {
            $splat.add('SearchBase', $SearchBase)
        }

        # Retrieve all OUs based on the search criteria
        $organizationalUnit = Get-ADOrganizationalUnit @splat

        foreach ($ou in $organizationalUnit) {
            # Check if the OU is empty
            if (Test-IsOrganizationalUnitEmpty -DistinguishedName $ou.DistinguishedName) {
                $ou
            }
        }
    } catch {
        Write-Error "An error occurred while retrieving or filtering organizational units: $_"
    }
} # Find-EmptyOrganizationalUnit