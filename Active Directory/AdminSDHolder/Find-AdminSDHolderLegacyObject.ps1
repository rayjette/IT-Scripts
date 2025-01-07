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


    # Retrieves all direct and indirect group memberships for a specified user or group.
    function Get-AllGroupMembers {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Identity
        )

        # Helper function to get all groups a user is a member of (direct and indirect)
        function Get-UserGroups {
            param (
                [Parameter(Mandatory = $true)]
                [string]$Username
            )
    
            $user = Get-ADUser -Identity $Username
            $allGroups = @()
    
            # Get the user's direct group memberships
            $groups = Get-ADUser $user -Properties MemberOf | Select-Object -ExpandProperty MemberOf
    
            # Loop through each group and get indirect memberships (recursively)
            foreach ($group in $groups) {
                $allGroups += Get-GroupMemberships -GroupDN $group
            }
    
            $allGroups
        }
    
        
        # Helper to get all direct and indirect memberships of a group (recursive)
        function Get-GroupMemberships {
            param (
                [Parameter(Mandatory = $true)]
                [string]$GroupDN
            )
    
            $nestedGroups = @()
    
            # Get the direct group itself by name (not DistinguishedName)
            $groupName = (Get-ADGroup $GroupDN -Properties Name).Name
            $nestedGroups += $groupName
    
            # Get the members of the group (to find other groups it may belong to)
            $members = Get-ADGroupMember $GroupDN -ErrorAction SilentlyContinue
    
            foreach ($member in $members) {
                if ($member.objectClass -eq "group") {
                    # If the member is a group, add it to the list recursively by name
                    $nestedGroups += Get-GroupMemberships -GroupDN $member.DistinguishedName
                }
            }
    
            # Now, get the groups the current group is a member of (i.e., group1 -> group2 -> group3)
            $groupMembers = Get-ADGroup $GroupDN -Properties MemberOf | Select-Object -ExpandProperty MemberOf
    
            foreach ($parentGroup in $groupMembers) {
                # Add the group names that the current group is a member of
                $parentGroupName = (Get-ADGroup $parentGroup -Properties Name).Name
                $nestedGroups += $parentGroupName
            }
    
            $nestedGroups
        }
    
        $user = $null
        $group = $null
        $allGroups = @()
    
        # Try to get user and catch errors if the user doesn't exist
        try {
            $user = Get-ADUser -Identity $Identity -ErrorAction Stop
        }
        catch {
            # If the user is not found, do nothing, we will try as a group next
        }
    
        # Try to get group and catch errors if the group doesn't exist
        try {
            $group = Get-ADGroup -Identity $Identity -ErrorAction Stop
        }
        catch {
            # If the group is not found, do nothing
        }
    
        if ($user) {
            # If it's a user, get the user's group memberships (direct and indirect)
            $allGroups = Get-UserGroups -Username $Identity
        }
        elseif ($group) {
            # If it's a group, get the group's memberships (direct and indirect)
            $allGroups = Get-GroupMemberships -GroupDN $group.DistinguishedName
        }
        else {
            Write-Error "Identity '$Identity' is neither a valid user nor a group."
            return
        }
    
        # Return the unique list of group names (direct and indirect)
        $allGroups | Sort-Object -Unique
    }

    
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
    # Get all objects with the AdminCount attribute set to 1
    $protectedObjects = Get-ADObject -Filter { AdminCount -eq 1 } -Properties AdminCount, sAMAccountName

    # Find objects that are no longer protected
    foreach ($object in $protectedObjects) {
        # Skip the krbtgt user
        if ($object.SamAccountName -eq 'krbtgt' -or $protectedGroups -contains $object.SamAccountName) {
            continue
        }

        # Get all the groups $object is a member of
        $allGroupMembers = Get-AllGroupMembers -Identity $object.SamAccountName

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