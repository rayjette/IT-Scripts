#Requires -Modules ActiveDirectory

Function Find-AdminSDHolderLegacyObject
{
    <#
    .SYNOPSIS
        Finds Active Directory objects that used to be protected by the AdminSDHolder but are no longer.

    .DESCRIPTION
        This function searches for Active Directory objects that were previously protected by the AdminSDHolder but are no longer protected. 
        This typically occurs when the objects are removed from a protected group that they were once a member of.

    .EXAMPLE
        Find-AdminSDHolderLegacyObject

    .NOTES
        Author: Raymond Jette
    #>
    [CmdletBinding()]
    param ()

    $protectedGroups = @(
        'Account Operators',
        'Administrators',
        'Backup Operators',
        'Domain Admins',
        'Domain Controllers',
        'Enterprise Admins',
        'Enterprise Key Admins',
        'Key Admins',
        'Print Operators',
        'Read-only Domain Controllers',
        'Replicator',
        'Schema Admins',
        'Server Operators'
    )

    # Get the AdminSDHolder object
    $adminSDHolder = Get-ADObject -Filter { Name -eq 'AdminSDHolder' } -Properties ntSecurityDescriptor

    # Get all objects with the AdminCount attribute set to 1
    $protectedObjects = Get-ADObject -Filter { AdminCount -eq 1 } -Properties AdminCount, sAMAccountName

    # Find objects that are no longer protected
    foreach ($object in $protectedObjects) {
        # Skip the krbtgt user
        if ($object.SamAccountName -eq 'krbtgt' -or $protectedGroups -contains $object.SamAccountName) {
            continue
        }

        # Get all the groups $object is a member of
         $allGroupMembers = Get-ADPrincipalGroupMembership -Identity $object.SamAccountName | Select-Object -ExpandProperty Name

        # Check if the object object is still a member of any protected group
        $isProtected = $false
        foreach ($group in $protectedGroups) {
            if ($allGroupMembers -contains $group) {
                $isProtected = $true
                break
            }
        }

        # If the user object is no longer protected, output it
        if (-not $isProtected) {
            $object
        }
    }
}