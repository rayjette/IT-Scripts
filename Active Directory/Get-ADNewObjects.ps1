#Requires -Modules ActiveDirectory

Function Get-ADNewObjects {
    <#
    .SYNOPSIS
        Finds new Active Directory objects created after a specified date.

    .DESCRIPTION
        This function queries Active Directory to find objects that were created after or equal to a specified date.
        By default, it looks for objects created in the last 7 days.

    .PARAMETER Date
        Returns Active Directory objects created after the specified date.

    .PARAMETER Type
        Specifies the type of Active Directory object to find.
        Valid values are 'User', 'Computer', 'Group', and 'OU'.
        If not provided, it will return all types found.  Types not supported by the type parameter will also be returned.

    .EXAMPLE
        Get-ADNewObjects 
        This command finds all Active Directory objects created in the last 7 days.

    .EXAMPLE
        Get-ADNewObjects -Date (Get-Date).AddDays(-30)
        This command finds all Active Directory objects created in the last 30 days.

    .EXAMPLE
        Get-ADNewObjects -Type User
        This command finds all Active Directory user objects created in the last 7 days
        
    .EXAMPLE
        Get-ADNewObjects -Type Computer
        This command finds all Active Directory computer objects created in the last 7 days.

    .EXAMPLE
        Get-ADNewObjects -Type Group
        This command finds all Active Directory group objects created in the last 7 days.
        
    .EXAMPLE
        Get-ADNewObjects -Type OU
        This command finds all Active Directory organizational unit objects created in the last 7 days.

    .INPUTS
        None.  Get-ADNewObjects does not accept input from the pipeline.

    .OUTPUTS
        Microsoft.ActiveDirectory.Management.ADObject

    .NOTES
        Author: Raymond Jette
        Date: 01/13/2025
        https://github.com/rayjette
    #>
    [CmdletBinding()]
    param (
        [DateTime]$Date = (Get-Date).AddDays(-7),

        [ValidateSet('User', 'Computer', 'Group', 'OU')]
        [String]$Type
    )

    try {
        # Define parameters for Get-ADObject
        $getADObjectParams = @{
            Filter     = '*'
            Properties = 'whenCreated'
        }

        # Retrieve new objects from Active Directory
        $newObjects = Get-ADObject @getADObjectParams | Where-Object {$_.whenCreated -ge $date}

        # Filter objects based on the specified type
        switch ($Type) 
        {
            'User'     { $newObjects = $newObjects | Where-Object { $_.ObjectClass -eq 'user' }; break }
            'Computer' { $newObjects = $newObjects | Where-Object { $_.ObjectClass -eq 'computer' }; break }
            'Group'    { $newObjects = $newObjects | Where-Object { $_.ObjectClass -eq 'group' }; break  }
            'OU'       { $newObjects = $newObjects | Where-Object { $_.ObjectClass -eq 'OrganizationalUnit' }; break }
        }

        # Output the filtered objects
        $newObjects
    } catch {
        Write-Error "An error occurred while getting users from Active Directory: $_"
    }
}