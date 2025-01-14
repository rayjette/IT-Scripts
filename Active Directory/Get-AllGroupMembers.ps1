#Requires -Modules ActiveDirectory

function Get-AllGroupMembers {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Identity
    )
    <#
    .SYNOPSIS
        Retrieves all direct and indirect group memberships for a specified user or group.

    .DESCRIPTION
        This function takes a user or group identity and retrieves all the groups that the user or group is a member of, 
        including both direct and indirect memberships.

        If user1 is a member of group2 and group2 is a member of group1 this script outputs both group1 and group2.

    .PARAMETER Identity
        The identity of the user or group for which to retrieve group memberships.  This can be a username or group name.

    .EXAMPLE
        Get-AllGroupMembers -Identity 'jdoe'
        Retrieves all group memberships for the user "jdoe".

    .EXAMPLE
        Get-AllGroupMembers -Identity 'Domain Admins'
        Retrieves all group memberships for the group "Domain Admins".

    .NOTES
        Author: Raymond Jette
        Date: 1/7/2025
        Version: 1.0
    #>


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
    }

    # Return the unique list of group names (direct and indirect)
    $allGroups | Sort-Object -Unique
}