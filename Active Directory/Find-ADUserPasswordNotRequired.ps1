#Requires -Modules ActiveDirectory

Function Find-ADUserPasswordNotRequired
{
    <#
    .SYNOPSIS
        This script searches for all user accounts which allow blank passwords.

    .DESCRIPTION
        This script uses the Get-ADUser cmdlet to find user accounts in Active Directory where the PasswordNotRequired attribute is set to true.

    .PARAMETER SearchBase
        Specifies the organizational unit or container to search within.

    .EXAMPLE
        Find-ADUserPasswordNotRequired
        This example searches for all user accounts which allow blank passwords.

    .EXAMPLE
        Find-ADUserPasswordNotRequired -SearchBase "OU=Users,DC=example,DC=com"
        This example searches for user accounts which allow blank passwords in the specified organizational unit.

    .NOTES
        Author: Raymond Jette
        Date: 01/10/2025
        https://github.com/rayjette
    #>
    [CmdletBinding()]
    param (
        # Specifies the organizational unit or container to search within
        [Parameter(Mandatory = $false)]
        [ValidatePattern('^(OU|CN)=.*$')]
        [string]$SearchBase
    )

    # Define a hashtable to store parameters for the Get-ADUser cmdlet
    $getADUserParams = @{
        Filter = 'PasswordNotRequired -eq $true'
    }

    # If a SearchBase is specified, add it to the parameters
    if ($SearchBase) {
        $getADUserParams.SearchBase = $SearchBase
    }
    
    try {  
        Get-ADuser @getADUserParams
    } catch {
        Write-Error "An error occurred while retrieving the user: $_"
    }
}